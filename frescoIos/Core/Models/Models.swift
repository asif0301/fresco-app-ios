import SwiftUI

struct AppUser: Hashable {
    var name: String
    var email: String
    var phone: String
    var avatarUrl: String
    var points: Int

    static let guest = AppUser(name: "", email: "", phone: "", avatarUrl: "", points: 0)

    init(name: String, email: String, phone: String, avatarUrl: String = "", points: Int = 0) {
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarUrl = avatarUrl
        self.points = points
    }

    init(json: [String: Any]) {
        name = clean(json["name"] ?? json["full_name"] ?? json["first_name"], fallback: "User")
        email = clean(json["email"])
        phone = clean(json["phone"] ?? json["mobile"])
        avatarUrl = clean(json["avatar"] ?? json["avatar_url"] ?? json["image"])
        points = intValue(json["points"]) ?? intValue(json["loyalty_points"]) ?? 0
    }
}

struct BannerItem: Identifiable, Hashable {
    var id = UUID().uuidString
    var title: String
    var subtitle: String
    var imageUrl: String
    var cta: String
    var color: Color

    init(title: String, subtitle: String, imageUrl: String = "", cta: String = "Shop now", color: Color = FrescoColors.primary) {
        self.title = title
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.cta = cta
        self.color = color
    }

    init(json: [String: Any]) {
        title = clean(json["title"] ?? json["name"], fallback: "Fresh picks")
        subtitle = clean(json["subtitle"] ?? json["description"], fallback: "Curated grocery deals for the Fresco app.")
        imageUrl = clean(json["image"] ?? json["image_url"])
        cta = clean(json["cta"] ?? json["button_text"], fallback: "Shop now")
        color = colorValue(json["bg_color"] ?? json["background_color"]) ?? FrescoColors.primary
    }
}

struct CategoryItem: Identifiable, Hashable {
    var id: String
    var name: String
    var slug: String
    var image: String

    init(id: String, name: String, slug: String, image: String = "") {
        self.id = id
        self.name = name
        self.slug = slug
        self.image = image
    }

    init(json: [String: Any]) {
        id = clean(json["id"] ?? json["slug"] ?? json["name"])
        name = clean(json["title"] ?? json["name"] ?? json["category_name"], fallback: "Category")
        slug = clean(json["slug"] ?? json["title"] ?? json["name"])
        image = clean(json["image"] ?? json["image_url"] ?? json["icon"])
    }
}

struct Product: Identifiable, Hashable {
    var id: String
    var name: String
    var slug: String
    var price: Double
    var salePrice: Double
    var rating: Double
    var reviewCount: Int
    var imageUrl: String
    var category: String
    var description: String
    var badges: [String]
    var isFeatured: Bool
    var isFavourite: Bool

    init(
        id: String,
        name: String,
        slug: String,
        price: Double,
        salePrice: Double? = nil,
        rating: Double = 4.5,
        reviewCount: Int = 0,
        imageUrl: String = "",
        category: String = "Fresh grocery",
        description: String = "",
        badges: [String] = [],
        isFeatured: Bool = false,
        isFavourite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.price = price
        self.salePrice = salePrice ?? price
        self.rating = rating
        self.reviewCount = reviewCount
        self.imageUrl = imageUrl
        self.category = category
        self.description = description
        self.badges = badges
        self.isFeatured = isFeatured
        self.isFavourite = isFavourite
    }

