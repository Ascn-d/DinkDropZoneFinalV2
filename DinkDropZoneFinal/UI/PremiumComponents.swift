import SwiftUI

// MARK: - Premium Card Components

/// Enhanced interactive card with advanced animations and haptic feedback
struct DSPremiumInteractiveCard<Content: View>: View {
    let content: Content
    let action: (() -> Void)?
    let style: DSCardStyle
    let glowColor: Color?
    
    @State private var isPressed = false
    
    init(
        style: DSCardStyle = .standard, 
        glowColor: Color? = nil,
        action: (() -> Void)? = nil, 
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.glowColor = glowColor
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            content
                .padding(DS.Layout.cardPadding)
                .background(getBackgroundView())
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                        .stroke(getBorderColor(), lineWidth: style.borderWidth)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .shadow(color: getShadowColor(), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    @ViewBuilder
    private func getBackgroundView() -> some View {
        if style == .glass {
            Color.clear
                .background(.ultraThinMaterial.opacity(0.8))
        } else {
            style.background
        }
    }
    
    private func getBorderColor() -> Color {
        if let glowColor = glowColor {
            return glowColor.opacity(0.3)
        }
        return style.borderColor
    }
    
    private func getShadowColor() -> Color {
        if let glowColor = glowColor {
            return glowColor.opacity(isPressed ? 0.2 : 0.4)
        }
        return Color.black.opacity(isPressed ? 0.05 : 0.1)
    }
}

/// Glass morphism card with blur effects
struct DSGlassMorphismCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DS.Layout.cardPadding)
            .background(.ultraThinMaterial.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

/// Floating action button with premium styling
struct DSPremiumFloatingButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Premium Text & Typography Components

/// Gradient text with premium styling
struct DSGradientText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient
    
    init(text: String, font: Font = DS.Font.headline, gradient: LinearGradient = DS.Color.primaryGradient) {
        self.text = text
        self.font = font
        self.gradient = gradient
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

/// Premium text field with floating label
struct DSPremiumTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    
    @FocusState private var isFocused: Bool
    @State private var showPassword = false
    
    init(title: String, placeholder: String = "", text: Binding<String>, icon: String? = nil, isSecure: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFocused ? DS.Color.accent : DS.Color.secondary)
                }
                
                Text(title)
                    .font(DS.Font.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(isFocused ? DS.Color.accent : DS.Color.secondary)
            }
            
            HStack {
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(DS.Font.body)
                .foregroundColor(DS.Color.primary)
                .focused($isFocused)
                
                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DS.Color.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                    .stroke(isFocused ? DS.Color.accent : DS.Color.divider, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

/// Pulsing dot indicator
struct DSPulsingDot: View {
    let color: Color
    let size: CGFloat
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6
    
    init(color: Color = DS.Color.accent, size: CGFloat = 12) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: scale
            )
            .onAppear {
                scale = 1.2
                opacity = 1.0
            }
    }
}

// MARK: - Premium Progress & Loading Components

/// Circular progress with percentage display
struct DSCircularProgress: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showPercentage: Bool
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, size: CGFloat = 80, lineWidth: CGFloat = 8, showPercentage: Bool = true) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.Color.surfaceAlt, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(DS.Color.primaryGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Color.primary)
                    
                    Text("%")
                        .font(.system(size: size * 0.15, weight: .medium, design: .rounded))
                        .foregroundColor(DS.Color.secondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Compact Stats Components

/// Compact stats card
struct CompactStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let showRing: Bool
    let ringProgress: Double
    
    init(title: String, value: String, icon: String, color: Color, showRing: Bool = false, ringProgress: Double = 0) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.showRing = showRing
        self.ringProgress = ringProgress
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if showRing {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(DS.Font.bodyEmphasized)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(title)
                .font(DS.Font.caption2)
                .foregroundColor(DS.Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.smallCornerRadius))
    }
} 