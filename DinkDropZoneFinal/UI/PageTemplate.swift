import SwiftUI

/// A standard page template to use as the base for all tabs
/// Provides consistent layout, spacing, and refreshable functionality
struct DSPageTemplate<Content: View, HeaderContent: View>: View {
    let title: String
    let showBackButton: Bool
    let onRefresh: (() async -> Void)?
    let headerContent: () -> HeaderContent
    let content: () -> Content
    
    @State private var isRefreshing = false
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        showBackButton: Bool = false,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder headerContent: @escaping () -> HeaderContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onRefresh = onRefresh
        self.headerContent = headerContent
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            RefreshableView(isRefreshing: $isRefreshing, onRefresh: onRefresh)
            
            VStack(spacing: 0) {
                // Optional header content
                headerContent()
                
                // Main content with consistent spacing
                VStack(spacing: DS.Layout.sectionSpacing) {
                    content()
                }
                .padding(.vertical, DS.Layout.verticalPadding)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showBackButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }
}

/// A version of the page template without a custom header
extension DSPageTemplate where HeaderContent == EmptyView {
    init(
        title: String,
        showBackButton: Bool = false,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            showBackButton: showBackButton,
            onRefresh: onRefresh,
            headerContent: { EmptyView() },
            content: content
        )
    }
}

/// A helper view for pull-to-refresh functionality
struct RefreshableView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: (() async -> Void)?
    
    var body: some View {
        VStack {
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .refreshable {
            guard let onRefresh = onRefresh else { return }
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }
}

/// A standard section container for consistent styling
struct DSSectionContainer<Content: View>: View {
    let title: String
    let actionTitle: String
    let action: (() -> Void)?
    let content: () -> Content
    
    init(
        title: String,
        actionTitle: String = "View All",
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: DS.Layout.itemSpacing) {
            DSSectionHeader(title: title, actionTitle: actionTitle, action: action)
            
            content()
        }
        .dsHorizontalPadding()
    }
}

#Preview {
    NavigationStack {
        DSPageTemplate(
            title: "Example Page",
            showBackButton: true,
            onRefresh: {
                // Simulating network delay
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            },
            headerContent: {
                ZStack {
                    DS.Color.headerGradient
                        .frame(height: 180)
                    
                    VStack {
                        Text("Header Content")
                            .font(DS.Font.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        ) {
            DSSectionContainer(title: "Section One", action: {}) {
                Text("Content goes here")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            }
            
            DSSectionContainer(title: "Section Two") {
                Text("More content")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            }
        }
    }
} 