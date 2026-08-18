import SwiftUI

struct OrdersView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        Group {
            if state.orders.isEmpty {
                EmptyState(systemImage: "shippingbox", title: "No orders", message: "Your Fresco orders and delivery status will appear here.")
            } else {
                List(state.orders) { order in
                    NavigationLink(value: Route.orderDetail(order)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(order.reference)
                                    .font(.headline.weight(.black))
                                Spacer()
                                Text(money(order.total))
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(FrescoColors.primaryDark)
                            }
                            HStack {
                                Text(statusLabel(order.status))
                                Spacer()
                                Text(paymentLabel(order.paymentMethod))
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(FrescoColors.muted)
                            Text(order.dateLabel)
                                .font(.caption)
                                .foregroundStyle(FrescoColors.muted)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Orders")
        .navigationDestination(for: Route.self) { route in
            destination(route)
        }
    }

    private func statusLabel(_ value: String) -> String {
        value.split(separator: "_").map { $0.capitalized }.joined(separator: " ")
    }

    private func paymentLabel(_ value: String) -> String {
        switch value.lowercased() {
        case "cod", "cash on delivery": "Cash on delivery"
        default: value.split(separator: "_").map { $0.capitalized }.joined(separator: " ")
        }
    }
}
