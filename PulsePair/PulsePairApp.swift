import SwiftUI

@main
struct PulsePairApp: App {
    @State private var auth = AuthStore()
    @State private var sensor = SensorSimulator()

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
                LoginView()
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
            NavigationStack { PairSensorView() }
                .tabItem { Label("Sensor", systemImage: "heart.text.square") }
            SessionsView()
                .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle") }
            PatientProfileView()
                .tabItem { Label("Patient", systemImage: "person.text.rectangle") }
            ChaosView()
                .tabItem { Label("Chaos", systemImage: "bolt.trianglebadge.exclamationmark") }
        }
    }
}
