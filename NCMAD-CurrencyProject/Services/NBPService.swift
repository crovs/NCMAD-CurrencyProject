//
//  NBPService.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import Combine

enum NBPError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        }
    }
}

@MainActor
class NBPService: ObservableObject {
    static let shared = NBPService()
    
    @Published var currentRates: [CurrencyRate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    /// Fetch current currency rates from NBP API
    func fetchCurrentRates() async throws -> [CurrencyRate] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: Constants.API.nbpCurrentRates) else {
            throw NBPError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NBPError.noData
            }
            
            let decoder = JSONDecoder()
            let tables = try decoder.decode([NBPTableResponse].self, from: data)
            
            guard let firstTable = tables.first else {
                throw NBPError.noData
            }
            
            currentRates = firstTable.rates
            return firstTable.rates
            
        } catch let error as DecodingError {
            self.errorMessage = NBPError.decodingError(error).localizedDescription
            throw NBPError.decodingError(error)
        } catch {
            self.errorMessage = NBPError.networkError(error).localizedDescription
            throw NBPError.networkError(error)
        }
    }
    
    /// Fetch historical rates for a specific currency
    func fetchHistoricalRates(currency: String, days: Int = 30) async throws -> [HistoricalRate] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let urlString = Constants.API.nbpHistoricalRates(currency: currency, days: days)
        
        guard let url = URL(string: urlString) else {
            throw NBPError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NBPError.noData
            }
            
            let decoder = JSONDecoder()
            let historicalResponse = try decoder.decode(NBPHistoricalResponse.self, from: data)
            
            return historicalResponse.rates
            
        } catch let error as DecodingError {
            self.errorMessage = NBPError.decodingError(error).localizedDescription
            throw NBPError.decodingError(error)
        } catch {
            self.errorMessage = NBPError.networkError(error).localizedDescription
            throw NBPError.networkError(error)
        }
    }
    
    /// Get exchange rate for a specific currency
    func getExchangeRate(for currencyCode: String) -> Double? {
        return currentRates.first(where: { $0.code == currencyCode })?.mid
    }
    
    /// Convert amount from one currency to another using current rates
    func convertCurrency(amount: Decimal, from: String, to: String) -> Decimal? {
        // PLN is the base currency in NBP
        if from == "PLN" {
            guard let toRate = getExchangeRate(for: to) else { return nil }
            return amount / Decimal(toRate)
        } else if to == "PLN" {
            guard let fromRate = getExchangeRate(for: from) else { return nil }
            return amount * Decimal(fromRate)
        } else {
            // Convert from -> PLN -> to
            guard let fromRate = getExchangeRate(for: from),
                  let toRate = getExchangeRate(for: to) else { return nil }
            let plnAmount = amount * Decimal(fromRate)
            return plnAmount / Decimal(toRate)
        }
    }
}
