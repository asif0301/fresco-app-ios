import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        ScrollView {
            Surface {
                VStack(spacing: 14) {
                    TextField("Full name", text: $name).frescoField()
                    TextField("Email", text: $email).disabled(true).frescoField()
                    TextField("Phone", text: $phone).keyboardType(.phonePad).frescoField()
                    Button("Save Changes") {
                        Task {
                            if await state.updateProfile(name: name, email: email, phone: phone) {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || state.isLoading)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Update profile")
        .onAppear {
            name = state.user.name
            email = state.user.email
            phone = state.user.phone
        }
    }
}
