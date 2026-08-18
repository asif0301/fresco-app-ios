import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""

    var body: some View {
        ScrollView {
            Surface {
                VStack(spacing: 14) {
                    SecureField("Current Password", text: $current).frescoField()
                    SecureField("New Password", text: $newPassword).frescoField()
                    SecureField("Confirm Password", text: $confirm).frescoField()
                    Button("Update Password") {
                        Task {
                            if await state.changePassword(currentPassword: current, newPassword: newPassword) {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(current.isEmpty || newPassword.count < 8 || newPassword != confirm || state.isLoading)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Change Password")
    }
}
