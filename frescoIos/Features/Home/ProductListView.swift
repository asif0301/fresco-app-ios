import SwiftUI

struct ProductListView: View {
    @EnvironmentObject private var state: FrescoAppState
    let title: String
    let initialProducts: [Product]
    @State private var products: [Product] = []

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                ForEach(products) { product in
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
        .navigationTitle(title)
        .onAppear {
            if products.isEmpty { products = initialProducts }
        }
    }
}
