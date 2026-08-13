import Foundation
import SwiftUI

@MainActor
final class FrescoAppState: ObservableObject {
    @Published var isReady = false
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var user = AppUser.guest
    @Published var banners = demoBanners
    @Published var categories = demoCategories
    @Published var products = demoProducts
    @Published var featuredProducts = demoProducts.filter(\.isFeatured)
    @Published var bestSellers = demoProducts.filter { $0.rating >= 4.6 }
    @Published var recommendedProducts: [Product] = []
    @Published var cartItems: [CartItem] = []
    @Published var notifications = demoNotifications
    @Published var addresses: [Address] = []
    @Published var orders: [OrderItem] = []
    @Published var favouriteProducts: [Product] = []
    @Published var selectedAddressId: String?
    @Published var checkoutSubtotal: Double?
    @Published var checkoutShipping: Double?
    @Published var checkoutDiscount: Double?
    @Published var checkoutTotal: Double?

    @Published var homeLoading = false
    @Published var categoriesLoading = false
    @Published var cartLoading = false
    @Published var profileLoading = false

    private let api = FrescoAPI.shared
    private let tokenKey = "fresco_token"
    private let selectedAddressKey = "fresco_selected_address"
    private var homeLoaded = false
    private var categoriesLoaded = false
    private var cartLoaded = false
    private var profileLoaded = false
    private var categoryChildrenCache: [String: [CategoryItem]] = [:]
    private var categoryProductsCache: [String: [Product]] = [:]

    var subtotal: Double { checkoutSubtotal ?? cartItems.reduce(0) { $0 + $1.lineTotal } }
    var shipping: Double { checkoutShipping ?? (cartItems.isEmpty ? 0 : 6.99) }
    var discount: Double { checkoutDiscount ?? (subtotal >= 60 ? subtotal * 0.1 : 0) }
    var total: Double { checkoutTotal ?? max(0, subtotal + shipping - discount) }
    var unreadNotifications: Int { notifications.filter { !$0.isRead }.count }

