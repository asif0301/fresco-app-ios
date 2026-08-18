import SwiftUI

struct DeliveryAddressView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var showCheckout = false
    @State private var showAddressForm = false

    private var selectedAddress: Address? {
        state.preferredCheckoutAddress()
    }

    var body: some View {
        List {
            Section {
                if state.profileLoading {
                    ProgressView()
                        .tint(FrescoColors.primary)
                        .frame(maxWidth: .infinity)
                } else if state.addresses.isEmpty {
                    EmptyState(systemImage: "mappin", title: "No saved addresses", message: "Add a delivery address to continue to checkout.")
                } else {
                    ForEach(state.addresses) { address in
                        Button {
                            state.saveSelectedAddress(address)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selectedAddress?.id == address.id ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(FrescoColors.primary)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(address.name)
                                        .font(.headline.weight(.black))
                                        .foregroundStyle(FrescoColors.ink)
                                    Text(address.phone)
                                        .font(.subheadline)
                                        .foregroundStyle(FrescoColors.muted)
                                    Text(address.oneLine)
                                        .font(.subheadline)
                                        .foregroundStyle(FrescoColors.muted)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Where should we deliver?")
            } footer: {
                Text("Select the address for this order.")
            }

            Section {
                Button {
                    showAddressForm = true
                } label: {
                    Label("Add a new address", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Delivery address")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Continue to checkout") {
                    if let selectedAddress {
                        state.saveSelectedAddress(selectedAddress)
                        showCheckout = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedAddress == nil || state.cartItems.isEmpty)
            }
        }
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView()
        }
        .sheet(isPresented: $showAddressForm) {
            NavigationStack {
                AddressFormView()
            }
        }
        .task { await state.loadProfile(force: true) }
    }
}
