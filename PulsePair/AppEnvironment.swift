import SwiftUI

enum AppEnvironment: String {
    case test = "Test"
    case production = "Production"

    static let current: AppEnvironment = {
        let value = Bundle.main.object(forInfoDictionaryKey: "PulsePairEnvironment") as? String
        return AppEnvironment(rawValue: value ?? "") ?? .production
    }()

    static var version: String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(marketing) (\(build))"
    }
}

struct EnvironmentBanner: View {
    private let environment = AppEnvironment.current

    var body: some View {
        Text("\(environment.rawValue.uppercased()) BUILD · v\(AppEnvironment.version)")
            .font(.caption.weight(.bold))
            .foregroundStyle(environment == .test ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(environment == .test ? Color.yellow : Color.red)
    }
}
