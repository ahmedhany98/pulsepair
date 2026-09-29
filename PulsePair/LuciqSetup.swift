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
}
