import SwiftUI

struct ContactSupportView: View {
    @Environment(AuthStore.self) private var auth
    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var ticketID: Int?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                TextField("Subject", text: $subject)
                TextField("What happened?", text: $message, axis: .vertical)
                    .lineLimit(4...8)
            } footer: {
                Text("Don't include patient details. Support gets the device and app details below.")
            }

            if let clinician = auth.user {
                Section("Attached for the engineers") {
                    ForEach(SupportDiagnostics.current(for: clinician).lines, id: \.0) { line in
                        LabeledContent(line.0) {
                            Text(line.1)
                                .font(.footnote.monospaced())
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Section {
                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Label("Send to support", systemImage: "paperplane")
                    }
                }
                .disabled(isSending || subject.isEmpty || message.isEmpty || auth.user == nil)
            }

            if let ticketID {
                Section {
                    Label("Ticket #\(ticketID) sent to support", systemImage: "checkmark.seal")
                        .foregroundStyle(.green)
                }
            }
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Contact support")
    }

    private func send() async {
        guard let clinician = auth.user else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            ticketID = try await SupportTicket.submit(subject: subject, message: message, from: clinician)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
