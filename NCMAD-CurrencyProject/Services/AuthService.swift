//
//  AuthService.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import Security

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Keychain Operations
    
    func saveToken(_ token: String) {
        save(key: Constants.Keychain.authToken, value: token)
    }
    
    func getToken() -> String? {
        return get(key: Constants.Keychain.authToken)
    }
    
    func saveUserId(_ userId: String) {
        save(key: Constants.Keychain.userId, value: userId)
    }
    
    func getUserId() -> String? {
        return get(key: Constants.Keychain.userId)
    }
    
    func clearAuth() {
        delete(key: Constants.Keychain.authToken)
        delete(key: Constants.Keychain.userId)
    }
    
    // MARK: - Keychain Helper Methods
    
    private func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Auth State
    
    func isLoggedIn() -> Bool {
        return getToken() != nil && getUserId() != nil
    }
}
