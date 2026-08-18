import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var query = ""
    @State private var results: [Product] = demoProducts

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                    ForEach(results) { product in
                        NavigationLink(value: Route.product(product)) {
                            ProductCard(product: product, compact: true) {
                                Task { _ = await state.addToCart(product) }
                            } favouriteAction: {
                                state.toggleFavourite(product)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(FrescoColors.background)
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search fresh groceries")
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .task { results = await state.loadProducts() }
            .onChange(of: query) { _, value in
                Task { results = await state.loadProducts(query: value) }
            }
        }
    }
}
