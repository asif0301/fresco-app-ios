import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var paymentMethod = "cod"
    @State private var couponCode = ""
    @State private var couponApplied = false
    @State private var isSummaryLoading = false
    @State private var isPlacingOrder = false
    @State private var successMessage: String?

    private var selectedAddress: Address? {
        state.preferredCheckoutAddress()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isSummaryLoading {
                    ProgressView()
                        .tint(FrescoColors.primary)
                        .frame(maxWidth: .infinity)
                }

                promoSection
                addressSection
                paymentSection
                itemsSection
                summarySection

                Button {
                    Task { await placeOrder() }
                } label: {
                    if isPlacingOrder {
                        HStack {
                            ProgressView().tint(.white)
                            Text("Placing order...")
                        }
                    } else {
                        Text("Place order")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedAddress == nil || paymentMethod.isEmpty || isPlacingOrder || state.cartItems.isEmpty)

                if let successMessage {
                    Text(successMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FrescoColors.primaryDark)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Checkout")
        .task {
            await state.loadProfile(force: true)
            if let selectedAddress {
                await refreshSummary(addressId: selectedAddress.id)
            }
        }
    }

    private var promoSection: some View {
        Surface {
            VStack(alignment: .leading, spacing: 14) {
                Label("Have a promo code?", systemImage: "tag")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(FrescoColors.primaryDark)
                HStack(spacing: 8) {
                    TextField("Coupon code", text: $couponCode)
                        .textInputAutocapitalization(.characters)
                        .frescoField()
                    Button(couponApplied ? "Remove" : "Apply") {
                        Task { await toggleCoupon() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FrescoColors.primary)
                    .frame(width: 96)
                }
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Delivery address", subtitle: "Your order will be delivered here")
            Surface {
                if let address = selectedAddress {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(address.name)
                            .font(.headline.weight(.black))
                        Text(address.phone)
                            .foregroundStyle(FrescoColors.muted)
                        Text(address.oneLine)
                            .foregroundStyle(FrescoColors.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    EmptyState(systemImage: "mappin", title: "No address found", message: "Add a delivery address in your Fresco account before checkout.")
                }
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Payment method", subtitle: "Choose how you would like to pay")
            Surface {
                Picker("Payment method", selection: $paymentMethod) {
                    Label("Cash on delivery", systemImage: "banknote").tag("cod")
                }
                .pickerStyle(.inline)
            }
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Items", subtitle: "\(state.cartItems.count) \(state.cartItems.count == 1 ? "item" : "items") in your order")
            Surface {
                VStack(spacing: 12) {
                    ForEach(state.cartItems) { item in
                        HStack(spacing: 12) {
                            RemoteProductImage(url: item.product.imageUrl)
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.subheadline.weight(.heavy))
                                    .lineLimit(2)
                                Text(item.product.category)
                                    .font(.caption)
                                    .foregroundStyle(FrescoColors.muted)
                                Text("Qty \(item.quantity) x \(item.product.displayPrice)")
                                    .font(.caption.weight(.heavy))
                            }
                            Spacer()
                            Text(money(item.lineTotal))
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(FrescoColors.muted)
                        }
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Order summary", subtitle: "")
            Surface {
                VStack(spacing: 10) {
                    checkoutRow("Items", "\(state.cartItems.count)")
                    checkoutRow("Subtotal", money(state.subtotal))
                    checkoutRow("Shipping", money(state.shipping))
                    checkoutRow("Discount", money(state.discount))
                    Divider()
                    checkoutRow("Total", money(state.total), bold: true)
                }
            }
        }
    }

    private func checkoutRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(bold ? .black : .semibold)
        }
        .foregroundStyle(bold ? FrescoColors.ink : FrescoColors.muted)
    }

    private func toggleCoupon() async {
        guard let address = selectedAddress else { return }
        if couponApplied {
            let removed = await state.removeCoupon()
            if removed {
                couponApplied = false
                couponCode = ""
                await refreshSummary(addressId: address.id)
            }
            return
        }
        guard !couponCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.errorMessage = "Please enter coupon code."
            return
        }
        let ok = await state.applyCoupon(couponCode)
        if ok {
            couponApplied = true
            await refreshSummary(addressId: address.id, couponCode: couponCode)
        }
    }

    private func refreshSummary(addressId: String, couponCode: String? = nil) async {
        isSummaryLoading = true
        _ = await state.refreshCheckoutSummary(addressId: addressId, couponCode: couponCode)
        isSummaryLoading = false
    }

    private func placeOrder() async {
        guard let address = selectedAddress else {
            state.errorMessage = "Add a delivery address to continue to checkout."
            return
        }
        isPlacingOrder = true
        let ok = await state.placeOrder(
            addressId: address.id,
            paymentMethod: paymentMethod,
            couponCode: couponCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : couponCode
        )
        isPlacingOrder = false
        if ok {
            successMessage = "Order placed successfully"
            dismiss()
        }
    }
}