    init(json: [String: Any]) {
        let nestedCategory = mapValue(json["category"])
        let store = mapValue(json["store"])
        let images = json["images"] as? [Any]
        let firstImage = images?.first
        let basePrice = doubleValue(json["price"]) ?? doubleValue(json["regular_price"]) ?? 0

        id = clean(json["id"] ?? json["product_id"] ?? json["slug"] ?? json["name"])
        name = clean(json["name"] ?? json["title"] ?? json["product_name"], fallback: "Product")
        slug = clean(json["slug"] ?? json["name"] ?? json["title"])
        price = basePrice
        salePrice = doubleValue(json["sale_price"]) ?? basePrice
        rating = doubleValue(json["rating"]) ?? 4.5
        reviewCount = intValue(json["reviews_count"]) ?? intValue(json["review_count"]) ?? 0
        imageUrl = clean(json["image"] ?? json["image_url"] ?? json["thumbnail"] ?? firstImage)
        category = clean(json["category_name"] ?? nestedCategory?["name"] ?? nestedCategory?["title"] ?? store?["name"] ?? json["category"], fallback: "Fresh grocery")
        description = clean(json["description"] ?? json["short_description"])
        badges = json["badge"].map { [clean($0)] } ?? []
        isFeatured = boolValue(json["featured"] ?? json["is_featured"])
        isFavourite = boolValue(json["is_favourite"])
    }

    var displayPrice: String { money(salePrice) }
    var regularPrice: String { money(price) }
}

struct CartItem: Identifiable, Hashable {
    var id: String
    var product: Product
    var quantity: Int
    var lineTotal: Double { product.salePrice * Double(quantity) }
}

struct Address: Identifiable, Hashable {
    var id: String
    var name: String
    var phone: String
    var line1: String
    var city: String
    var state: String
    var postalCode: String
    var country: String
    var stateId: String?
    var countryId: String?
    var isDefault: Bool

