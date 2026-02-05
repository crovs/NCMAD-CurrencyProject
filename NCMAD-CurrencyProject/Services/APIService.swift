//
//  APIService.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please log in again"
        case .serverError(let message):
            return message
        }
    }
}

// API Request/Response models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct AuthResponse: Codable {
    let token: String
    let userId: String
    let email: String
    let name: String
}

struct FundAccountRequest: Codable {
    let userId: String
    let amount: Double
    let currency: String
}

struct ExchangeRequest: Codable {
    let userId: String
    let fromCurrency: String
    let toCurrency: String
    let fromAmount: Double
    let toAmount: Double
    let exchangeRate: Double
    let transactionType: String
}

struct ErrorResponse: Codable {
    let error: String
}

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authToken: String?
    private let baseURL = Constants.API.baseURL
    
    private init() {}
    
    // MARK: - Authentication
    
    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw APIError.invalidURL
        }
        
        let request = RegisterRequest(email: email, password: password, name: name)
        
        let response: AuthResponse = try await performRequest(url: url, method: "POST", body: request)
        
        // Store auth token
        self.authToken = response.token
        
        return response
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw APIError.invalidURL
        }
        
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await performRequest(url: url, method: "POST", body: request)
        
        // Store auth token
        self.authToken = response.token
        
        return response
    }
    
    func clearToken() {
        self.authToken = nil
    }
    
    // MARK: - Wallet Operations
    
    func fundAccount(userId: String, amount: Double, currency: String = "PLN") async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/wallet/fund") else {
            throw APIError.invalidURL
        }
        
        let request = FundAccountRequest(userId: userId, amount: amount, currency: currency)
        
        let _: [String: String] = try await performAuthenticatedRequest(url: url, method: "POST", body: request)
    }
    
    func getWalletBalances(userId: String) async throws -> [CurrencyWallet] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/wallet/\(userId)") else {
            throw APIError.invalidURL
        }
        
        // For now, return mock data since backend isn't running yet
        // This will be replaced with actual API call
        return []
    }
    
    // MARK: - Exchange Operations
    
    func executeExchange(userId: String, fromCurrency: String, toCurrency: String, fromAmount: Double, toAmount: Double, exchangeRate: Double, type: TransactionType) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/exchange") else {
            throw APIError.invalidURL
        }
        
        let request = ExchangeRequest(
            userId: userId,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            fromAmount: fromAmount,
            toAmount: toAmount,
            exchangeRate: exchangeRate,
            transactionType: type.rawValue
        )
        
        let _: [String: String] = try await performAuthenticatedRequest(url: url, method: "POST", body: request)
    }
    
    func getTransactionHistory(userId: String) async throws -> [Transaction] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/exchange/history/\(userId)") else {
            throw APIError.invalidURL
        }
        
        // For now, return empty array since backend isn't running yet
        return []
    }
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Codable, R: Codable>(url: URL, method: String, body: T) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(R.self, from: data)
            
        } catch let error as DecodingError {
            self.errorMessage = APIError.decodingError(error).localizedDescription
            throw APIError.decodingError(error)
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func performAuthenticatedRequest<T: Codable, R: Codable>(url: URL, method: String, body: T) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(R.self, from: data)
            
        } catch let error as DecodingError {
            self.errorMessage = APIError.decodingError(error).localizedDescription
            throw APIError.decodingError(error)
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
}
