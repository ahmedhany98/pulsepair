import LuciqSDK
import SwiftUI

@main
struct PulsePairApp: App {
    @State private var auth = AuthStore()
    @State private var sensor = SensorSimulator()

    init() {
        LuciqSetup.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(sensor)
        }
    }
}

struct RootView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        Group {
            if auth.user == nil {
                LuciqTracedView(name: "Sign in") { LoginView() }
            } else {
                MainTabView()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            EnvironmentBanner()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LuciqTracedView(name: "Pair sensor") { NavigationStack { PairSensorView() } }
                .tabItem { Label("Sensor", systemImage: "heart.text.square") }
            LuciqTracedView(name: "Sessions") { SessionsView() }
                .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle") }
            LuciqTracedView(name: "Patient profile") { PatientProfileView() }
                .tabItem { Label("Patient", systemImage: "person.text.rectangle") }
            LuciqTracedView(name: "Chaos") { ChaosView() }
                .tabItem { Label("Chaos", systemImage: "bolt.trianglebadge.exclamationmark") }
        }
    }
}
