import Foundation

struct AIConfig: Decodable {
    let apiKey: String
    let model: String?
    let endpoint: String?

    static func load() -> AIConfig? {
        guard
            let url = Bundle.main.url(forResource: "AIConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let config = try? PropertyListDecoder().decode(AIConfig.self, from: data),
            !config.apiKey.isEmpty
        else { return nil }
        return config
    }
}

/// A successful call, with everything monitoring needs about it.
struct AIAnswer {
    let text: String
    /// The model that actually answered. The request sends `fallbacks: "default"`,
    /// so this is not always the model we asked for.
    let model: String
    let stopReason: String?
    let usage: AITelemetry.Usage

    /// An answer cut off at `max_tokens` is still shown, but it is not a
    /// healthy call and shouldn't be counted as one.
    var outcome: AITelemetry.Outcome {
        stopReason == "max_tokens" ? .truncated : .ok
    }
}

struct AIError: LocalizedError {
    let message: String
    let outcome: AITelemetry.Outcome
    var model = "unknown"
    var usage = AITelemetry.Usage()
    var refusalCategory: String?

    var errorDescription: String? { message }
}

enum AIClient {
    private struct Request: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let max_tokens: Int
        let fallbacks: String
        let messages: [Message]
    }

    private struct Response: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }

        struct Usage: Decodable {
            let input_tokens: Int?
            let output_tokens: Int?
            let cache_read_input_tokens: Int?
            let cache_creation_input_tokens: Int?
        }

        struct StopDetails: Decodable {
            let type: String?
            let category: String?
            let explanation: String?
        }

        let content: [Block]
        let model: String?
        let stop_reason: String?
        let stop_details: StopDetails?
        let usage: Usage?
    }

    private struct ErrorResponse: Decodable {
        struct Detail: Decodable {
            let type: String
            let message: String
        }

        let error: Detail
    }

    static func ask(_ question: String, config: AIConfig) async throws -> AIAnswer {
        var request = URLRequest(url: URL(string: config.endpoint ?? "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONEncoder().encode(Request(
            model: config.model ?? "claude-opus-5",
            max_tokens: 16000,
            fallbacks: "default",
            messages: [.init(role: "user", content: question)]
        ))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw AIError(message: error.localizedDescription, outcome: outcome(for: error))
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let outcome: AITelemetry.Outcome = status >= 500 ? .httpServer : .httpClient
            if let failure = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AIError(
                    message: "HTTP \(status) \(failure.error.type): \(failure.error.message)",
                    outcome: outcome
                )
            }
            throw AIError(message: "HTTP \(status)", outcome: outcome)
        }

        guard let answer = try? JSONDecoder().decode(Response.self, from: data) else {
            throw AIError(message: "The response could not be read.", outcome: .decodeError)
        }

        let model = answer.model ?? config.model ?? "unknown"
        let usage = AITelemetry.Usage(
            inputTokens: answer.usage?.input_tokens ?? 0,
            outputTokens: answer.usage?.output_tokens ?? 0,
            cacheReadTokens: answer.usage?.cache_read_input_tokens ?? 0,
            cacheCreationTokens: answer.usage?.cache_creation_input_tokens ?? 0
        )

        // A refusal is an HTTP 200 with no answer in it. Nothing Luciq measures
        // about this request can tell it apart from a good one.
        if answer.stop_reason == "refusal" {
            throw AIError(
                message: "The model declined to answer this question.",
                outcome: .refused,
                model: model,
                usage: usage,
                refusalCategory: answer.stop_details?.category
            )
        }

        let text = answer.content.filter { $0.type == "text" }.compactMap(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else {
            throw AIError(message: "The model returned no text.", outcome: .empty, model: model, usage: usage)
        }

        return AIAnswer(text: text, model: model, stopReason: answer.stop_reason, usage: usage)
    }

    private static func outcome(for error: URLError) -> AITelemetry.Outcome {
        switch error.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
             .cannotFindHost, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        default:
            return .transport
        }
    }
}
