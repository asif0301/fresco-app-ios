import SwiftUI

struct CartView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var showDeliveryAddress = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if state.cartItems.isEmpty {
                    EmptyState(systemImage: "cart", title: "Your cart is empty", message: "Add fresh groceries from home or search to start checkout.")
                        .padding(.top, 80)
                        .padding(.horizontal, 20)
                } else {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cart summary")
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(FrescoColors.ink)
                                Text("Review items before checkout")
                                    .font(.title3)
                                    .foregroundStyle(FrescoColors.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                            }
                            .layoutPriority(1)

                            Spacer()

                            Button("Clear all") {
                                state.clearCart()
                            }
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(FrescoColors.primary)
                            .fixedSize()
                            .padding(.top, 38)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(state.cartItems) { item in
                            CartItemCard(item: item) { quantity in
                                state.updateCartItem(item, quantity: quantity)
                            } deleteAction: {
                                state.removeCartItem(item)
                            }
                        }

                        CartTotalsCard(
                            subtotal: state.subtotal,
                            shipping: state.shipping,
                            discount: state.discount,
                            total: state.total
                        )

                        Button("Proceed to checkout") {
                            showDeliveryAddress = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }
            }
           
            .background(FrescoColors.background)
            .navigationTitle("Cart")
            .navigationDestination(isPresented: $showDeliveryAddress) {
                DeliveryAddressView()
            }
            .task { await state.loadCart() }
            .refreshable { await state.loadCart(force: true) }
        }
    }
}

struct CartItemCard: View {
    let item: CartItem
    let quantityAction: (Int) -> Void
    let deleteAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RemoteProductImage(url: item.product.imageUrl)
                .frame(width: 102, height: 102)
                .layoutPriority(1)

            VStack(alignment: .leading, spacing: 12) {
                Text(item.product.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(FrescoColors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(item.product.category.isEmpty ? "Fresh grocery" : item.product.category)
                    .font(.headline)
                    .foregroundStyle(FrescoColors.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(String(format: "%.2f USD", item.product.salePrice))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(FrescoColors.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(spacing: 14) {
                    quantityButton(systemImage: "minus.circle", disabled: item.quantity <= 1) {
                        quantityAction(item.quantity - 1)
                    }

                    Text("\(item.quantity)")
                        .font(.title3.weight(.black))
                        .foregroundStyle(FrescoColors.ink)
                        .frame(minWidth: 20)

                    quantityButton(systemImage: "plus.circle") {
                        quantityAction(item.quantity + 1)
                    }

                    Spacer()

                    Button(action: deleteAction) {
                        Image(systemName: "trash")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(FrescoColors.primary)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FrescoColors.border, lineWidth: 1.2)
        )
    }

    private func quantityButton(systemImage: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(disabled ? FrescoColors.muted.opacity(0.35) : FrescoColors.ink.opacity(0.78))
                .frame(width: 34, height: 34)
        }
        .disabled(disabled)
    }
}

struct CartTotalsCard: View {
    let subtotal: Double
    let shipping: Double
    let discount: Double
    let total: Double

    var body: some View {
        VStack(spacing: 18) {
            totalRow("Subtotal", subtotal)
            totalRow("Shipping", shipping)
            totalRow("Discount", discount)
            Divider()
                .overlay(FrescoColors.muted.opacity(0.35))
                .padding(.vertical, 2)
            totalRow("Total", total, bold: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FrescoColors.border, lineWidth: 1.2)
        )
    }

    private func totalRow(_ title: String, _ value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(format: "%.2f USD", value))
        }
        .font(bold ? .title2.weight(.black) : .title3.weight(.bold))
        .foregroundStyle(FrescoColors.ink)
    }
}
