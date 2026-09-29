import SwiftUI

struct SessionsView: View {
    @Environment(SensorSimulator.self) private var sensor
    @State private var sessions: [SessionPost] = []
    @State private var loadError: String?
    @State private var saveStatus: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    recordCard

                    SectionHeader(title: "Past sessions", systemImage: "clock")
                    if let loadError {
                        Label(loadError, systemImage: "wifi.exclamationmark")
                            .font(.subheadline)
                            .foregroundStyle(Brand.heart)
                            .brandCard(padding: 14)
                    } else if sessions.isEmpty {
                        ProgressView()
                            .padding(.top, 24)
                    }
                    LazyVStack(spacing: 10) {
                        ForEach(sessions) { session in
                            sessionRow(session)
                        }
                    }
                }
                .padding()
            }
            .background(Brand.canvas.ignoresSafeArea())
            .navigationTitle("Sessions")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Current recording", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                if let bpm = sensor.currentBPM {
                    Text("\(bpm) bpm")
                        .font(.headline.monospacedDigit())
                }
            }
            Text(sensor.summary)
                .font(.subheadline)
                .opacity(0.9)
            Button {
                Task { await save() }
            } label: {
                Label(isSaving ? "Saving…" : "Save session", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(BrandButtonStyle(color: .white, foreground: Brand.heart))
            .disabled(isSaving)
            if let saveStatus {
                Label(saveStatus, systemImage: "checkmark.icloud")
                    .font(.footnote.weight(.medium))
                    .opacity(0.9)
            }
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Brand.indigo, Brand.heart], startPoint: .topLeading, endPoint: .bottomTrailing))
                ECGTrace(color: .white.opacity(0.18), lineWidth: 2, speed: 60, beatWidth: 110)
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        )
        .shadow(color: Brand.indigo.opacity(0.3), radius: 16, y: 8)
    }

    private func sessionRow(_ session: SessionPost) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(Brand.heart)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Brand.heart.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.subheadline.weight(.semibold))
                Text(session.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Text("#\(session.id)")
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .brandCard(padding: 14)
    }

    private func load() async {
        do {
            let list: SessionPostList = try await API.get("/posts?limit=10")
            sessions = list.posts
            loadError = nil
        } catch {
            loadError = "Couldn't load sessions: \(error.localizedDescription)"
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let session = NewSessionPost(
            title: "Heart-rate session\(sensor.averageBPM.map { " · avg \($0) bpm" } ?? "") · \(Date().formatted(date: .abbreviated, time: .shortened))",
            body: sensor.summary,
            userId: 1
        )
        do {
            let saved: SessionPost = try await API.post("/posts/add", body: session)
            sessions.insert(saved, at: 0)
            saveStatus = "Uploaded as session #\(saved.id)"
        } catch {
            saveStatus = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