    var oneLine: String {
        [line1, city, state, postalCode, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    init(id: String, name: String, phone: String, line1: String, city: String, state: String, postalCode: String, country: String, stateId: String? = nil, countryId: String? = nil, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.phone = phone
        self.line1 = line1
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.stateId = stateId
        self.countryId = countryId
        self.isDefault = isDefault
    }

    init(json: [String: Any]) {
        let stateMap = mapValue(json["state"])
        let countryMap = mapValue(json["country"])
        id = clean(json["id"] ?? json["address_id"] ?? json["sh_id"] ?? json["uuid"])
        name = clean(json["full_name"] ?? json["name"], fallback: "Address")
        phone = clean(json["phone"] ?? json["mobile"])
        line1 = clean(json["street"] ?? json["line1"] ?? json["address_line_1"])
        city = clean(json["city"])
        state = clean(json["state_name"] ?? json["province"] ?? stateMap?["name"] ?? stateMap?["state_name"] ?? stateMap?["title"] ?? json["state"])
        postalCode = clean(json["zip_code"] ?? json["postal_code"] ?? json["post_code"] ?? json["zip"])
        country = clean(json["country_name"] ?? countryMap?["name"] ?? countryMap?["title"] ?? json["country"])
        stateId = optionalClean(json["state_id"] ?? stateMap?["id"] ?? stateMap?["state_id"])
        countryId = optionalClean(json["country_id"] ?? countryMap?["id"] ?? countryMap?["country_id"])
        isDefault = boolValue(json["is_default"] ?? json["default"])
    }
}

struct LocationOption: Identifiable, Hashable {
    var id: String
    var label: String

    init(json: [String: Any], fallback: String) {
        id = clean(json["id"] ?? json["country_id"] ?? json["state_id"] ?? json["code"])
        label = clean(json["title"] ?? json["name"] ?? json["country_name"] ?? json["state_name"], fallback: fallback)
    }
}

struct NotificationItem: Identifiable, Hashable {
    var id: String
    var title: String
    var message: String
    var timeLabel: String
    var isRead: Bool

    init(id: String, title: String, message: String, timeLabel: String, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.timeLabel = timeLabel
        self.isRead = isRead
    }

    init(json: [String: Any]) {
        id = clean(json["id"] ?? json["notification_id"])
        title = clean(json["title"] ?? json["name"], fallback: "Notification")
        message = clean(json["message"] ?? json["description"])
        timeLabel = clean(json["created_at"] ?? json["time"], fallback: "Just now")
        isRead = boolValue(json["is_read"] ?? json["read"])
    }
}

struct OrderItem: Identifiable, Hashable {
    var id: String
    var reference: String
    var status: String
    var paymentMethod: String
    var total: Double
    var dateLabel: String
    var itemCount: Int
}

struct CmsPage: Identifiable, Hashable {
    var id: String { slug }
    var slug: String
    var title: String
    var body: String

    init(slug: String, title: String, body: String) {
        self.slug = slug
        self.title = title
        self.body = body
    }

    init(json: [String: Any]) {
        slug = clean(json["slug"] ?? json["page_slug"])
        title = clean(json["title"] ?? json["name"], fallback: "Page")
        body = clean(json["body"] ?? json["content"])
    }

    var plainBody: String {
        body.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HomeSnapshot {
    var banners: [BannerItem]
    var categories: [CategoryItem]
    var featuredProducts: [Product]
    var bestSellers: [Product]
    var recommendedProducts: [Product]
}

struct CartSnapshot {
    var items: [CartItem]
    var subtotal: Double
    var shipping: Double
    var discount: Double
    var total: Double
}

enum FrescoColors {
    static let primary = Color(red: 0.231, green: 0.514, blue: 0.847)
    static let primaryDark = Color(red: 0.122, green: 0.373, blue: 0.659)
    static let background = Color(red: 0.957, green: 0.973, blue: 0.992)
    static let border = Color(red: 0.863, green: 0.910, blue: 0.969)
    static let ink = Color(red: 0.071, green: 0.071, blue: 0.071)
    static let muted = Color(red: 0.392, green: 0.455, blue: 0.545)
}

let demoBanners = [
    BannerItem(title: "Fresh groceries delivered", subtitle: "Stock the kitchen with produce, pantry staples, and weekly Fresco picks.", imageUrl: "", cta: "Shop featured", color: FrescoColors.primary),
    BannerItem(title: "Weekly best sellers", subtitle: "Customer favorites for fast baskets and family meals.", imageUrl: "", cta: "Browse deals", color: Color(red: 0.078, green: 0.620, blue: 0.498))
]

let demoCategories = [
    CategoryItem(id: "fruit", name: "Fruits", slug: "fruits"),
    CategoryItem(id: "vegetables", name: "Vegetables", slug: "vegetables"),
    CategoryItem(id: "dairy", name: "Dairy", slug: "dairy"),
    CategoryItem(id: "bakery", name: "Bakery", slug: "bakery"),
    CategoryItem(id: "pantry", name: "Pantry", slug: "pantry")
]

let demoProducts = [
    Product(id: "1", name: "Organic Banana Bunch", slug: "organic-banana-bunch", price: 3.99, salePrice: 2.99, rating: 4.8, reviewCount: 124, category: "Fruits", description: "Sweet ripe bananas for smoothies, lunches, and baking.", badges: ["Fresh"], isFeatured: true),
    Product(id: "2", name: "Farm Fresh Tomatoes", slug: "farm-fresh-tomatoes", price: 5.49, salePrice: 4.25, rating: 4.7, reviewCount: 98, category: "Vegetables", description: "Juicy tomatoes selected for salads, sauces, and sandwiches.", badges: ["Local"], isFeatured: true),
    Product(id: "3", name: "Whole Milk 2L", slug: "whole-milk-2l", price: 4.99, rating: 4.6, reviewCount: 73, category: "Dairy", description: "Creamy everyday milk from trusted dairy suppliers.", badges: ["Best seller"], isFeatured: true),
    Product(id: "4", name: "Sourdough Bread", slug: "sourdough-bread", price: 6.25, rating: 4.9, reviewCount: 156, category: "Bakery", description: "Crusty sourdough loaf baked fresh for Fresco customers.", badges: ["Bakery"]),
    Product(id: "5", name: "Extra Virgin Olive Oil", slug: "extra-virgin-olive-oil", price: 13.99, salePrice: 11.99, rating: 4.5, reviewCount: 42, category: "Pantry", description: "Balanced olive oil for dressings, cooking, and finishing.", badges: ["Deal"])
]

let demoNotifications = [
    NotificationItem(id: "n1", title: "Order update", message: "Your latest Fresco order is being prepared.", timeLabel: "Just now"),
    NotificationItem(id: "n2", title: "Fresh deal", message: "New produce offers are available this week.", timeLabel: "Today", isRead: true)
]
