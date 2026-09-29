import LuciqSDK
import SwiftUI

struct ChaosView: View {
    @State private var log: [String] = []

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    intro

                    LazyVGrid(columns: columns, spacing: 12) {
                        ChaosTile(title: "Crash", subtitle: "Fatal exception", icon: "xmark.octagon.fill", color: Brand.heart) {
                            ChaosActions.crash()
                        }
                        ChaosTile(title: "Handled error", subtitle: "Reported as non-fatal", icon: "exclamationmark.triangle.fill", color: Brand.amber) {
                            append(ChaosActions.handledError())
                        }
                        ChaosTile(title: "Slow call", subtitle: "5 second response", icon: "tortoise.fill", color: Brand.indigo) {
                            append("Slow call started…")
                            Task { append(await ChaosActions.call("/products?delay=5000")) }
                        }
                        ChaosTile(title: "Server error", subtitle: "HTTP 500", icon: "server.rack", color: .purple) {
                            Task { append(await ChaosActions.call("/http/500")) }
                        }
                        ChaosTile(title: "Freeze", subtitle: "Main thread, 5 s", icon: "snowflake", color: Brand.teal) {
                            ChaosActions.freeze()
                            append("Main thread was blocked for 5 seconds")
                        }
                        NavigationLink {
                            LuciqTracedView(name: "Heavy list") { HeavyListView() }
                        } label: {
                            ChaosTileLabel(title: "Heavy list", subtitle: "500 images", icon: "photo.stack.fill", color: .blue)
                        }
                        .buttonStyle(.plain)
                        ChaosTile(title: "Memory hog", subtitle: "Grow until killed", icon: "memorychip.fill", color: .pink) {
                            append("Memory hog started…")
                            ChaosActions.memoryHog { append($0) }
                        }
                        NavigationLink {
                            LuciqTracedView(name: "Ask AI") { AskAIView() }
                        } label: {
                            ChaosTileLabel(title: "Ask AI", subtitle: "Real LLM call", icon: "sparkles", color: .orange)
                        }
                        .buttonStyle(.plain)
                    }

                    if !log.isEmpty {
                        SectionHeader(title: "Log", systemImage: "list.bullet.rectangle")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(log.enumerated().reversed()), id: \.offset) { entry in
                                Text(entry.element)
                                    .font(.footnote.monospaced())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .brandCard(padding: 14)
                    }
                }
                .padding()
            }
            .background(Brand.canvas.ignoresSafeArea())
            .navigationTitle("Chaos")
        }
    }

    private var intro: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Brand.heroGradient))
            VStack(alignment: .leading, spacing: 3) {
                Text("Break things on purpose")
                    .font(.headline)
                Text("Each button triggers a real failure, so you can check what Luciq reports.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .brandCard(padding: 14)
    }

    private func append(_ line: String) {
        log.append("\(Date().formatted(date: .omitted, time: .standard))  \(line)")
    }
}

struct ChaosTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChaosTileLabel(title: title, subtitle: subtitle, icon: icon, color: color)
        }
        .buttonStyle(.plain)
    }
}

struct ChaosTileLabel: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .brandCard(padding: 14)
        // Keep the tap's label the same as the old list rows ("Crash", "Server error", …),
        // so repro steps and user steps read the same as before.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
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
