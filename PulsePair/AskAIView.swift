import SwiftUI

struct AskAIView: View {
    @State private var question = "What resting heart rate is normal for an adult?"
    @State private var answer: String?
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
            }
            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Ask AI")
    }

    private func ask() async {
        guard let config else { return }
        isAsking = true
        errorMessage = nil
        defer { isAsking = false }
        do {
            answer = try await AIClient.ask(question, config: config)
        } catch {
            answer = nil
            errorMessage = error.localizedDescription
        }
    }
}
