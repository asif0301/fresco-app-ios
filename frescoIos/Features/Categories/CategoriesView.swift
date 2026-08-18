import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject private var state: FrescoAppState
    @State private var selectedCategory: CategoryItem?
    @State private var selectedMainCategoryId: String?
    @State private var selectedSubcategoryId: String?
    @State private var subcategories: [CategoryItem] = []
    @State private var categoryProducts: [Product] = []
    @State private var loadingChildren = false
    @State private var loadingProducts = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    if state.categoriesLoading {
                        ProgressView()
                            .tint(FrescoColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if state.categories.isEmpty {
                        EmptyState(systemImage: "square.grid.2x2", title: "No categories", message: "Categories are not available right now.")
                            .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(state.categories) { category in
                                Button {
                                    Task { await selectCategory(category, isSubcategory: false) }
                                } label: {
                                    CategoryGridCard(
                                        category: category,
                                        selected: category.id == selectedMainCategoryId
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let category = selectedCategory {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(title: "Subcategories", subtitle: "Browse children for selected category")

                                if loadingChildren {
                                    ProgressView()
                                        .tint(FrescoColors.primary)
                                        .frame(maxWidth: .infinity)
                                } else if subcategories.isEmpty {
                                    EmptyState(systemImage: "square.grid.2x2", title: "No subcategories", message: "This category does not expose nested categories yet.")
                                } else {
                                    FlowLayout(spacing: 10, rowSpacing: 10) {
                                        ForEach(subcategories) { child in
                                            Button {
                                                Task { await selectCategory(child, isSubcategory: true) }
                                            } label: {
                                                Text(child.name)
                                                    .font(.subheadline.weight(.heavy))
                                                    .foregroundStyle(child.id == selectedSubcategoryId ? .white : FrescoColors.primaryDark)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(child.id == selectedSubcategoryId ? FrescoColors.primary : Color(red: 0.925, green: 0.963, blue: 1))
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(
                                    title: "\(category.name) products",
                                    subtitle: loadingProducts ? "Loading products" : "\(categoryProducts.count) items available"
                                )

                                if loadingProducts {
                                    ProgressView()
                                        .tint(FrescoColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                } else if categoryProducts.isEmpty {
                                    EmptyState(systemImage: "tray", title: "No products", message: "No products were returned for this category.")
                                } else {
                                    ForEach(categoryProducts.prefix(20)) { product in
                                        NavigationLink(value: Route.product(product)) {
                                            CategoryProductRow(product: product) {
                                                state.toggleFavourite(product)
                                            } addAction: {
                                                Task { _ = await state.addToCart(product) }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(FrescoColors.background)
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.notifications) {
                        Image(systemName: state.unreadNotifications > 0 ? "bell.badge" : "bell")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .task {
                await state.loadCategories()
                if selectedCategory == nil, let first = state.categories.first {
                    await selectCategory(first, isSubcategory: false)
                }
            }
            .refreshable {
                await state.loadCategories(force: true)
                if let selectedCategory {
                    await selectCategory(selectedCategory, isSubcategory: selectedSubcategoryId == selectedCategory.id)
                } else if let first = state.categories.first {
                    await selectCategory(first, isSubcategory: false)
                }
            }
        }
    }

    private func selectCategory(_ category: CategoryItem, isSubcategory: Bool) async {
        selectedCategory = category
        if isSubcategory {
            selectedSubcategoryId = category.id
        } else {
            selectedMainCategoryId = category.id
            selectedSubcategoryId = nil
            loadingChildren = true
            subcategories = await state.loadCategoryChildren(category)
            loadingChildren = false
        }
        loadingProducts = true
        categoryProducts = await state.loadProducts(category: category)
        loadingProducts = false
    }
}

struct CategoryGridCard: View {
    let category: CategoryItem
    let selected: Bool

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white)
                if let url = URL(string: category.image), !category.image.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit().padding(8)
                        case .empty:
                            ProgressView().tint(FrescoColors.primary)
                        default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: 74, height: 74)

            Text(category.name)
                .font(.title3.weight(.black))
                .foregroundStyle(FrescoColors.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)

            Text(category.slug.isEmpty ? category.name.lowercased() : category.slug)
                .font(.subheadline)
                .foregroundStyle(FrescoColors.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background(selected ? Color(red: 0.925, green: 0.963, blue: 1) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(selected ? FrescoColors.primary : FrescoColors.border, lineWidth: selected ? 2 : 1)
        )
    }

    private var placeholder: some View {
        Image(systemName: "square.grid.2x2.fill")
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(FrescoColors.primary)
    }
}

struct CategoryProductRow: View {
    let product: Product
    let favouriteAction: () -> Void
    let addAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                RemoteProductImage(url: product.imageUrl)
                    .frame(width: 118, height: 118)
                Button(action: favouriteAction) {
                    Image(systemName: product.isFavourite ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(product.isFavourite ? .red : FrescoColors.primaryDark)
                        .frame(width: 46, height: 46)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                }
                .offset(x: 8, y: -8)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(product.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(FrescoColors.ink)
                    .lineLimit(2)
                Text(product.category.isEmpty ? "Fresh grocery" : product.category)
                    .font(.subheadline)
                    .foregroundStyle(FrescoColors.muted)
                Text(product.displayPrice)
                    .font(.headline.weight(.black))
                    .foregroundStyle(FrescoColors.muted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.925, green: 0.963, blue: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Spacer(minLength: 0)

            Button(action: addAction) {
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(FrescoColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FrescoColors.border, lineWidth: 1)
        )
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = rows(in: width, subviews: subviews)
        return CGSize(width: width, height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * rowSpacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + rowSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }

    private func rows(in width: CGFloat, subviews: Subviews) -> [(height: CGFloat, width: CGFloat)] {
        var rows: [(height: CGFloat, width: CGFloat)] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > width {
                rows.append((rowHeight, rowWidth))
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = rowWidth == 0 ? size.width : rowWidth + spacing + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        if rowWidth > 0 {
            rows.append((rowHeight, rowWidth))
        }
        return rows
    }
}
