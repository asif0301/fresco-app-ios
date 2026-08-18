import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject private var state: FrescoAppState

    var favourites: [Product] {
        let values = state.favouriteProducts.isEmpty ? state.products.filter(\.isFavourite) : state.favouriteProducts
        return values
    }

    var body: some View {
        Group {
            if favourites.isEmpty {
                EmptyState(systemImage: "heart", title: "No favourites yet", message: "Tap the heart icon on any product to save it here.")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                        ForEach(favourites) { product in
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
            }
        }
        .navigationTitle("Favourites")
        .navigationDestination(for: Route.self) { route in destination(route) }
        .task { await state.loadProfile(force: true) }
    }
}
