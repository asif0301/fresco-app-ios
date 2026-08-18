import SwiftUI

struct CategoryProductView: View {
    @EnvironmentObject private var state: FrescoAppState
    let category: CategoryItem
    @State private var products: [Product] = []
    @State private var loading = true

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(FrescoColors.primary)
            } else if products.isEmpty {
                EmptyState(systemImage: "tray", title: "No products yet", message: "This category does not have products available right now.")
            } else {
                ProductListView(title: category.name, initialProducts: products)
            }
        }
        .navigationTitle(category.name)
        .task {
            products = await state.loadProducts(category: category)
            loading = false
        }
    }
}
