import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject private var state: FrescoAppState
    let product: Product
    @State private var detail: Product?
    @State private var quantity = 1

    var shown: Product { detail ?? product }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RemoteProductImage(url: shown.imageUrl)
                    .frame(height: 280)
                VStack(alignment: .leading, spacing: 10) {
                    Text(shown.category)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(FrescoColors.primary)
                    Text(shown.name)
                        .font(.title2.weight(.black))
                    HStack {
                        Label(String(format: "%.1f", shown.rating), systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(shown.reviewCount) reviews")
                            .foregroundStyle(FrescoColors.muted)
                        Spacer()
                        Text(shown.displayPrice)
                            .font(.title3.weight(.black))
                            .foregroundStyle(FrescoColors.primaryDark)
                    }
                    Text(shown.description.isEmpty ? "Fresh selection from FrescoCanada, ready for your next grocery basket." : shown.description)
                        .font(.body)
                        .foregroundStyle(FrescoColors.muted)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                        .font(.headline)
                    Button {
                        Task { _ = await state.addToCart(shown, quantity: quantity) }
                    } label: {
                        Label("Add to cart", systemImage: "cart.badge.plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .background(FrescoColors.background)
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .task { detail = await state.loadDetail(for: product) }
    }
}
