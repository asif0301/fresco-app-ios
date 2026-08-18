import SwiftUI

struct ContactUsView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var reason = ""
    @State private var message = ""

    var body: some View {
        ScrollView {
            Surface {
                VStack(spacing: 14) {
                    TextField("Subject", text: $subject).frescoField()
                    TextField("Name", text: $name).frescoField()
                    TextField("Email", text: $email).keyboardType(.emailAddress).frescoField()
                    TextField("Reason", text: $reason).frescoField()
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(4...6)
                        .frescoField()
                    Button("Submit") {
                        Task {
                            let ok = await state.submitContactUs(subject: subject, name: name, email: email, reason: reason, message: message)
                            if ok { dismiss() }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled([subject, name, email, reason, message].contains { $0.trimmingCharacters(in: .whitespaces).isEmpty } || state.isLoading)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Contact us")
        .onAppear {
            name = state.user.name
            email = state.user.email
        }
    }
}
