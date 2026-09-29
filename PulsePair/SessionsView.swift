import SwiftUI

struct SessionsView: View {
    @Environment(SensorSimulator.self) private var sensor
    @State private var sessions: [SessionPost] = []
    @State private var loadError: String?
    @State private var saveStatus: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        Label(isSaving ? "Saving…" : "Save session", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isSaving)
                    if let saveStatus {
                        Text(saveStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text(sensor.summary)
                }
                Section("Past sessions") {
                    if let loadError {
                        Text(loadError).foregroundStyle(.red)
                    } else if sessions.isEmpty {
                        ProgressView()
                    }
                    ForEach(sessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title).font(.headline)
                            Text(session.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
            .task { await load() }
            .refreshable { await load() }
        }
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
            title: "Heart-rate session · avg \(sensor.averageBPM) bpm · \(Date().formatted(date: .abbreviated, time: .shortened))",
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
