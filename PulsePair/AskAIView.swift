import SwiftUI

struct AskAIView: View {
    @State private var question = "What resting heart rate is normal for an adult?"
    @State private var answer: String?
    @State private var run: AITelemetry.Run?
    @State private var rating: String?
    @State private var errorMessage: String?
    @State private var isAsking = false
    private let config = AIConfig.load()

    var body: some View {
        Form {
            if config == nil {
                Section {
                    Text("Add PulsePair/AIConfig.plist with your team's LLM API key. Copy AIConfig.example.plist to start.")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Question") {
                TextField("Ask anything", text: $question, axis: .vertical)
                    .lineLimit(2...6)
            }
            Section {
                Button {
                    Task { await ask() }
                } label: {
                    if isAsking {
                        ProgressView()
                    } else {
                        Text("Ask AI")
                    }
                }
                .disabled(isAsking || question.isEmpty || config == nil)
            }
            if let answer {
                Section("Answer") {
                    Text(answer).textSelection(.enabled)
                }
                ratingSection
            }
            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            if let run {
                callDetails(run)
            }
        }
        .navigationTitle("Ask AI")
    }

    /// Nothing else in the app can tell us whether an answer was any good, and
    /// no amount of latency or status-code monitoring will either.
    private var ratingSection: some View {
        Section("Was this answer right?") {
            if let rating {
                Text(rating == "wrong" ? "Reported as wrong. Thank you." : "Marked as correct. Thank you.")
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 24) {
                    Button {
                        rate(wrong: false)
                    } label: {
                        Label("Correct", systemImage: "hand.thumbsup")
                    }
                    Button(role: .destructive) {
                        rate(wrong: true)
                    } label: {
                        Label("Wrong", systemImage: "hand.thumbsdown")
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }

    /// Shown in the app because the dashboard can't show most of it.
    private func callDetails(_ run: AITelemetry.Run) -> some View {
        Section("This call") {
            LabeledContent("Outcome", value: run.outcome.rawValue)
            LabeledContent("Model", value: run.model)
            LabeledContent("Latency", value: String(format: "%.2f sec", run.latency))
            LabeledContent("Tokens", value: "\(run.usage.inputTokens) in / \(run.usage.outputTokens) out")
            LabeledContent("Cost", value: String(format: "$%.5f", run.costUSD))
        }
    }

    private func ask() async {
        guard let config else { return }
        isAsking = true
        errorMessage = nil
        answer = nil
        run = nil
        rating = nil
        defer { isAsking = false }

        let started = Date()
        AITelemetry.startFlow()
        do {
            let result = try await AIClient.ask(question, config: config)
            answer = result.text
            if result.outcome == .truncated {
                errorMessage = "This answer stopped at the token limit, so it is incomplete."
            }
            run = AITelemetry.endFlow(
                outcome: result.outcome,
                model: result.model,
                usage: result.usage,
                latency: Date().timeIntervalSince(started)
            )
        } catch let error as AIError {
            errorMessage = error.errorDescription
            run = AITelemetry.endFlow(
                outcome: error.outcome,
                model: error.model,
                usage: error.usage,
                latency: Date().timeIntervalSince(started),
                refusalCategory: error.refusalCategory
            )
        } catch {
            errorMessage = error.localizedDescription
            run = AITelemetry.endFlow(
                outcome: .transport,
                model: "unknown",
                usage: AITelemetry.Usage(),
                latency: Date().timeIntervalSince(started)
            )
        }
    }

    private func rate(wrong: Bool) {
        guard let run else { return }
        rating = wrong ? "wrong" : "good"
        AITelemetry.rate(run, wrong: wrong, questionLength: question.count)
    }
}
