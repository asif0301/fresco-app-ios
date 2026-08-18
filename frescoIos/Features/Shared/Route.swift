import SwiftUI

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
