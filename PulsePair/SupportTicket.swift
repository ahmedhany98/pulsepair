import Foundation
import LuciqSDK
import UIKit

struct ZendeskConfig: Decodable {
    let subdomain: String
    let email: String?
    let apiToken: String?

    static func load() -> ZendeskConfig? {
        guard
            let url = Bundle.main.url(forResource: "ZendeskConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let config = try? PropertyListDecoder().decode(ZendeskConfig.self, from: data),
            !config.subdomain.isEmpty
        else { return nil }
        return config
    }

    var hasToken: Bool { !(email ?? "").isEmpty && !(apiToken ?? "").isEmpty }
}

struct SupportError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// What engineers need to find this user in Luciq. No patient data goes in here.
struct SupportDiagnostics {
    let luciqUserID: String
    let environment: String
    let appVersion: String
    let device: String
    let os: String
    let sessionReplay: String

    @MainActor
    static func current(for clinician: Clinician) -> SupportDiagnostics {
        SupportDiagnostics(
            luciqUserID: String(clinician.id),
            environment: AppEnvironment.current.rawValue,
            appVersion: AppEnvironment.version,
            device: deviceModel(),
            os: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            sessionReplay: SessionReplay.sessionReplayLink
                ?? (AppEnvironment.current == .production
                    ? "Not recorded (Session Replay is off in Production builds)"
                    : "No link from the SDK yet")
        )
    }

    var lines: [(String, String)] {
        [
            ("Luciq user ID", luciqUserID),
            ("Environment", environment),
            ("App version", appVersion),
            ("Device", device),
            ("OS", os),
            ("Session replay", sessionReplay),
        ]
    }

    var text: String {
        lines.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
    }

    private static func deviceModel() -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}

enum SupportTicket {
    private struct Payload: Encodable {
        struct Ticket: Encodable {
            struct Requester: Encodable {
                let name: String
                let email: String
            }

            struct Comment: Encodable {
                let body: String
            }

            let subject: String
            let comment: Comment
            let requester: Requester
            let tags: [String]
        }

        let ticket: Ticket?
        let request: Ticket?
    }

    private struct Response: Decodable {
        struct Created: Decodable { let id: Int }
        let ticket: Created?
        let request: Created?
        let suspended_ticket: Created?
    }

    /// Files a Zendesk ticket that carries the Luciq pointers, then records the ticket
    /// number on the Luciq user so it works in both directions.
    @MainActor
    static func submit(subject: String, message: String, from clinician: Clinician) async throws -> (id: Int, suspended: Bool) {
        guard let config = ZendeskConfig.load() else {
            throw SupportError(message: "Zendesk isn't configured. Copy ZendeskConfig.example.plist to PulsePair/ZendeskConfig.plist.")
        }
        let diagnostics = SupportDiagnostics.current(for: clinician)
        let ticket = Payload.Ticket(
            subject: "[PulsePair] \(subject)",
            comment: .init(body: "\(message)\n\nSent from PulsePair:\n\(diagnostics.text)"),
            requester: .init(name: "\(clinician.firstName) \(clinician.lastName)", email: clinician.email),
            tags: ["pulsepair", "luciq_user_\(diagnostics.luciqUserID)", diagnostics.environment.lowercased()]
        )

        // An API token files a ticket as the support team; without one, fall back to an
        // end-user request, which needs "Anyone can submit tickets" on the Zendesk account.
        let path = config.hasToken ? "tickets" : "requests"
        var request = URLRequest(url: URL(string: "https://\(config.subdomain).zendesk.com/api/v2/\(path).json")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if config.hasToken, let email = config.email, let token = config.apiToken {
            let credentials = Data("\(email)/token:\(token)".utf8).base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(
            config.hasToken ? Payload(ticket: ticket, request: nil) : Payload(ticket: nil, request: ticket)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status),
              let created = try? JSONDecoder().decode(Response.self, from: data),
              let id = created.ticket?.id ?? created.request?.id ?? created.suspended_ticket?.id
        else {
            throw SupportError(message: "Zendesk returned \(status): \(String(decoding: data.prefix(300), as: UTF8.self))")
        }

        // Zendesk holds end-user requests from unverified senders in its Suspended queue until an agent recovers them.
        let suspended = created.suspended_ticket != nil
        Luciq.setUserAttribute(suspended ? "suspended #\(id)" : "#\(id)", withKey: "Zendesk ticket")
        Luciq.logUserEvent(withName: "Contacted support")
        return (id, suspended)
    }
}
