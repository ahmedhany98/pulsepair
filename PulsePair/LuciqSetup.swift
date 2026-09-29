import Foundation
import LuciqSDK

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
    static func start() {
        guard let config = LuciqConfig.load() else { return }
        switch AppEnvironment.current {
        case .test:
            Luciq.start(withToken: config.testToken, invocationEvents: [.shake, .floatingButton])
        case .production:
            Luciq.start(withToken: config.productionToken, invocationEvents: [])
            SessionReplay.enabled = false
            BugReporting.enabled = false
            Luciq.setReproStepsFor(.all, with: .disable)
            Luciq.trackUserSteps = false
            NetworkLogger.enabled = false
        }
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
}
