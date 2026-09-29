import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth
    @State private var username = "emilys"
    @State private var password = "emilyspass"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Clinician sign-in")
                } footer: {
                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
                Section {
                    Button {
                        Task { await auth.signIn(username: username, password: password) }
                    } label: {
                        if auth.isSigningIn {
                            ProgressView()
                        } else {
                            Text("Sign in")
                        }
                    }
                    .disabled(auth.isSigningIn || username.isEmpty || password.isEmpty)
                }
            }
            .navigationTitle("PulsePair")
        }
    }
}
