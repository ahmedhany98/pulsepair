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

struct AIError: LocalizedError {
    let message: String
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

        let content: [Block]
        let stop_reason: String?
    }

    private struct ErrorResponse: Decodable {
        struct Detail: Decodable {
            let type: String
            let message: String
        }

        let error: Detail
    }

    static func ask(_ question: String, config: AIConfig) async throws -> String {
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

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if let failure = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AIError(message: "HTTP \(status) \(failure.error.type): \(failure.error.message)")
            }
            throw AIError(message: "HTTP \(status)")
        }

        let answer = try JSONDecoder().decode(Response.self, from: data)
        if answer.stop_reason == "refusal" {
            throw AIError(message: "The model declined to answer this question.")
        }
        let text = answer.content.filter { $0.type == "text" }.compactMap(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else { throw AIError(message: "The model returned no text.") }
        return text
    }
}
