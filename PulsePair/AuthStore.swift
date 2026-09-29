import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    private(set) var user: Clinician?
    private(set) var isSigningIn = false
    private(set) var errorMessage: String?

    func signIn(username: String, password: String) async {
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }
        do {
            let clinician: Clinician = try await API.post(
                "/auth/login",
                body: LoginRequest(username: username, password: password, expiresInMins: 240)
            )
            API.accessToken = clinician.accessToken
            LuciqSetup.identify(clinician)
            user = clinician
        } catch {
            errorMessage = "Sign-in failed: \(error.localizedDescription)"
        }
    }

    func signOut() {
        LuciqSetup.signOut()
        API.accessToken = nil
        user = nil
    }
}
