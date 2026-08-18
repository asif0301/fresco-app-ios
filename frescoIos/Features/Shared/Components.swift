import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(configuration.isPressed ? FrescoColors.primaryDark : FrescoColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct Surface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(FrescoColors.border, lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(FrescoColors.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(FrescoColors.muted)
        }
    }
}

struct RemoteProductImage: View {
    let url: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.918, green: 0.965, blue: 1))
            if let remoteURL = URL(string: url), !url.isEmpty {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(8)
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView().tint(FrescoColors.primary)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(FrescoColors.primary)
    }
}

struct BannerCard: View {
    let banner: BannerItem

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: [banner.color, FrescoColors.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(banner.title)
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(banner.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .lineLimit(3)
                    Text(banner.cta)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(FrescoColors.primaryDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.white)
                        .clipShape(Capsule())
                }
                Spacer(minLength: 4)
                Image("fresco-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct CategoryTile: View {
    let category: CategoryItem

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                if let url = URL(string: category.image), !category.image.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit().padding(12)
                    } placeholder: {
                        ProgressView().tint(FrescoColors.primary)
                    }
                } else {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(FrescoColors.primary)
                }
            }
            .frame(width: 76, height: 70)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FrescoColors.border, lineWidth: 1)
            )
            Text(category.name)
                .font(.caption.weight(.heavy))
                .foregroundStyle(FrescoColors.ink)
                .lineLimit(1)
                .frame(width: 86)
        }
    }
}

struct ProductCard: View {
    let product: Product
    let compact: Bool
    let addAction: () -> Void
    let favouriteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RemoteProductImage(url: product.imageUrl)
                    .frame(height: compact ? 124 : 150)
                Button(action: favouriteAction) {
                    Image(systemName: product.isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(product.isFavourite ? .red : FrescoColors.primaryDark)
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                }
                .padding(10)
            }
            Text(product.category)
                .font(.caption.weight(.heavy))
                .foregroundStyle(FrescoColors.primary)
                .lineLimit(1)
            Text(product.name)
                .font(.headline.weight(.black))
                .foregroundStyle(FrescoColors.ink)
                .lineLimit(2)
                .frame(height: 44, alignment: .topLeading)
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", product.rating))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(FrescoColors.muted)
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.weight(.black))
                    .foregroundStyle(FrescoColors.primaryDark)
            }
            Button(action: addAction) {
                Label("Add", systemImage: "cart.badge.plus")
                    .font(.subheadline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(FrescoColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(FrescoColors.border, lineWidth: 1)
        )
        .frame(width: compact ? nil : 196)
    }
}

struct EmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(FrescoColors.primary)
            Text(title)
                .font(.title3.weight(.black))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FrescoColors.muted)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

struct BadgeCount: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .frame(minWidth: 17, minHeight: 17)
                .background(.red)
                .clipShape(Capsule())
        }
    }
}
