//
//  AuthViewModel.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let authService = AuthService.shared
    private var modelContext: ModelContext?
    
    init() {
        checkAuthState()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func checkAuthState() {
        if authService.isLoggedIn(),
           let token = authService.getToken(),
           let userId = authService.getUserId() {
            apiService.setAuthToken(token)
            // Load user from SwiftData if available
            loadCurrentUser(userId: userId)
        }
    }
    
    func register(email: String, password: String, name: String) async {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.register(email: email, password: password, name: name)
            
            // Save to keychain
            authService.saveToken(response.token)
            authService.saveUserId(response.userId)
            
            // Create user in SwiftData
            let user = User(
                id: UUID(uuidString: response.userId) ?? UUID(),
                email: response.email,
                name: response.name,
                isAuthenticated: true,
                authToken: response.token
            )
            
            modelContext?.insert(user)
            try? modelContext?.save()
            
            currentUser = user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.login(email: email, password: password)
            
            // Save to keychain
            authService.saveToken(response.token)
            authService.saveUserId(response.userId)
            
            // Create or update user in SwiftData
            let user = User(
                id: UUID(uuidString: response.userId) ?? UUID(),
                email: response.email,
                name: response.name,
                isAuthenticated: true,
                authToken: response.token
            )
            
            modelContext?.insert(user)
            try? modelContext?.save()
            
            currentUser = user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        authService.clearAuth()
        apiService.clearToken()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func loadCurrentUser(userId: String) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id.uuidString == userId
            }
        )
        
        if let user = try? context.fetch(descriptor).first {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
