import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var selectedBanner = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TabView(selection: $selectedBanner) {
                        ForEach(Array(state.banners.enumerated()), id: \.element.id) { index, banner in
                            BannerCard(banner: banner)
                                .tag(index)
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(height: 230)
                    .tabViewStyle(.page(indexDisplayMode: .always))

                    sectionHeader("Categories", subtitle: "Fresh departments for every basket")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(state.categories) { category in
                                NavigationLink(value: Route.category(category)) {
                                    CategoryTile(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    productsRow(title: "Featured", subtitle: "Curated picks for the week", products: state.featuredProducts.isEmpty ? state.products : state.featuredProducts)

                    if !state.recommendedProducts.isEmpty {
                        productsRow(title: "Recommended", subtitle: "More picks from Fresco", products: state.recommendedProducts)
                    }

                    productsRow(title: "Best Sellers", subtitle: "Fast choices for everyday baskets", products: state.bestSellers)
                }
                .padding(.vertical, 16)
            }
            .background(FrescoColors.background)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        Image("fresco-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("FrescoCanada")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text("Freshness guaranteed")
                                .font(.caption2)
                                .foregroundStyle(Color.white.opacity(0.82))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.notifications) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.headline)
                            BadgeCount(count: state.unreadNotifications)
                                .offset(x: 9, y: -8)
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(FrescoColors.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .task { await state.loadHome() }
            .refreshable { await state.loadHome(force: true) }
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        SectionTitle(title: title, subtitle: subtitle)
            .padding(.horizontal, 20)
    }

    private func productsRow(title: String, subtitle: String, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(title: title, subtitle: subtitle)
                Spacer()
                NavigationLink("See all", value: Route.products(title, products))
                    .font(.subheadline.weight(.heavy))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(products) { product in
                        NavigationLink(value: Route.product(product)) {
                            ProductCard(product: product, compact: false) {
                                Task { _ = await state.addToCart(product) }
                            } favouriteAction: {
                                state.toggleFavourite(product)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct CategoriesView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        NavigationStack {
            List(state.categories) { category in
                NavigationLink(value: Route.category(category)) {
                    HStack(spacing: 14) {
                        CategoryTile(category: category)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.headline.weight(.black))
                            Text(category.slug.isEmpty ? "Fresh grocery department" : category.slug)
                                .font(.subheadline)
                                .foregroundStyle(FrescoColors.muted)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.plain)
            .background(FrescoColors.background)
            .navigationTitle("Categories")
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .task { await state.loadCategories() }
            .refreshable { await state.loadCategories(force: true) }
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var query = ""
    @State private var results: [Product] = demoProducts

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                    ForEach(results) { product in
                        NavigationLink(value: Route.product(product)) {
                            ProductCard(product: product, compact: true) {
                                Task { _ = await state.addToCart(product) }
                            } favouriteAction: {
                                state.toggleFavourite(product)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(FrescoColors.background)
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search fresh groceries")
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .task { results = await state.loadProducts() }
            .onChange(of: query) { _, value in
                Task { results = await state.loadProducts(query: value) }
            }
        }
    }
}

struct ProductListView: View {
    @EnvironmentObject private var state: FrescoAppState
    let title: String
    let initialProducts: [Product]
    @State private var products: [Product] = []

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                ForEach(products) { product in
                    NavigationLink(value: Route.product(product)) {
                        ProductCard(product: product, compact: true) {
                            Task { _ = await state.addToCart(product) }
                        } favouriteAction: {
                            state.toggleFavourite(product)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle(title)
        .onAppear {
            if products.isEmpty { products = initialProducts }
        }
    }
}

struct CategoryProductView: View {
    @EnvironmentObject private var state: FrescoAppState
    let category: CategoryItem
    @State private var products: [Product] = []
    @State private var loading = true

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(FrescoColors.primary)
            } else if products.isEmpty {
                EmptyState(systemImage: "tray", title: "No products yet", message: "This category does not have products available right now.")
            } else {
                ProductListView(title: category.name, initialProducts: products)
            }
        }
        .navigationTitle(category.name)
        .task {
            products = await state.loadProducts(category: category)
            loading = false
        }
    }
}

struct ProductDetailView: View {
    @EnvironmentObject private var state: FrescoAppState
    let product: Product
    @State private var detail: Product?
    @State private var quantity = 1

    var shown: Product { detail ?? product }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RemoteProductImage(url: shown.imageUrl)
                    .frame(height: 280)
                VStack(alignment: .leading, spacing: 10) {
                    Text(shown.category)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(FrescoColors.primary)
                    Text(shown.name)
                        .font(.title2.weight(.black))
                    HStack {
                        Label(String(format: "%.1f", shown.rating), systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(shown.reviewCount) reviews")
                            .foregroundStyle(FrescoColors.muted)
                        Spacer()
                        Text(shown.displayPrice)
                            .font(.title3.weight(.black))
                            .foregroundStyle(FrescoColors.primaryDark)
                    }
                    Text(shown.description.isEmpty ? "Fresh selection from FrescoCanada, ready for your next grocery basket." : shown.description)
                        .font(.body)
                        .foregroundStyle(FrescoColors.muted)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                        .font(.headline)
                    Button {
                        Task { _ = await state.addToCart(shown, quantity: quantity) }
                    } label: {
                        Label("Add to cart", systemImage: "cart.badge.plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .background(FrescoColors.background)
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .task { detail = await state.loadDetail(for: product) }
    }
}

struct CartView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var showDeliveryAddress = false

    var body: some View {
        NavigationStack {
            Group {
                if state.cartItems.isEmpty {
                    EmptyState(systemImage: "cart", title: "Your cart is empty", message: "Add fresh groceries from home or search to start checkout.")
                } else {
                    List {
                        ForEach(state.cartItems) { item in
                            HStack(spacing: 12) {
                                RemoteProductImage(url: item.product.imageUrl)
                                    .frame(width: 72, height: 72)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.product.name)
                                        .font(.headline.weight(.black))
                                    Text(item.product.displayPrice)
                                        .font(.subheadline.weight(.heavy))
                                        .foregroundStyle(FrescoColors.primaryDark)
                                    Stepper("Qty \(item.quantity)", value: Binding(
                                        get: { item.quantity },
                                        set: { state.updateCartItem(item, quantity: $0) }
                                    ), in: 1...99)
                                    .font(.caption.weight(.heavy))
                                }
                                Spacer()
                                Text(money(item.lineTotal))
                                    .font(.headline.weight(.black))
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    state.removeCartItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        Section {
                            totalRow("Subtotal", state.subtotal)
                            totalRow("Shipping", state.shipping)
                            totalRow("Discount", -state.discount)
                            totalRow("Total", state.total, bold: true)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(FrescoColors.background)
            .navigationTitle("Cart")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Proceed to checkout") {
                        showDeliveryAddress = true
                    }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(state.cartItems.isEmpty)
                }
            }
            .navigationDestination(isPresented: $showDeliveryAddress) {
                DeliveryAddressView()
            }
            .task { await state.loadCart() }
            .refreshable { await state.loadCart(force: true) }
        }
    }

    private func totalRow(_ title: String, _ value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(money(value))
                .fontWeight(bold ? .black : .semibold)
        }
    }
}

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

struct CheckoutView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    @State private var paymentMethod = "cod"
    @State private var couponCode = ""
    @State private var couponApplied = false
    @State private var isSummaryLoading = false
    @State private var isPlacingOrder = false
    @State private var successMessage: String?

    private var selectedAddress: Address? {
        state.preferredCheckoutAddress()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isSummaryLoading {
                    ProgressView()
                        .tint(FrescoColors.primary)
                        .frame(maxWidth: .infinity)
                }

                promoSection
                addressSection
                paymentSection
                itemsSection
                summarySection

                Button {
                    Task { await placeOrder() }
                } label: {
                    if isPlacingOrder {
                        HStack {
                            ProgressView().tint(.white)
                            Text("Placing order...")
                        }
                    } else {
                        Text("Place order")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedAddress == nil || paymentMethod.isEmpty || isPlacingOrder || state.cartItems.isEmpty)

                if let successMessage {
                    Text(successMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FrescoColors.primaryDark)
                }
            }
            .padding(20)
        }
        .background(FrescoColors.background)
        .navigationTitle("Checkout")
        .task {
            await state.loadProfile(force: true)
            if let selectedAddress {
                await refreshSummary(addressId: selectedAddress.id)
            }
        }
    }

    private var promoSection: some View {
        Surface {
            VStack(alignment: .leading, spacing: 14) {
                Label("Have a promo code?", systemImage: "tag")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(FrescoColors.primaryDark)
                HStack(spacing: 8) {
                    TextField("Coupon code", text: $couponCode)
                        .textInputAutocapitalization(.characters)
                        .frescoField()
                    Button(couponApplied ? "Remove" : "Apply") {
                        Task { await toggleCoupon() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FrescoColors.primary)
                    .frame(width: 96)
                }
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Delivery address", subtitle: "Your order will be delivered here")
            Surface {
                if let address = selectedAddress {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(address.name)
                            .font(.headline.weight(.black))
                        Text(address.phone)
                            .foregroundStyle(FrescoColors.muted)
                        Text(address.oneLine)
                            .foregroundStyle(FrescoColors.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    EmptyState(systemImage: "mappin", title: "No address found", message: "Add a delivery address in your Fresco account before checkout.")
                }
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Payment method", subtitle: "Choose how you would like to pay")
            Surface {
                Picker("Payment method", selection: $paymentMethod) {
                    Label("Cash on delivery", systemImage: "banknote").tag("cod")
                }
                .pickerStyle(.inline)
            }
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Items", subtitle: "\(state.cartItems.count) \(state.cartItems.count == 1 ? "item" : "items") in your order")
            Surface {
                VStack(spacing: 12) {
                    ForEach(state.cartItems) { item in
                        HStack(spacing: 12) {
                            RemoteProductImage(url: item.product.imageUrl)
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.subheadline.weight(.heavy))
                                    .lineLimit(2)
                                Text(item.product.category)
                                    .font(.caption)
                                    .foregroundStyle(FrescoColors.muted)
                                Text("Qty \(item.quantity) x \(item.product.displayPrice)")
                                    .font(.caption.weight(.heavy))
                            }
                            Spacer()
                            Text(money(item.lineTotal))
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(FrescoColors.muted)
                        }
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Order summary", subtitle: "")
            Surface {
                VStack(spacing: 10) {
                    checkoutRow("Items", "\(state.cartItems.count)")
                    checkoutRow("Subtotal", money(state.subtotal))
                    checkoutRow("Shipping", money(state.shipping))
                    checkoutRow("Discount", money(state.discount))
                    Divider()
                    checkoutRow("Total", money(state.total), bold: true)
                }
            }
        }
    }

    private func checkoutRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(bold ? .black : .semibold)
        }
        .foregroundStyle(bold ? FrescoColors.ink : FrescoColors.muted)
    }

    private func toggleCoupon() async {
        guard let address = selectedAddress else { return }
        if couponApplied {
            let removed = await state.removeCoupon()
            if removed {
                couponApplied = false
                couponCode = ""
                await refreshSummary(addressId: address.id)
            }
            return
        }
        guard !couponCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.errorMessage = "Please enter coupon code."
            return
        }
        let ok = await state.applyCoupon(couponCode)
        if ok {
            couponApplied = true
            await refreshSummary(addressId: address.id, couponCode: couponCode)
        }
    }

    private func refreshSummary(addressId: String, couponCode: String? = nil) async {
        isSummaryLoading = true
        _ = await state.refreshCheckoutSummary(addressId: addressId, couponCode: couponCode)
        isSummaryLoading = false
    }

    private func placeOrder() async {
        guard let address = selectedAddress else {
            state.errorMessage = "Add a delivery address to continue to checkout."
            return
        }
        isPlacingOrder = true
        let ok = await state.placeOrder(
            addressId: address.id,
            paymentMethod: paymentMethod,
            couponCode: couponCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : couponCode
        )
        isPlacingOrder = false
        if ok {
            successMessage = "Order placed successfully"
            dismiss()
        }
    }
}

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

struct NotificationsView: View {
    @EnvironmentObject private var state: FrescoAppState

    var body: some View {
        List(state.notifications) { item in
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.isRead ? "bell" : "bell.fill")
                    .foregroundStyle(FrescoColors.primary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline.weight(.black))
                    Text(item.message)
                        .foregroundStyle(FrescoColors.muted)
                    Text(item.timeLabel)
                        .font(.caption)
                        .foregroundStyle(FrescoColors.muted)
                }
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Notifications")
    }
}

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

struct AddressFormView: View {
    @EnvironmentObject private var state: FrescoAppState
    @Environment(\.dismiss) private var dismiss
    let address: Address?

    init(address: Address? = nil) {
        self.address = address
    }

    @State private var name = ""
    @State private var phone = ""
    @State private var line1 = ""
    @State private var city = ""
    @State private var postalCode = ""
    @State private var stateName = ""
    @State private var countryName = ""
    @State private var stateId: String?
    @State private var countryId: String?
    @State private var isDefault = false
    @State private var countries: [LocationOption] = []
    @State private var states: [LocationOption] = []
    @State private var submitting = false

    var body: some View {
        Form {
            Section {
                TextField("Full name", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Street Address", text: $line1)
                TextField("City", text: $city)
                TextField("Postal Code", text: $postalCode)
                    .keyboardType(.numberPad)
            }

            Section {
                if countries.isEmpty {
                    TextField("Country", text: $countryName)
                    TextField("State / Province", text: $stateName)
                } else {
                    Picker("Country", selection: Binding(
                        get: { countryId ?? countries.first?.id ?? "" },
                        set: { id in
                            countryId = id
                            countryName = countries.first(where: { $0.id == id })?.label ?? ""
                            stateId = nil
                            stateName = ""
                            Task { await loadStates() }
                        }
                    )) {
                        ForEach(countries) { option in
                            Text(option.label).tag(option.id)
                        }
                    }

                    if states.isEmpty {
                        TextField("State / Province", text: $stateName)
                    } else {
                        Picker("State / Province", selection: Binding(
                            get: { stateId ?? states.first?.id ?? "" },
                            set: { id in
                                stateId = id
                                stateName = states.first(where: { $0.id == id })?.label ?? ""
                            }
                        )) {
                            ForEach(states) { option in
                                Text(option.label).tag(option.id)
                            }
                        }
                    }
                }
                Toggle("Set as default", isOn: $isDefault)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if submitting {
                        ProgressView()
                    } else {
                        Text(address == nil ? "Save Address" : "Update Address")
                    }
                }
                .disabled(!canSave || submitting)
            }
        }
        .navigationTitle(address == nil ? "Add Address" : "Update Address")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear(perform: fillForm)
        .task {
            countries = await state.loadCountries()
            if countryId == nil, let first = countries.first {
                countryId = first.id
                countryName = first.label
            }
            await loadStates()
        }
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty &&
        !phone.trimmed.isEmpty &&
        !line1.trimmed.isEmpty &&
        !city.trimmed.isEmpty &&
        !postalCode.trimmed.isEmpty &&
        !countryName.trimmed.isEmpty &&
        !stateName.trimmed.isEmpty
    }

    private func fillForm() {
        guard let address else { return }
        name = address.name
        phone = address.phone
        line1 = address.line1
        city = address.city
        postalCode = address.postalCode
        stateName = address.state
        countryName = address.country
        stateId = address.stateId
        countryId = address.countryId
        isDefault = address.isDefault
    }

    private func loadStates() async {
        guard let countryId, !countryId.isEmpty else { return }
        states = await state.loadStates(countryId: countryId)
        if stateId == nil, let first = states.first {
            stateId = first.id
            stateName = first.label
        }
    }

    private func save() async {
        submitting = true
        let saved = Address(
            id: address?.id ?? "a-\(Int(Date().timeIntervalSince1970 * 1000))",
            name: name.trimmed,
            phone: phone.trimmed,
            line1: line1.trimmed,
            city: city.trimmed,
            state: stateName.trimmed,
            postalCode: postalCode.trimmed,
            country: countryName.trimmed,
            stateId: stateId,
            countryId: countryId,
            isDefault: isDefault
        )
        let ok = await state.upsertAddress(saved)
        submitting = false
        if ok {
            dismiss()
        }
    }
}

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

struct FavouritesView: View {
    @EnvironmentObject private var state: FrescoAppState

    var favourites: [Product] {
        let values = state.favouriteProducts.isEmpty ? state.products.filter(\.isFavourite) : state.favouriteProducts
        return values
    }

    var body: some View {
        Group {
            if favourites.isEmpty {
                EmptyState(systemImage: "heart", title: "No favourites yet", message: "Tap the heart icon on any product to save it here.")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 164), spacing: 14)], spacing: 14) {
                        ForEach(favourites) { product in
                            NavigationLink(value: Route.product(product)) {
                                ProductCard(product: product, compact: true) {
                                    Task { _ = await state.addToCart(product) }
                                } favouriteAction: {
                                    state.toggleFavourite(product)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .background(FrescoColors.background)
            }
        }
        .navigationTitle("Favourites")
        .navigationDestination(for: Route.self) { route in destination(route) }
        .task { await state.loadProfile(force: true) }
    }
}

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

struct CmsPageView: View {
    @EnvironmentObject private var state: FrescoAppState
    let slug: String
    @State private var page: CmsPage?
    @State private var loaded = false

    var body: some View {
        Group {
            if !loaded {
                ProgressView().tint(FrescoColors.primary)
            } else if let page {
                ScrollView {
                    Surface {
                        Text(page.plainBody.isEmpty ? page.body : page.plainBody)
                            .font(.body)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                }
                .background(FrescoColors.background)
            } else {
                EmptyState(systemImage: "doc.text", title: "No page content", message: "The API did not return content for this page.")
            }
        }
        .navigationTitle(page?.title ?? slug)
        .task {
            page = await state.loadPage(slug: slug)
            loaded = true
        }
    }
}

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

enum Route: Hashable {
    case product(Product)
    case products(String, [Product])
    case category(CategoryItem)
    case notifications
    case addresses
    case orders
    case orderDetail(OrderItem)
    case favourites
    case editProfile
    case changePassword
    case contactUs
    case deleteAccount
    case cmsPage(String)
}

@ViewBuilder
func destination(_ route: Route) -> some View {
    switch route {
    case .product(let product):
        ProductDetailView(product: product)
    case .products(let title, let products):
        ProductListView(title: title, initialProducts: products)
    case .category(let category):
        CategoryProductView(category: category)
    case .notifications:
        NotificationsView()
    case .addresses:
        AddressesView()
    case .orders:
        OrdersView()
    case .orderDetail(let order):
        OrderDetailView(order: order)
    case .favourites:
        FavouritesView()
    case .editProfile:
        EditProfileView()
    case .changePassword:
        ChangePasswordView()
    case .contactUs:
        ContactUsView()
    case .deleteAccount:
        DeleteAccountView()
    case .cmsPage(let slug):
        CmsPageView(slug: slug)
    }
}
