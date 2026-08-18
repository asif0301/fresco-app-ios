import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image("profile")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                            .padding(10)
                            .background(FrescoColors.background)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(state.user.name.isEmpty ? "Fresco Customer" : state.user.name)
                                .font(.title3.weight(.black))
                            Text(state.user.email)
                                .font(.subheadline)
                                .foregroundStyle(FrescoColors.muted)
                            Text("\(state.user.points) loyalty points")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(FrescoColors.primary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                Section("Account") {
                    NavigationLink(value: Route.orders) {
                        Label("Orders", systemImage: "shippingbox")
                    }
                    NavigationLink(value: Route.addresses) {
                        Label("Addresses", systemImage: "mappin.and.ellipse")
                    }
                    NavigationLink(value: Route.editProfile) {
                        Label("Update profile", systemImage: "pencil")
                    }
                    NavigationLink(value: Route.changePassword) {
                        Label("Change password", systemImage: "lock.rotation")
                    }
                    NavigationLink(value: Route.notifications) {
                        Label("Notifications", systemImage: "bell")
                    }
                    NavigationLink(value: Route.favourites) {
                        Label("Favourites", systemImage: "heart.fill")
                    }
                }
                Section("Support") {
                    NavigationLink(value: Route.cmsPage("about-us")) {
                        Label("About us", systemImage: "doc.text")
                    }
                    NavigationLink(value: Route.cmsPage("terms-and-conditions")) {
                        Label("Terms & conditions", systemImage: "article")
                    }
                    NavigationLink(value: Route.cmsPage("privacy-policy")) {
                        Label("Privacy policy", systemImage: "hand.raised")
                    }
                    NavigationLink(value: Route.contactUs) {
                        Label("Contact us", systemImage: "questionmark.circle")
                    }
                    NavigationLink(value: Route.deleteAccount) {
                        Label("Delete account", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Button(role: .destructive) {
                        state.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .task { await state.loadProfile() }
            .refreshable { await state.loadProfile(force: true) }
        }
    }
}
