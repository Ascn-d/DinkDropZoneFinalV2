import SwiftUI

/// Animated hamburger menu button that morphs into an "X" when active.
struct HamburgerButton: View {
    @Binding var isActive: Bool
    let size: CGFloat
    let color: Color
    
    init(isActive: Binding<Bool>, size: CGFloat = 22, color: Color = DS.Color.primary) {
        self._isActive = isActive
        self.size = size
        self.color = color
    }
    
    private var lineWidth: CGFloat { size / 12 }
    private var lineLength: CGFloat { size }
    private var spacing: CGFloat { size / 3 }
    
    var body: some View {
        VStack(spacing: spacing) {
            Capsule()
                .fill(color)
                .frame(width: lineLength, height: lineWidth)
                .rotationEffect(.degrees(isActive ? 45 : 0), anchor: .center)
                .offset(y: isActive ? (spacing + lineWidth) : 0)
            Capsule()
                .fill(color)
                .frame(width: lineLength, height: lineWidth)
                .opacity(isActive ? 0 : 1)
            Capsule()
                .fill(color)
                .frame(width: lineLength, height: lineWidth)
                .rotationEffect(.degrees(isActive ? -45 : 0), anchor: .center)
                .offset(y: isActive ? -(spacing + lineWidth) : 0)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        .accessibilityLabel("Toggle menu")
    }
}

// Helper for previews where we need a @State
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

#Preview("Hamburger Button") {
    StatefulPreviewWrapper(false) { isActive in
        HamburgerButton(isActive: isActive)
            .padding()
    }
} 