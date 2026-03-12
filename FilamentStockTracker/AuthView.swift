import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    private var isCompanyEmail: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .hasSuffix("@fited.co")
    }

    var body: some View {
        ZStack {
            // BACKGROUND
            Image("filament_wall")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.60),
                    .black.opacity(0.25),
                    .black.opacity(0.60)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // CENTER CARD
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 26, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Filament Stock Tracker")
                                .font(.title3).bold()
                            Text("Sign in with your company account")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    VStack(spacing: 10) {
                        TextField("company email (…@fited.co)", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .disabled(auth.isLoading)

                        SecureField("password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .disabled(auth.isLoading)
                    }

                    if let err = auth.lastError, !err.isEmpty {
                        let isSuccess = err.starts(with: "Şifre yenileme maili gönderildi")
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(isSuccess ? .green : .red)

                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(isSuccess ? .green : .red)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        Task { await auth.signIn(email: email, password: password) }
                    } label: {
                        HStack(spacing: 8) {
                            if auth.isLoading { ProgressView().controlSize(.small) }
                            Text(auth.isLoading ? "Signing in…" : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(auth.isLoading || password.isEmpty || !isCompanyEmail)
                    .keyboardShortcut(.defaultAction)

                    HStack {
                        Button("Create account") { showSignUp = true }
                            .buttonStyle(.bordered)
                            .disabled(auth.isLoading) // mail yazmadan da açılır

                        Spacer()

                        Button("Forgot password?") {
                            Task { await auth.sendPasswordReset(email: email) }
                        }
                        .buttonStyle(.link)
                        .disabled(auth.isLoading || !isCompanyEmail)
                    }

                    Text("Only @fited.co emails are allowed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(6)
                .frame(width: 420)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
      
        .sheet(isPresented: $showSignUp) {
            SignUpView().environmentObject(auth)
        }
    }
}
