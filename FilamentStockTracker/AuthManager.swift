import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthManager: ObservableObject {

    @Published private(set) var user: User? = nil
    @Published var lastError: String? = nil
    @Published var isLoading: Bool = false

    var isSignedIn: Bool { user != nil }
    var userEmail: String? { user?.email }

    // MARK: - Session

    func restoreSession() async {
        user = Auth.auth().currentUser
    }
    //Mark : -Sign Up
    
    func signUp(email:String, password:String) async {
        isLoading = true
        defer {isLoading = false}
        lastError = nil
        
        let e = email.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
        guard !e.isEmpty else {
            lastError = "Email boş olamaz."
            return
        }
        guard e.hasSuffix("@fited.co") else {
            lastError = "Lütfen @fited.co email kullan."
            return
        }
        guard password.count >= 6 else {
                lastError = "Şifre en az 6 karakter olmalı."
                return
            }

            do {
                let result = try await Auth.auth().createUser(withEmail: e, password: password)
                user = result.user
            } catch {
                lastError = (error as NSError).localizedDescription
            }
        
    }
    // MARK: - Sign in

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard e.hasSuffix("@fited.co") else {
            lastError = "Lütfen @fited.co email kullan."
            return
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: e, password: password)
            user = result.user
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }

    // MARK: - Forgot password

    func sendPasswordReset(email: String) async {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !e.isEmpty else {
            lastError = "Email boş olamaz."
            return
        }
        guard e.hasSuffix("@fited.co") else {
            lastError = "Lütfen @fited.co email kullan."
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: e)
            lastError = "Şifre yenileme maili gönderildi: \(e)"
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }

    // MARK: - Sign out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }
}