    func bootstrap() {
        let token = UserDefaults.standard.string(forKey: tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedAddressId = UserDefaults.standard.string(forKey: selectedAddressKey)
        isAuthenticated = token?.isEmpty == false
        api.setToken(isAuthenticated ? token : nil)
        isReady = true
        Task {
            await loadHome(force: true)
            if isAuthenticated {
                await loadProfile()
                await loadCart()
            }
        }
    }

    func login(email: String, password: String) async -> Bool {
        await runAuthTask {
            let remote = try await api.login(email: email, password: password)
            try finishAuth(remote: remote, fallback: AppUser(name: email.components(separatedBy: "@").first ?? "User", email: email, phone: ""))
        }
    }

    func register(name: String, email: String, phone: String, password: String) async -> Bool {
        await runAuthTask {
            let remote = try await api.register(name: name, email: email, phone: phone, password: password)
            try finishAuth(remote: remote, fallback: AppUser(name: name, email: email, phone: phone))
        }
    }

    func verifyEmail(email: String, otp: String) async -> Bool {
        await runAuthTask {
            try await api.verifyEmail(email: email, otp: otp)
        }
    }

    func forgotPassword(email: String) async -> Bool {
        await runAuthTask {
            try await api.forgotPassword(email: email)
        }
    }

    func resetPassword(email: String, otp: String, password: String) async -> Bool {
        await runAuthTask {
            try await api.resetPassword(email: email, otp: otp, password: password)
        }
    }

    func logout() {
        Task {
            await api.logout()
            UserDefaults.standard.removeObject(forKey: tokenKey)
            api.setToken(nil)
            isAuthenticated = false
            user = .guest
            cartItems = []
            resetLazyFlags()
        }
    }

    func loadHome(force: Bool = false) async {
        if homeLoading || (homeLoaded && !force) { return }
        homeLoading = true
        defer {
            homeLoading = false
            homeLoaded = true
        }
        do {
            let snapshot = try await api.home()
            if !snapshot.banners.isEmpty { banners = snapshot.banners }
            if !snapshot.categories.isEmpty { categories = snapshot.categories }
            if !snapshot.featuredProducts.isEmpty { featuredProducts = snapshot.featuredProducts }
            if !snapshot.bestSellers.isEmpty { bestSellers = snapshot.bestSellers }
            recommendedProducts = snapshot.recommendedProducts
            if products == demoProducts {
                products = Array(SetPreservingOrder(snapshot.featuredProducts + snapshot.bestSellers + snapshot.recommendedProducts))
                if products.isEmpty { products = demoProducts }
            }
        } catch {
            remember(error)
        }
    }

    func loadCategories(force: Bool = false) async {
        if categoriesLoading || (categoriesLoaded && !force) { return }
        categoriesLoading = true
        defer {
            categoriesLoading = false
            categoriesLoaded = true
        }
        do {
            let remote = try await api.categories()
            if !remote.isEmpty { categories = remote }
            if force {
                categoryChildrenCache.removeAll()
                categoryProductsCache.removeAll()
            }
        } catch {
            remember(error)
        }
    }

    func loadCategoryChildren(_ category: CategoryItem) async -> [CategoryItem] {
        if let cached = categoryChildrenCache[category.id] {
            return cached
        }
        do {
            let remote = try await api.categoryChildren(categoryId: category.id)
            categoryChildrenCache[category.id] = remote
            return remote
        } catch {
            remember(error)
            return []
        }
    }

    func loadProducts(query: String? = nil, featuredOnly: Bool = false) async -> [Product] {
        do {
            let remote = try await api.products(query: query, featuredOnly: featuredOnly)
            if !remote.isEmpty {
                if query?.isEmpty ?? true { products = remote }
                return remote
            }
        } catch {
            remember(error)
        }
        let q = query?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let base = featuredOnly ? featuredProducts : products
        return q.isEmpty ? base : base.filter { $0.name.lowercased().contains(q) || $0.category.lowercased().contains(q) }
    }

    func loadProducts(category: CategoryItem) async -> [Product] {
        if let cached = categoryProductsCache[category.id] {
            return cached
        }
        do {
            let remote = try await api.products(categoryId: category.id)
            if !remote.isEmpty {
                categoryProductsCache[category.id] = remote
                products = Array(SetPreservingOrder(products + remote))
                return remote
            }
        } catch {
            remember(error)
        }
        let fallback = products.filter { $0.category.localizedCaseInsensitiveContains(category.name) }
        categoryProductsCache[category.id] = fallback
        return fallback
    }

    func loadDetail(for product: Product) async -> Product {
        do {
            if let remote = try await api.productDetail(product.slug.isEmpty ? product.id : product.slug) {
                return remote
            }
        } catch {
            remember(error)
        }
        return product
    }

    func loadCart(force: Bool = false) async {
        guard isAuthenticated else { return }
        if cartLoading || (cartLoaded && !force) { return }
        cartLoading = true
        defer {
            cartLoading = false
            cartLoaded = true
        }
        do {
            applyCartSnapshot(try await api.cart())
        } catch {
            remember(error)
        }
    }

    func addToCart(_ product: Product, quantity: Int = 1) async -> Bool {
        guard isAuthenticated else {
            if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
                cartItems[index].quantity += quantity
            } else {
                cartItems.append(CartItem(id: UUID().uuidString, product: product, quantity: quantity))
            }
            clearCheckoutTotals()
            return true
        }
        do {
            let snapshot = try await api.addToCart(productId: product.id, quantity: quantity)
            if !snapshot.items.isEmpty {
                applyCartSnapshot(snapshot)
            }
            await loadCart(force: true)
            return true
        } catch {
            remember(error)
            return false
        }
    }

