import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var selectedBanner = 0
    private let bannerTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !state.banners.isEmpty {
                        TabView(selection: $selectedBanner) {
                            ForEach(Array(state.banners.enumerated()), id: \.element.id) { index, banner in
                                HomeBannerCard(banner: banner)
                                    .tag(index)
                                    .padding(.trailing, index == state.banners.count - 1 ? 0 : 14)
                            }
                        }
                        .frame(height: 260)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .padding(.top, 20)

                        HomePageDots(count: state.banners.count, selected: selectedBanner)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                    }

                    sectionHeader("Categories", subtitle: "Fresh departments for every basket")
                        .padding(.top, state.banners.isEmpty ? 20 : 20)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(state.categories) { category in
                                NavigationLink(value: Route.category(category)) {
                                    HomeCategoryCard(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 110)
                    .padding(.top, 12)

                    productsRow(title: "Featured", subtitle: "Curated picks for the week", products: featuredProducts)
                        .padding(.top, 18)

                    if !state.recommendedProducts.isEmpty {
                        productsRow(title: "Recommended", subtitle: "More picks from Fresco", products: state.recommendedProducts)
                            .padding(.top, 22)
                    }

                    if !state.bestSellers.isEmpty {
                        SectionTitle(title: "Best sellers", subtitle: "Highly rated grocery essentials")
                            .padding(.top, 22)
                        VStack(spacing: 12) {
                            ForEach(Array(state.bestSellers.prefix(4))) { product in
                                NavigationLink(value: Route.product(product)) {
                                    HomeBestSellerCard(product: product) {
                                        Task { _ = await state.addToCart(product) }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 12)
                    }

                    HomeHighlightCard()
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(FrescoColors.background)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Image("fresco-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("FrescoCanada")
                                .font(.system(size: 30, weight: .black))
                                .foregroundStyle(.white)
                            Text("Freshness guaranteed")
                                .font(.system(size: 18, weight: .medium))
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
            .onReceive(bannerTimer) { _ in
                guard state.banners.count > 1 else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    selectedBanner = selectedBanner + 1 >= state.banners.count ? 0 : selectedBanner + 1
                }
            }
            .refreshable { await state.loadHome(force: true) }
        }
    }

    private var featuredProducts: [Product] {
        let values = state.featuredProducts.isEmpty ? state.products : state.featuredProducts
        return values.isEmpty ? state.bestSellers : values
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        SectionTitle(title: title, subtitle: subtitle)
    }

    private func productsRow(title: String, subtitle: String, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(title: title, subtitle: subtitle)
                Spacer()
                NavigationLink("See all", value: Route.products(title, products))
                    .font(.subheadline.weight(.heavy))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(products) { product in
                        NavigationLink(value: Route.product(product)) {
                            HomeProductCard(product: product) {
                                Task { _ = await state.addToCart(product) }
                            } favouriteAction: {
                                state.toggleFavourite(product)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 350)
        }
    }
}

struct HomeBannerCard: View {
    let banner: BannerItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(FrescoColors.primary)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: 148, y: -92)

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: -156, y: 106)

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Fresh grocery essentials")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())

                    Text(banner.title)
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text(banner.subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .lineLimit(3)

                    Text(banner.cta)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(FrescoColors.primaryDark)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(.white)
                        .clipShape(Capsule())
                }

                if !banner.imageUrl.isEmpty {
                    RemoteProductImage(url: banner.imageUrl)
                        .frame(width: 115, height: 115)
                } else {
                    Image("fresco-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

struct HomePageDots: View {
    let count: Int
    let selected: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == selected ? FrescoColors.primary : Color(red: 0.839, green: 0.906, blue: 0.980))
                    .frame(width: index == selected ? 20 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: selected)
            }
        }
    }
}

struct HomeCategoryCard: View {
    let category: CategoryItem

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 52, height: 52)
                if let url = URL(string: category.image), !category.image.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit().clipShape(Circle())
                        case .empty:
                            ProgressView().tint(FrescoColors.primary)
                        default:
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(FrescoColors.primary)
                        }
                    }
                    .frame(width: 52, height: 52)
                } else {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FrescoColors.primary)
                }
            }

            Text(category.name)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(FrescoColors.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .top)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 112, height: 110)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
    }
}

struct HomeProductCard: View {
    let product: Product
    let addAction: () -> Void
    let favouriteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RemoteProductImage(url: product.imageUrl)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button(action: favouriteAction) {
                    Image(systemName: product.isFavourite ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(product.isFavourite ? .red : FrescoColors.primaryDark)
                        .frame(width: 36, height: 36)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FrescoColors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(minHeight: 36, alignment: .topLeading)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", product.rating == 0 ? 4.5 : product.rating))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(FrescoColors.muted)
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Text(product.displayPrice)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.459, green: 0.459, blue: 0.459))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color(red: 0.937, green: 0.965, blue: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Spacer(minLength: 0)

                    Button(action: addAction) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(FrescoColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            .padding(12)
            .frame(height: 140)
        }
        .frame(width: 180, height: 350)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(FrescoColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }
}

struct HomeBestSellerCard: View {
    let product: Product
    let addAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RemoteProductImage(url: product.imageUrl)
                .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 7) {
                Text(product.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(FrescoColors.ink)
                    .lineLimit(2)
                Text(product.category.isEmpty ? "Fresh grocery" : product.category)
                    .font(.subheadline)
                    .foregroundStyle(FrescoColors.muted)
                    .lineLimit(1)
                Text(product.displayPrice)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(FrescoColors.primaryDark)
            }

            Spacer(minLength: 0)

            Button(action: addAction) {
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(FrescoColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FrescoColors.border, lineWidth: 1)
        )
    }
}

struct HomeHighlightCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Freshness guaranteed")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text("Quality groceries selected for every basket.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
            }
            Spacer()
            Image("fresco-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
        }
        .padding(18)
        .background(FrescoColors.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
