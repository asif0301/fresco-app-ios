import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        Group {
            if !state.isReady {
                SplashView()
            } else if state.isAuthenticated {
                BuyerShellView()
            } else {
                LoginView()
            }
        }
        .tint(FrescoColors.primary)
        .alert("Fresco", isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
    }
}

struct BuyerShellView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            CategoriesView()
                .tabItem { Label("Category", systemImage: "square.grid.2x2.fill") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            CartView()
                .tabItem { Label("Cart", systemImage: "cart.fill") }
                .badge(state.cartItems.count)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FrescoAppState())
}
