import LuciqSDK
import UIKit

struct LuciqConfig: Decodable {
    let testToken: String
    let productionToken: String

    static func load() -> LuciqConfig? {
        guard
            let url = Bundle.main.url(forResource: "LuciqConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? PropertyListDecoder().decode(LuciqConfig.self, from: data)
    }
}

enum LuciqSetup {
    private static let maskedHeaders = ["Authorization", "Cookie", "X-API-Key", "token"]
    private static let maskedResponseHeaders: Set<String> = ["set-cookie"]
    private static let maskedBodyFields: Set<String> = [
        "password", "token", "ssn", "email", "phone", "cardNumber", "iban", "accessToken", "refreshToken",
        "firstName", "lastName", "maidenName", "birthDate", "address", "ip", "macAddress",
    ]

    static func start() {
        guard let config = LuciqConfig.load() else { return }
        switch AppEnvironment.current {
        case .test:
            Luciq.start(withToken: config.testToken, invocationEvents: [.shake, .floatingButton])
            attachReplayLinkToReports()
        case .production:
            Luciq.start(withToken: config.productionToken, invocationEvents: [])
            SessionReplay.enabled = false
            BugReporting.enabled = false
            Luciq.setReproStepsFor(.all, with: .disable)
            Luciq.trackUserSteps = false
            NetworkLogger.enabled = false
        }
        Luciq.setAutoMaskScreenshots([.textInputs])
        Luciq.autoMaskAllSwiftUIViews = false
        maskNetworkRequests()
        maskNetworkResponses()
        applyTheme()
    }

    private static func attachReplayLinkToReports() {
        Luciq.willSendReportHandler = { report in
            if let link = SessionReplay.sessionReplayLink {
                report.setUserAttribute(link, withKey: "Session replay")
            }
            return report
        }
    }

    private static func applyTheme() {
        let theme = Theme()
        theme.primaryColor = .systemRed
        Luciq.theme = theme
        Luciq.setValue("Report a problem to the PulsePair QA team", forStringWithKey: kLCQReportBugStringName)
        Luciq.setValue("Shake your phone any time to report a problem to the QA team.", forStringWithKey: kLCQShakeStartAlertTextStringName)
    }

    static func identify(_ clinician: Clinician) {
        switch AppEnvironment.current {
        case .test:
            Luciq.identifyUser(
                withID: String(clinician.id),
                email: clinician.email,
                name: "\(clinician.firstName) \(clinician.lastName)"
            )
        case .production:
            Luciq.identifyUser(withID: String(clinician.id), email: nil, name: nil)
        }
        Luciq.setUserAttribute("Enterprise", withKey: "plan")
        Luciq.setUserAttribute("P8 Regulated QA Lead", withKey: "persona")
    }

    static func signOut() {
        Luciq.logOut()
    }

    static func reportNonFatal(_ error: Error) {
        CrashReporting.error(error).report()
    }

    static func logEvent(_ name: String) {
        Luciq.logUserEvent(withName: name)
    }

    private static func maskNetworkRequests() {
        NetworkLogger.setRequestObfuscationHandler { request in
            var masked = request
            for header in maskedHeaders where masked.value(forHTTPHeaderField: header) != nil {
                masked.setValue("*****", forHTTPHeaderField: header)
            }
            if let body = masked.httpBody, let json = try? JSONSerialization.jsonObject(with: body) {
                masked.httpBody = try? JSONSerialization.data(withJSONObject: mask(json))
            }
            return masked
        }
    }

    private static func maskNetworkResponses() {
        NetworkLogger.setResponseObfuscationHandler { data, response, completion in
            let maskedData = data.flatMap { body in
                (try? JSONSerialization.jsonObject(with: body)).flatMap { try? JSONSerialization.data(withJSONObject: mask($0)) }
            }
            completion(maskedData ?? data, maskHeaders(of: response))
        }
    }

    private static func maskHeaders(of response: URLResponse) -> URLResponse {
        guard
            let http = response as? HTTPURLResponse,
            let url = http.url,
            var headers = http.allHeaderFields as? [String: String]
        else { return response }
        for key in headers.keys where maskedResponseHeaders.contains(key.lowercased()) {
            headers[key] = "*****"
        }
        return HTTPURLResponse(url: url, statusCode: http.statusCode, httpVersion: nil, headerFields: headers) ?? response
    }

    private static func mask(_ object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, entry in
                result[entry.key] = maskedBodyFields.contains(entry.key) ? "*****" : mask(entry.value)
            }
        }
        if let array = object as? [Any] {
            return array.map(mask)
        }
        return object
    }
}
