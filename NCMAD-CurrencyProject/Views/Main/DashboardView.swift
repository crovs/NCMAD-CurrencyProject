//
//  DashboardView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var exchangeViewModel: ExchangeViewModel
    @EnvironmentObject var nbpService: NBPService
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass.fill")
                }
                .tag(0)
            
            ExchangeView()
                .tabItem {
                    Label("Exchange", systemImage: "arrow.left.arrow.right.circle.fill")
                }
                .tag(1)
            
            RatesView()
                .tabItem {
                    Label("Rates", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color(hex: "00d4ff"))
        .onAppear {
            setupUserData()
            loadInitialData()
        }
    }
    
    private func setupUserData() {
        if let user = authViewModel.currentUser {
            walletViewModel.setUserId(user.id)
            
            // Get model context from environment
            if let context = walletViewModel.modelContext {
                exchangeViewModel.setDependencies(
                    walletViewModel: walletViewModel,
                    modelContext: context,
                    userId: user.id
                )
            }
        }
    }
    
    private func loadInitialData() {
        Task {
            do {
                _ = try await nbpService.fetchCurrentRates()
            } catch {
                print("Failed to load NBP rates: \(error)")
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(WalletViewModel())
        .environmentObject(ExchangeViewModel())
        .environmentObject(NBPService.shared)
}
