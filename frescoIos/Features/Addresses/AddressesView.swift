import SwiftUI

struct AddressesView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var editingAddress: Address?
    @State private var showAddressForm = false

    var body: some View {
        Group {
            if state.addresses.isEmpty {
                VStack(spacing: 16) {
                    EmptyState(systemImage: "mappin", title: "No Address Found", message: "Add your delivery address to continue shopping.")
                    Button {
                        editingAddress = nil
                        showAddressForm = true
                    } label: {
                        Label("Add Address", systemImage: "plus.circle")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                }
            } else {
                List(state.addresses) { address in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(address.name)
                                .font(.headline.weight(.black))
                            if address.isDefault {
                                Text("Default")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(FrescoColors.primary)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(address.phone)
                            .foregroundStyle(FrescoColors.muted)
                        Text(address.oneLine)
                            .foregroundStyle(FrescoColors.muted)
                        HStack {
                            Button("Edit") {
                                editingAddress = address
                                showAddressForm = true
                            }
                            Button("Set default") {
                                Task { _ = await state.setDefaultAddress(address.id) }
                            }
                            .disabled(address.isDefault)
                            Spacer()
                            Button(role: .destructive) {
                                Task { _ = await state.deleteAddress(address.id) }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .buttonStyle(.borderless)
                        .font(.subheadline.weight(.bold))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Addresses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingAddress = nil
                    showAddressForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddressForm) {
            NavigationStack {
                AddressFormView(address: editingAddress)
            }
        }
        .task { await state.loadProfile(force: true) }
    }
}
