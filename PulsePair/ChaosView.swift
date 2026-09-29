import LuciqSDK
import SwiftUI

struct ChaosView: View {
    @State private var log: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        ChaosActions.crash()
                    } label: {
                        Label("Crash", systemImage: "xmark.octagon")
                    }
                    Button {
                        append(ChaosActions.handledError())
                    } label: {
                        Label("Handled error", systemImage: "exclamationmark.triangle")
                    }
                    Button {
                        append("Slow call started…")
                        Task { append(await ChaosActions.call("/products?delay=5000")) }
                    } label: {
                        Label("Slow call", systemImage: "tortoise")
                    }
                    Button {
                        Task { append(await ChaosActions.call("/http/500")) }
                    } label: {
                        Label("Server error", systemImage: "server.rack")
                    }
                    Button {
                        ChaosActions.freeze()
                        append("Main thread was blocked for 5 seconds")
                    } label: {
                        Label("Freeze", systemImage: "snowflake")
                    }
                    NavigationLink {
                        LuciqTracedView(name: "Heavy list") { HeavyListView() }
                    } label: {
                        Label("Heavy list", systemImage: "photo.stack")
                    }
                    Button(role: .destructive) {
                        append("Memory hog started…")
                        ChaosActions.memoryHog { append($0) }
                    } label: {
                        Label("Memory hog", systemImage: "memorychip")
                    }
                    NavigationLink {
                        LuciqTracedView(name: "Ask AI") { AskAIView() }
                    } label: {
                        Label("Ask AI", systemImage: "sparkles")
                    }
                }
                if !log.isEmpty {
                    Section("Log") {
                        ForEach(Array(log.enumerated().reversed()), id: \.offset) { entry in
                            Text(entry.element)
                                .font(.footnote.monospaced())
                        }
                    }
                }
            }
            .navigationTitle("Chaos")
        }
    }

    private func append(_ line: String) {
        log.append("\(Date().formatted(date: .omitted, time: .standard))  \(line)")
    }
}

struct HeavyListView: View {
    var body: some View {
        List(1...500, id: \.self) { index in
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: "https://picsum.photos/seed/\(index)/400/300")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.2)
                }
                .frame(width: 120, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Image \(index)")
            }
        }
        .navigationTitle("Heavy list")
    }
}
