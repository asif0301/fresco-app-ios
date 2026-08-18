import SwiftUI

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
