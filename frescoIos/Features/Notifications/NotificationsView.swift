import SwiftUI

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
