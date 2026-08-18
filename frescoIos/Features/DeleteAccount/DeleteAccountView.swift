import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            Surface {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Delete your account")
                        .font(.title3.weight(.black))
                    Text("Deleting your account will permanently remove your information. This action cannot be undone.")
                        .foregroundStyle(FrescoColors.muted)
                    TextField("Reason (Optional)", text: $reason, axis: .vertical)
                        .lineLimit(4...6)
                        .frescoField()
                    HStack {
                        Button("Request Delete") {
                            Task {
                                if await state.requestAccountDelete(reason: reason) {
                                    state.logout()
                                    dismiss()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(FrescoColors.primary)
                        Button("Delete Now", role: .destructive) {
                            confirmDelete = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(FrescoColors.primary)
                    }
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Delete Account")
        .confirmationDialog("Delete account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    if await state.deleteAccountNow() {
                        state.logout()
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
