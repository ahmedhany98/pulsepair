import SwiftUI

struct AskAIView: View {
    @State private var question = "What resting heart rate is normal for an adult?"
    @State private var answer: String?
    @State private var answerSeconds: Double?
    @State private var errorMessage: String?
    @State private var isAsking = false
    private let config = AIConfig.load()

    private let suggestions = [
        "What resting heart rate is normal for an adult?",
        "What does a spike to 150 bpm at rest mean?",
        "How should I wear a chest strap for accurate readings?",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if config == nil {
                    Label(
                        "Add PulsePair/AIConfig.plist with your team's LLM API key. Copy AIConfig.example.plist to start.",
                        systemImage: "key.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .brandCard(padding: 14)
                }

                SectionHeader(title: "Question", systemImage: "questionmark.bubble")
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Ask anything", text: $question, axis: .vertical)
                        .lineLimit(2...6)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(suggestion) { question = suggestion }
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Brand.heart.opacity(0.1)))
                                    .foregroundStyle(Brand.heart)
                            }
                        }
                    }
                }
                .brandCard(padding: 14)

                Button {
                    Task { await ask() }
                } label: {
                    if isAsking {
                        ProgressView().tint(.white)
                    } else {
                        Label("Ask AI", systemImage: "sparkles")
                    }
                }
                .buttonStyle(BrandButtonStyle())
                .disabled(isAsking || question.isEmpty || config == nil)

                if let answer {
                    SectionHeader(title: "Answer", systemImage: "text.bubble")
                    VStack(alignment: .leading, spacing: 10) {
                        Text(answer)
                            .textSelection(.enabled)
                        if let answerSeconds {
                            Label(String(format: "%.1f s", answerSeconds), systemImage: "timer")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .brandCard(padding: 14)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Brand.heart)
                        .brandCard(padding: 14)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Brand.canvas.ignoresSafeArea())
        .navigationTitle("Ask AI")
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [.orange, Brand.heart], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            VStack(alignment: .leading, spacing: 3) {
                Text("PulseAI")
                    .font(.headline)
                Text(config?.model ?? "Not configured")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("Not medical advice.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .brandCard(padding: 14)
    }

    private func ask() async {
        guard let config else { return }
        isAsking = true
        errorMessage = nil
        defer { isAsking = false }
        let start = Date()
        do {
            answer = try await AIClient.ask(question, config: config)
            answerSeconds = Date().timeIntervalSince(start)
        } catch {
            answer = nil
            answerSeconds = nil
            errorMessage = error.localizedDescription
        }
    }
}
