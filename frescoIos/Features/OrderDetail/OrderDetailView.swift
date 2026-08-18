import SwiftUI

struct OrderDetailView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    let order: OrderItem
    @State private var reason = ""
    @State private var showCancel = false

    var body: some View {
        List {
            Section {
                detailRow("Order", order.reference)
                detailRow("Status", statusLabel(order.status))
                detailRow("Date", order.dateLabel)
                detailRow("Payment", paymentLabel(order.paymentMethod))
                detailRow("Items", "\(order.itemCount)")
                detailRow("Total", money(order.total))
            }
            if order.status.lowercased() != "cancelled" && order.status.lowercased() != "delivered" {
                Section {
                    Button("Cancel order", role: .destructive) {
                        showCancel = true
                    }
                }
            }
        }
        .navigationTitle("Order detail")
        .alert("Cancel order?", isPresented: $showCancel) {
            TextField("Reason", text: $reason)
            Button("Cancel order", role: .destructive) {
                Task {
                    if await state.cancelOrder(orderId: order.id, reason: reason) {
                        dismiss()
                    }
                }
            }
            Button("Keep order", role: .cancel) {}
        } message: {
            Text("Please enter a reason for cancellation.")
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .foregroundStyle(FrescoColors.muted)
                .multilineTextAlignment(.trailing)
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
