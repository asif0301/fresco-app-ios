import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL."
        case .requestFailed(let message):
            message
        }
    }
}

final class FrescoAPI {
    static let shared = FrescoAPI()

    private let root = "https://fresco.skynetsolutionz.space"
    private var token: String?

    func setToken(_ token: String?) {
        self.token = token?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func login(email: String, password: String) async throws -> [String: Any] {
        try await mapRequest(
            path: "/api/v1/mobile/auth/login",
            method: "POST",
            body: ["email": email, "password": password, "app_flag": "buyer"],
            authorized: false
        )
    }

    func register(name: String, email: String, phone: String, password: String) async throws -> [String: Any] {
        try await mapRequest(
            path: "/api/v1/mobile/auth/register",
            method: "POST",
            body: ["name": name, "email": email, "phone": phone, "password": password, "password_confirmation": password, "app_flag": "buyer"],
            authorized: false
        )
    }

    func verifyEmail(email: String, otp: String) async throws {
        _ = try await request(
            path: "/api/v1/mobile/auth/verify-email",
            method: "POST",
            body: ["email": email, "otp": otp],
            authorized: false
        )
    }

    func forgotPassword(email: String) async throws {
        _ = try await request(
            path: "/api/v1/mobile/auth/forgot-password",
            method: "POST",
            body: ["email": email],
            authorized: false
        )
    }

    func resetPassword(email: String, otp: String, password: String) async throws {
        _ = try await request(
            path: "/api/v1/mobile/auth/reset-password",
            method: "POST",
            body: ["email": email, "otp": otp, "password": password, "password_confirmation": password],
            authorized: false
        )
    }

    func home() async throws -> HomeSnapshot {
        let value = try await request(path: "/api/v1/mobile/home?limit=10", method: "GET", authorized: false)
        let map = unwrapMap(value)
        let banners = nestedList(map, "banners").map(BannerItem.init(json:))
        let categories = nestedList(map, "categories").map(CategoryItem.init(json:))
        let featured = (nestedList(map, "featured_products") + nestedList(map, "featuredProducts")).map(Product.init(json:))
        let best = nestedList(map, "best_sellers").map(Product.init(json:))
        let recommended = (nestedList(map, "recommended_products") + nestedList(map, "recommendedProducts")).map(Product.init(json:))
        return HomeSnapshot(banners: banners, categories: categories, featuredProducts: featured, bestSellers: best, recommendedProducts: recommended)
    }

    func categories() async throws -> [CategoryItem] {
        try await listRequest(path: "/api/v1/mobile/categories", authorized: false).map(CategoryItem.init(json:))
    }

    func products(query: String? = nil, featuredOnly: Bool = false) async throws -> [Product] {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let path: String
        if !trimmed.isEmpty {
            path = "/api/v1/mobile/products/search?q=\(trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed)&page=1&limit=20"
        } else if featuredOnly {
            path = "/api/v1/mobile/home/products?section=featured&page=1&limit=20"
        } else {
            path = "/api/v1/mobile/products?page=1&limit=20&sort=latest"
        }
        return try await listRequest(path: path, authorized: false).map(Product.init(json:))
    }

    func products(categoryId: String) async throws -> [Product] {
        try await listRequest(path: "/api/v1/mobile/categories/\(categoryId)/products?page=1&limit=20", authorized: false).map(Product.init(json:))
    }

    func productDetail(_ idOrSlug: String) async throws -> Product? {
        let escaped = idOrSlug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? idOrSlug
        let map = try await mapRequest(path: "/api/v1/mobile/products/\(escaped)", method: "GET", authorized: false)
        return map.isEmpty ? nil : Product(json: map)
    }

    func addToCart(productId: String, quantity: Int) async throws -> CartSnapshot {
        cartSnapshot(
            try await request(path: "/api/v1/mobile/cart/items", method: "POST", body: ["product_id": Int(productId) ?? productId, "quantity": quantity], authorized: true)
        )
    }

    func cart() async throws -> CartSnapshot {
        cartSnapshot(try await request(path: "/api/v1/mobile/cart", method: "GET", authorized: true))
    }

    func updateCartItem(cartId: String, quantity: Int) async throws {
        _ = try await request(path: "/api/v1/mobile/cart/items/\(cartId)", method: "PATCH", body: ["quantity": quantity], authorized: true)
    }

    func deleteCartItem(cartId: String) async throws {
        _ = try await request(path: "/api/v1/mobile/cart/items/\(cartId)", method: "DELETE", authorized: true)
    }

    func applyCoupon(code: String) async throws {
        _ = try await request(path: "/api/v1/mobile/coupons/apply", method: "POST", body: ["coupon_code": code], authorized: true)
    }

    func removeCoupon() async throws {
        _ = try await request(path: "/api/v1/mobile/coupons/remove", method: "DELETE", authorized: true)
    }

    func checkoutSummary(addressId: String, couponCode: String? = nil) async throws -> CartSnapshot {
        var body: [String: Any] = ["address_id": Int(addressId) ?? addressId]
        if let couponCode, !couponCode.isEmpty {
            body["coupon_code"] = couponCode
        }
        return cartSnapshot(try await request(path: "/api/v1/mobile/checkout/summary", method: "POST", body: body, authorized: true))
    }

    func placeOrder(addressId: String, paymentMethod: String, couponCode: String? = nil) async throws {
        var body: [String: Any] = [
            "address_id": Int(addressId) ?? addressId,
            "payment_method": paymentMethod
        ]
        if let couponCode, !couponCode.isEmpty {
            body["coupon_code"] = couponCode
        }
        _ = try await request(path: "/api/v1/mobile/orders", method: "POST", body: body, authorized: true)
    }

    func notifications() async throws -> [NotificationItem] {
        try await listRequest(path: "/api/v1/mobile/notifications", authorized: true).map(NotificationItem.init(json:))
    }

    func favourites() async throws -> [Product] {
        try await listRequest(path: "/api/v1/mobile/favourites", authorized: true).map { item in
            Product(json: mapValue(item["product"]) ?? item)
        }
    }

    func addresses() async throws -> [Address] {
        try await listRequest(path: "/api/v1/mobile/addresses", authorized: true).map(Address.init(json:))
    }

    func createAddress(_ address: Address) async throws -> Address? {
        let map = try await mapRequest(path: "/api/v1/mobile/addresses", method: "POST", body: addressBody(address), authorized: true)
        return map.isEmpty ? address : Address(json: map)
    }

    func updateAddress(_ address: Address) async throws -> Address? {
        let map = try await mapRequest(path: "/api/v1/mobile/addresses/\(address.id)", method: "PUT", body: addressBody(address), authorized: true)
        return map.isEmpty ? address : Address(json: map)
    }

    func deleteAddress(_ id: String) async throws {
        _ = try await request(path: "/api/v1/mobile/addresses/\(id)", method: "DELETE", authorized: true)
    }

    func makeDefaultAddress(_ id: String) async throws {
        _ = try await request(path: "/api/v1/mobile/addresses/\(id)/default", method: "POST", authorized: true)
    }

    func countries() async throws -> [LocationOption] {
        try await listRequest(path: "/api/v1/mobile/locations/countries", authorized: true)
            .map { LocationOption(json: $0, fallback: "Country") }
            .filter { !$0.id.isEmpty }
    }

    func states(countryId: String) async throws -> [LocationOption] {
        let encoded = countryId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? countryId
        return try await listRequest(path: "/api/v1/mobile/locations/states?country_id=\(encoded)", authorized: true)
            .map { LocationOption(json: $0, fallback: "State") }
            .filter { !$0.id.isEmpty }
    }

    func orders() async throws -> [OrderItem] {
        try await listRequest(path: "/api/v1/mobile/orders", authorized: true).map { item in
            OrderItem(
                id: clean(item["id"] ?? item["order_id"]),
                reference: clean(item["reference"] ?? item["order_number"], fallback: "Order #\(clean(item["id"]))"),
                status: clean(item["order_status"] ?? item["status"], fallback: "Pending"),
                paymentMethod: clean(item["payment_method"] ?? item["paymentMethod"], fallback: "Card"),
                total: doubleValue(item["payable_amount"] ?? item["total_amount"] ?? item["total"]) ?? 0,
                dateLabel: clean(item["date_label"] ?? item["created_at"]),
                itemCount: intValue(item["total_items"]) ?? 0
            )
        }
    }

    func profile() async throws -> AppUser? {
        let map = try await mapRequest(path: "/api/v1/mobile/profile", method: "GET", authorized: true)
        return map.isEmpty ? nil : AppUser(json: map)
    }

    func updateProfile(name: String, email: String, phone: String) async throws -> AppUser? {
        let map = try await mapRequest(
            path: "/api/v1/mobile/profile",
            method: "POST",
            body: ["name": name, "email": email, "phone": phone],
            authorized: true
        )
        if let userMap = map["user"] as? [String: Any] {
            return AppUser(json: userMap)
        }
        return map.isEmpty ? nil : AppUser(json: map)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        _ = try await request(
            path: "/api/v1/mobile/profile/password",
            method: "PUT",
            body: ["current_password": currentPassword, "password": newPassword, "password_confirmation": newPassword],
            authorized: true
        )
    }

    func submitContactUs(subject: String, name: String, email: String, reason: String, message: String) async throws {
        _ = try await request(
            path: "/api/contact-us",
            method: "POST",
            body: ["subject": subject, "name": name, "email": email, "reason": reason, "message": message],
            authorized: true
        )
    }

    func loadPage(slug: String) async throws -> CmsPage? {
        let map = try await mapRequest(path: "/api/v1/mobile/pages/\(slug)", method: "GET", authorized: false)
        return map.isEmpty ? nil : CmsPage(json: map)
    }

    func requestAccountDelete(reason: String) async throws {
        _ = try await request(path: "/api/v1/mobile/account/delete-request", method: "POST", body: ["reason": reason], authorized: true)
    }

    func deleteAccount() async throws {
        _ = try await request(path: "/api/v1/mobile/account", method: "DELETE", authorized: true)
    }

    private func addressBody(_ address: Address) -> [String: Any] {
        var body: [String: Any] = [
            "full_name": address.name,
            "phone": address.phone,
            "street": address.line1,
            "city": address.city,
            "zip_code": address.postalCode,
            "is_default": address.isDefault
        ]
        if let stateId = locationIdValue(address.stateId) {
            body["state_id"] = stateId
        }
        if let countryId = locationIdValue(address.countryId) {
            body["country_id"] = countryId
        }
        return body
    }

    private func locationIdValue(_ value: String?) -> Any? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return Int(value) ?? value
    }

