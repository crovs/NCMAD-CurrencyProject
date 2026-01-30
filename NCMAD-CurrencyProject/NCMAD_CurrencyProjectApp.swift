//
//  NCMAD_CurrencyProjectApp.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI
import SwiftData

@main
struct NCMAD_CurrencyProjectApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var walletViewModel = WalletViewModel()
    @StateObject private var exchangeViewModel = ExchangeViewModel()
    @StateObject private var nbpService = NBPService.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            CurrencyWallet.self,
            Transaction.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(walletViewModel)
                .environmentObject(exchangeViewModel)
                .environmentObject(nbpService)
                .onAppear {
                    authViewModel.setModelContext(sharedModelContainer.mainContext)
                    walletViewModel.setModelContext(sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DashboardView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            authViewModel.checkAuthState()
        }
    }
}
