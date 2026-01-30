//
//  RegisterView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00d4ff"), Color(hex: "0099ff")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Join to start trading currencies")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                // Registration Form
                VStack(spacing: 20) {
                    CustomTextField(
                        icon: "person.fill",
                        placeholder: "Full Name",
                        text: $name
                    )
                    
                    CustomTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    CustomSecureField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password
                    )
                    
                    CustomSecureField(
                        icon: "lock.fill",
                        placeholder: "Confirm Password",
                        text: $confirmPassword
                    )
                }
                .padding(.horizontal, 30)
                
                // Error Message
                if let error = localError ?? authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 30)
                }
                
                // Register Button
                Button(action: {
                    registerUser()
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "00d4ff"), Color(hex: "0099ff")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 30)
                .disabled(authViewModel.isLoading)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Color(hex: "00d4ff"))
                }
            }
        }
    }
    
    private func registerUser() {
        // Validation
        localError = nil
        
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            localError = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            localError = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters"
            return
        }
        
        Task {
            await authViewModel.register(email: email, password: password, name: name)
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