    func updateCartItem(_ item: CartItem, quantity: Int) {
        guard quantity > 0 else {
            removeCartItem(item)
            return
        }
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            cartItems[index].quantity = quantity
        }
        clearCheckoutTotals()
        guard isAuthenticated else { return }
        Task {
            do {
                try await api.updateCartItem(cartId: item.id, quantity: quantity)
                await loadCart(force: true)
            } catch {
                remember(error)
            }
        }
    }

    func removeCartItem(_ item: CartItem) {
        cartItems.removeAll { $0.id == item.id }
        clearCheckoutTotals()
        guard isAuthenticated else { return }
        Task {
            do {
                try await api.deleteCartItem(cartId: item.id)
                await loadCart(force: true)
            } catch {
                remember(error)
            }
        }
    }

    func clearCart() {
        let items = cartItems
        cartItems.removeAll()
        clearCheckoutTotals()
        guard isAuthenticated else { return }
        Task {
            for item in items {
                do {
                    try await api.deleteCartItem(cartId: item.id)
                } catch {
                    remember(error)
                }
            }
        }
    }

    func toggleFavourite(_ product: Product) {
        func toggle(_ values: inout [Product]) {
            if let index = values.firstIndex(where: { $0.id == product.id }) {
                values[index].isFavourite.toggle()
            }
        }
        toggle(&products)
        toggle(&featuredProducts)
        toggle(&bestSellers)
        toggle(&recommendedProducts)
    }

    func loadProfile(force: Bool = false) async {
        guard isAuthenticated else { return }
        if profileLoading || (profileLoaded && !force) { return }
        profileLoading = true
        defer {
            profileLoading = false
            profileLoaded = true
        }
        do {
            if let remote = try await api.profile() {
                user = remote
            }
            notifications = try await api.notifications()
            addresses = try await api.addresses()
            ensureSelectedAddress()
            orders = try await api.orders()
            favouriteProducts = try await api.favourites()
            applyFavouriteFlags(favouriteProducts)
        } catch {
            remember(error)
        }
    }

    func updateProfile(name: String, email: String, phone: String) async -> Bool {
        let previous = user
        user = AppUser(name: name, email: email, phone: phone, avatarUrl: user.avatarUrl, points: user.points)
        guard isAuthenticated else { return true }
        do {
            if let updated = try await api.updateProfile(name: name, email: email, phone: phone) {
                user = updated
            }
            return true
        } catch {
            user = previous
            remember(error)
            return false
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        await runAuthTask {
            try await api.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        }
    }

    func submitContactUs(subject: String, name: String, email: String, reason: String, message: String) async -> Bool {
        await runAuthTask {
            try await api.submitContactUs(subject: subject, name: name, email: email, reason: reason, message: message)
        }
    }

    func loadPage(slug: String) async -> CmsPage? {
        do {
            return try await api.loadPage(slug: slug)
        } catch {
            remember(error)
            return nil
        }
    }

    func requestAccountDelete(reason: String) async -> Bool {
        await runAuthTask {
            try await api.requestAccountDelete(reason: reason)
        }
    }

    func deleteAccountNow() async -> Bool {
        await runAuthTask {
            try await api.deleteAccount()
        }
    }

    func cancelOrder(orderId: String, reason: String) async -> Bool {
        let ok = await runAuthTask {
            try await api.cancelOrder(orderId: orderId, reason: reason)
        }
        if ok {
            await loadProfile(force: true)
        }
        return ok
    }

    func preferredCheckoutAddress() -> Address? {
        if let selectedAddressId, let selected = addresses.first(where: { $0.id == selectedAddressId }) {
            return selected
        }
        return addresses.first(where: \.isDefault) ?? addresses.first
    }

    func saveSelectedAddress(_ address: Address) {
        selectedAddressId = address.id
        UserDefaults.standard.set(address.id, forKey: selectedAddressKey)
    }

    func upsertAddress(_ address: Address) async -> Bool {
        guard isAuthenticated else {
            errorMessage = "Please login before saving an address."
            return false
        }
        let isNew = !addresses.contains(where: { $0.id == address.id })
        do {
            let saved = isNew ? try await api.createAddress(address) : try await api.updateAddress(address)
            await loadProfile(force: true)
            if let saved {
                saveSelectedAddress(saved)
            } else if let refreshed = preferredCheckoutAddress() {
                saveSelectedAddress(refreshed)
            }
            return true
        } catch {
            remember(error)
            return false
        }
    }

    func deleteAddress(_ id: String) async -> Bool {
        guard isAuthenticated else { return false }
        let ok = await runAuthTask {
            try await api.deleteAddress(id)
        }
        if ok {
            await loadProfile(force: true)
            if selectedAddressId == id {
                if let fallback = preferredCheckoutAddress() {
                    saveSelectedAddress(fallback)
                } else {
                    selectedAddressId = nil
                    UserDefaults.standard.removeObject(forKey: selectedAddressKey)
                }
            }
        }
        return ok
    }

    func setDefaultAddress(_ id: String) async -> Bool {
        guard isAuthenticated else { return false }
        let ok = await runAuthTask {
            try await api.makeDefaultAddress(id)
        }
        if ok {
            await loadProfile(force: true)
            if let selected = addresses.first(where: { $0.id == id }) {
                saveSelectedAddress(selected)
            }
        }
        return ok
    }

    func loadCountries() async -> [LocationOption] {
        do {
            return try await api.countries()
        } catch {
            remember(error)
            return []
        }
    }

    func loadStates(countryId: String) async -> [LocationOption] {
        do {
            return try await api.states(countryId: countryId)
        } catch {
            remember(error)
            return []
        }
    }

    func applyCoupon(_ code: String) async -> Bool {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return await runAuthTask {
            try await api.applyCoupon(code: code)
        }
    }

    func removeCoupon() async -> Bool {
        await runAuthTask {
            try await api.removeCoupon()
        }
    }

    func refreshCheckoutSummary(addressId: String, couponCode: String? = nil) async -> Bool {
        guard !cartItems.isEmpty else { return false }
        guard isAuthenticated else { return true }
        do {
            let snapshot = try await api.checkoutSummary(addressId: addressId, couponCode: couponCode)
            applyCartSnapshot(snapshot)
            return true
        } catch {
            remember(error)
            return false
        }
    }

    func placeOrder(addressId: String, paymentMethod: String, couponCode: String? = nil) async -> Bool {
        guard !cartItems.isEmpty else { return false }
        guard isAuthenticated else {
            errorMessage = "Please login before placing your order."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await api.placeOrder(addressId: addressId, paymentMethod: paymentMethod, couponCode: couponCode)
            await loadCart(force: true)
            await loadProfile(force: true)
            clearCheckoutTotals()
            return true
        } catch {
            remember(error)
            return false
        }
    }

    private func runAuthTask(_ task: () async throws -> Void) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await task()
            return true
        } catch {
            remember(error)
            return false
        }
    }

    private func finishAuth(remote: [String: Any], fallback: AppUser) throws {
        let token = clean(remote["token"] ?? remote["access_token"] ?? remote["accessToken"])
        guard !token.isEmpty else { throw APIError.requestFailed("Login token was missing from the response.") }
        UserDefaults.standard.set(token, forKey: tokenKey)
        api.setToken(token)
        if let userMap = remote["user"] as? [String: Any] {
            user = AppUser(json: userMap)
        } else {
            user = fallback
        }
        isAuthenticated = true
        resetLazyFlags()
    }

    private func resetLazyFlags() {
        homeLoaded = false
        categoriesLoaded = false
        cartLoaded = false
        profileLoaded = false
    }

    private func applyCartSnapshot(_ snapshot: CartSnapshot) {
        cartItems = enrichedCartItems(snapshot.items)
        checkoutSubtotal = snapshot.subtotal
        checkoutShipping = snapshot.shipping
        checkoutDiscount = snapshot.discount
        checkoutTotal = snapshot.total
    }

    private func enrichedCartItems(_ items: [CartItem]) -> [CartItem] {
        items.map { item in
            guard let known = knownProduct(matching: item.product) else { return item }
            var product = item.product
            if product.name.isEmpty || product.name == "Product" { product.name = known.name }
            if product.slug.isEmpty { product.slug = known.slug }
            if product.imageUrl.isEmpty { product.imageUrl = known.imageUrl }
            if product.category.isEmpty || product.category == "Fresh grocery" { product.category = known.category }
            if product.price == 0 { product.price = known.price }
            if product.salePrice == 0 { product.salePrice = known.salePrice }
            if product.rating == 4.5 { product.rating = known.rating }
            if product.reviewCount == 0 { product.reviewCount = known.reviewCount }
            if product.description.isEmpty { product.description = known.description }
            if product.badges.isEmpty { product.badges = known.badges }
            product.isFeatured = product.isFeatured || known.isFeatured
            product.isFavourite = product.isFavourite || known.isFavourite
            return CartItem(id: item.id, product: product, quantity: item.quantity)
        }
    }

    private func knownProduct(matching product: Product) -> Product? {
        let allProducts = products
            + featuredProducts
            + bestSellers
            + recommendedProducts
            + categoryProductsCache.values.flatMap { $0 }
        return allProducts.first { candidate in
            candidate.id == product.id
                || (!product.slug.isEmpty && candidate.slug == product.slug)
                || (!product.name.isEmpty && candidate.name.caseInsensitiveCompare(product.name) == .orderedSame)
        }
    }

    private func clearCheckoutTotals() {
        checkoutSubtotal = nil
        checkoutShipping = nil
        checkoutDiscount = nil
        checkoutTotal = nil
    }

    private func ensureSelectedAddress() {
        if let selectedAddressId, addresses.contains(where: { $0.id == selectedAddressId }) {
            return
        }
        if let fallback = addresses.first(where: \.isDefault) ?? addresses.first {
            saveSelectedAddress(fallback)
        } else {
            selectedAddressId = nil
            UserDefaults.standard.removeObject(forKey: selectedAddressKey)
        }
    }

    private func applyFavouriteFlags(_ favourites: [Product]) {
        let ids = Set(favourites.map(\.id))
        func update(_ product: Product) -> Product {
            var copy = product
            if ids.contains(product.id) { copy.isFavourite = true }
            return copy
        }
        products = products.map(update)
        featuredProducts = featuredProducts.map(update)
        bestSellers = bestSellers.map(update)
        recommendedProducts = recommendedProducts.map(update)
    }

    private func remember(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

struct SetPreservingOrder<Element: Identifiable & Equatable>: Sequence where Element.ID: Hashable {
    private let values: [Element]

    init(_ values: [Element]) {
        var ids = Set<Element.ID>()
        self.values = values.filter { ids.insert($0.id).inserted }
    }

    func makeIterator() -> IndexingIterator<[Element]> {
        values.makeIterator()
    }
}
