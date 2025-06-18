import SwiftUI

/// A lightweight design-system holding colour, typography and layout constants used across the app.
/// Extend as the product grows – keep it focused on SINGLE-SOURCE-OF-TRUTH values.
enum DS {
    // MARK: Colours
    enum Color {
        /// Base background (adapts to light / dark automatically)
        static let background = SwiftUI.Color(UIColor.systemBackground)
        /// Secondary background used for cards and grouped cells
        static let surface = SwiftUI.Color(UIColor.secondarySystemBackground)
        /// Primary accent (brand colour)
        static let accent = SwiftUI.Color.purple
        /// Subtle border / divider colour
        static let divider = SwiftUI.Color(UIColor.separator)
        /// Primary text color
        static let primary = SwiftUI.Color.primary
        /// Secondary text color
        static let secondary = SwiftUI.Color.secondary
    }

    // MARK: Typography
    enum Font {
        static let display = SwiftUI.Font.system(size: 32, weight: .bold, design: .rounded)
        static let title = SwiftUI.Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title2 = SwiftUI.Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
        static let subheadline = SwiftUI.Font.system(size: 15, weight: .regular, design: .rounded)
        static let body = SwiftUI.Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption2 = SwiftUI.Font.system(size: 11, weight: .regular, design: .rounded)
    }

    // MARK: Layout
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let animationDuration: Double = 0.25
    }
}

// MARK: - View helpers

extension View {
    /// Applies the standard card appearance: surface background, rounded corners and subtle border.
    func dsCard() -> some View {
        self
            .padding(DS.Layout.cardPadding)
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(DS.Color.divider.opacity(0.1))
            )
    }

    /// Standard animation wrapper so we can tweak globally later.
    func dsAnimated(_ value: some Equatable) -> some View {
        self.animation(.easeOut(duration: DS.Layout.animationDuration), value: value)
    }
} 