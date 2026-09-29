import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth
    @State private var username = "emilys"
    @State private var password = "emilyspass"

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 14) {
                    ZStack {
                        ECGTrace(color: Brand.heart.opacity(0.55), lineWidth: 2.5, speed: 85, beatWidth: 130)
                            .frame(height: 70)
                            .padding(.horizontal, -24)
                        Circle()
                            .fill(Brand.heroGradient)
                            .frame(width: 108, height: 108)
                            .shadow(color: Brand.heart.opacity(0.45), radius: 22, y: 12)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse)
                    }
                    Text("PulsePair")
                        .font(.largeTitle.bold())
                    Text("Clinician sign-in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 36)

                VStack(spacing: 12) {
                    inputRow(icon: "person.fill") {
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    inputRow(icon: "lock.fill") {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                    }
                }

                if let errorMessage = auth.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Brand.heart)
                }

                Button {
                    Task { await auth.signIn(username: username, password: password) }
                } label: {
                    if auth.isSigningIn {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign in")
                    }
                }
                .buttonStyle(BrandButtonStyle())
                .disabled(auth.isSigningIn || username.isEmpty || password.isEmpty)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Brand.canvas.ignoresSafeArea())
    }

    private func inputRow<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Brand.heart)
                .frame(width: 22)
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.card))
    }
}
