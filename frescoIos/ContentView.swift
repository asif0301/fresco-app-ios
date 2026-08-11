import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        Group {
            if !state.isReady {
                SplashView()
            } else if state.isAuthenticated {
                BuyerShellView()
            } else {
                LoginView()
            }
        }
        .tint(FrescoColors.primary)
        .alert("Fresco", isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            FrescoColors.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image("fresco-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                Text("FrescoCanada")
                    .font(.title.bold())
                ProgressView()
                    .tint(FrescoColors.primary)
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showPassword = false
    @State private var showRecovery = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 14) {
                        Image("fresco-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 62, height: 62)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome to Fresco")
                                .font(.title2.weight(.black))
                            Text("Sign in to browse fresh groceries, manage orders, and checkout quickly.")
                                .font(.subheadline)
                                .foregroundStyle(FrescoColors.muted)
                        }
                    }

                    Surface {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Login")
                                .font(.title2.weight(.black))
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .textContentType(.emailAddress)
                                .frescoField()
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField("Password", text: $password)
                                    }
                                }
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                }
                            }
                            .frescoField()
                            Button {
                                Task { await state.login(email: email, password: password) }
                            } label: {
                                if state.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Login")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(email.isEmpty || password.isEmpty || state.isLoading)

                            Button("Forgot password?") {
                                showRecovery = true
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            HStack {
                                Text("Don't have an account?")
                                    .foregroundStyle(FrescoColors.muted)
                                Button("Register") { showRegister = true }
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(20)
            }
            .background(FrescoColors.background)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $showRecovery) {
                AuthRecoveryView(initialEmail: email)
            }
        }
    }
}

enum AuthRecoveryMode: String, CaseIterable, Identifiable {
    case forgotPassword = "Forgot"
    case resetPassword = "Reset"
    case verifyEmail = "Verify"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forgotPassword: "Forgot password"
        case .resetPassword: "Reset password"
        case .verifyEmail: "Verify email"
        }
    }

    var subtitle: String {
        switch self {
        case .forgotPassword: "Enter your email to request a reset OTP."
        case .resetPassword: "Use your reset OTP to set a new password."
        case .verifyEmail: "Enter your email and OTP to verify your account."
        }
    }
}

struct AuthRecoveryView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var mode = AuthRecoveryMode.forgotPassword
    @State private var email: String
    @State private var otp = ""
    @State private var password = ""
    @State private var successMessage: String?

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: mode.title, subtitle: mode.subtitle)

                Picker("Mode", selection: $mode) {
                    ForEach(AuthRecoveryMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Surface {
                    VStack(spacing: 14) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .frescoField()

                        if mode != .forgotPassword {
                            TextField("OTP", text: $otp)
                                .keyboardType(.numberPad)
                                .frescoField()
                        }

                        if mode == .resetPassword {
                            SecureField("New password", text: $password)
                                .frescoField()
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            if state.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(buttonTitle)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canSubmit || state.isLoading)

                        if let successMessage {
                            Text(successMessage)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(FrescoColors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle(mode.title)
    }

    private var buttonTitle: String {
        switch mode {
        case .forgotPassword: "Send OTP"
        case .resetPassword: "Reset password"
        case .verifyEmail: "Verify email"
        }
    }

    private var canSubmit: Bool {
        let hasEmail = email.contains("@")
        switch mode {
        case .forgotPassword:
            return hasEmail
        case .resetPassword:
            return hasEmail && !otp.isEmpty && password.count >= 6
        case .verifyEmail:
            return hasEmail && !otp.isEmpty
        }
    }

    private func submit() async {
        switch mode {
        case .forgotPassword:
            if await state.forgotPassword(email: email) {
                successMessage = "Reset OTP sent"
                mode = .resetPassword
            }
        case .resetPassword:
            if await state.resetPassword(email: email, otp: otp, password: password) {
                dismiss()
            }
        case .verifyEmail:
            if await state.verifyEmail(email: email, otp: otp) {
                successMessage = "Email verified"
            }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var formIsValid: Bool {
        !name.isEmpty && email.contains("@") && !phone.isEmpty && password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        ScrollView {
            Surface {
                VStack(spacing: 14) {
                    TextField("Full name", text: $name).frescoField()
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .frescoField()
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .frescoField()
                    SecureField("Password", text: $password).frescoField()
                    SecureField("Confirm Password", text: $confirmPassword).frescoField()
                    Button {
                        Task {
                            let ok = await state.register(name: name, email: email, phone: phone, password: password)
                            if ok { dismiss() }
                        }
                    } label: {
                        if state.isLoading { ProgressView().tint(.white) } else { Text("Create account") }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!formIsValid || state.isLoading)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Register")
    }
}

struct BuyerShellView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            CategoriesView()
                .tabItem { Label("Category", systemImage: "square.grid.2x2.fill") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            CartView()
                .tabItem { Label("Cart", systemImage: "cart.fill") }
                .badge(state.cartItems.count)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}

extension View {
    func frescoField() -> some View {
        self
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FrescoColors.border, lineWidth: 1)
            )
    }
}

#Preview {
    ContentView()
        .environmentObject(FrescoAppState())
}
