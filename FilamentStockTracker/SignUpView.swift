//
//  SignUpView.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 30.01.2026.
//
import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 14) {
            Text("Create account")
                .font(.title2).bold()

            TextField("company email (…@fited.co)", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .disabled(auth.isLoading)

            SecureField("password (min 6)", text: $password)
                .textFieldStyle(.roundedBorder)
                .disabled(auth.isLoading)

            SecureField("confirm password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .disabled(auth.isLoading)

            if let err = auth.lastError, !err.isEmpty {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            HStack(spacing: 10) {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button(auth.isLoading ? "Creating..." : "Create") {
                    Task {
                        auth.lastError = nil

                        guard password == confirmPassword else {
                            auth.lastError = "Şifreler aynı değil."
                            return
                        }

                        await auth.signUp(email: email, password: password)
                        if auth.isSignedIn { dismiss() }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(auth.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