    func cancelOrder(orderId: String, reason: String) async throws {
        _ = try await request(path: "/api/v1/mobile/orders/\(orderId)/cancel", method: "POST", body: ["reason": reason], authorized: true)
    }

    func logout() async {
        _ = try? await request(path: "/api/v1/mobile/auth/logout", method: "POST", authorized: true)
    }

    private func listRequest(path: String, authorized: Bool) async throws -> [[String: Any]] {
        extractList(try await request(path: path, method: "GET", authorized: authorized))
    }

    private func mapRequest(path: String, method: String, body: [String: Any]? = nil, authorized: Bool) async throws -> [String: Any] {
        unwrapMap(try await request(path: path, method: method, body: body, authorized: authorized))
    }

    @discardableResult
    private func request(path: String, method: String, body: [String: Any]? = nil, authorized: Bool = true) async throws -> Any {
        guard let url = URL(string: root + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authorized, let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let decoded = data.isEmpty ? [:] : (try JSONSerialization.jsonObject(with: data))
        if status >= 400 {
            throw APIError.requestFailed(errorMessage(decoded, fallback: statusMessage(status)))
        }
        if let map = decoded as? [String: Any], boolValue(map["status"]) == false {
            throw APIError.requestFailed(errorMessage(decoded, fallback: "Request failed."))
        }
        return decoded
    }

    private func cartSnapshot(_ value: Any) -> CartSnapshot {
        let map = unwrapMap(value)
        let items = extractList(value).map { item -> CartItem in
            let productJSON = mapValue(item["product"]) ?? item
            return CartItem(
                id: clean(item["id"] ?? item["cart_id"] ?? UUID().uuidString),
                product: Product(json: productJSON),
                quantity: intValue(item["quantity"]) ?? 1
            )
        }
        let subtotal = doubleValue(map["subtotal"]) ?? items.reduce(0) { $0 + $1.lineTotal }
        let shipping = doubleValue(map["shipping"]) ?? (items.isEmpty ? 0 : 6.99)
        let discount = doubleValue(map["discount"]) ?? 0
        let total = doubleValue(map["total"]) ?? max(0, subtotal + shipping - discount)
        return CartSnapshot(items: items, subtotal: subtotal, shipping: shipping, discount: discount, total: total)
    }

    private func unwrapMap(_ value: Any) -> [String: Any] {
        if let map = value as? [String: Any], let data = map["data"] {
            return data as? [String: Any] ?? map
        }
        return value as? [String: Any] ?? [:]
    }

    private func extractList(_ value: Any) -> [[String: Any]] {
        if let list = value as? [[String: Any]] { return list }
        let unwrapped = (value as? [String: Any])?["data"] ?? value
        if let list = unwrapped as? [[String: Any]] { return list }
        if let map = unwrapped as? [String: Any] {
            for key in ["items", "results", "payload", "records", "addresses", "countries", "states", "data"] {
                if let list = map[key] as? [[String: Any]] { return list }
            }
        }
        return []
    }

    private func nestedList(_ map: [String: Any], _ key: String) -> [[String: Any]] {
        map[key] as? [[String: Any]] ?? []
    }

    private func errorMessage(_ value: Any, fallback: String) -> String {
        guard let map = value as? [String: Any] else { return fallback }
        if let errors = map["errors"] as? [String: Any] {
            for value in errors.values {
                if let list = value as? [Any], let first = list.first {
                    return clean(first, fallback: fallback)
                }
                let text = clean(value)
                if !text.isEmpty { return text }
            }
        }
        return clean(map["message"] ?? map["error"], fallback: fallback)
    }

    private func statusMessage(_ status: Int) -> String {
        switch status {
        case 400: "Bad request."
        case 401: "You are not authorized to continue."
        case 403: "You do not have permission to perform this action."
        case 404: "Requested resource was not found."
        case 422: "Validation failed."
        case 429: "Too many requests. Please try again."
        default: "Request failed."
        }
    }
}
