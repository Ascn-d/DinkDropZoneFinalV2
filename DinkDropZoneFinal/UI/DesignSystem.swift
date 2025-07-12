import SwiftUI

/// A comprehensive design-system holding colour, typography and layout constants used across the app.
/// Enhanced with modern UI patterns and advanced visual effects.
enum DS {
    // MARK: Colours
    enum Color {
        /// Base background (adapts to light / dark automatically)
        static let background = SwiftUI.Color(UIColor.systemBackground)
        /// Secondary background used for cards and grouped cells
        static let surface = SwiftUI.Color(UIColor.secondarySystemBackground)
        /// Tertiary background for cells within cards
        static let surfaceAlt = SwiftUI.Color(UIColor.tertiarySystemBackground)
        /// Primary accent (brand colour)
        static let accent = SwiftUI.Color.purple
        /// Secondary accent color
        static let accentAlt = SwiftUI.Color.orange
        /// Subtle border / divider colour
        static let divider = SwiftUI.Color(UIColor.separator)
        /// Primary text color
        static let primary = SwiftUI.Color.primary
        /// Secondary text color
        static let secondary = SwiftUI.Color.secondary
        
        // Semantic colors
        static let success = SwiftUI.Color.green
        static let warning = SwiftUI.Color.orange
        static let error = SwiftUI.Color.red
        static let danger = SwiftUI.Color.red
        static let info = SwiftUI.Color.blue
        
        // Enhanced color palette for premium feel
        static let premium = SwiftUI.Color.indigo
        static let luxury = SwiftUI.Color.mint
        static let elite = SwiftUI.Color.cyan
        
        // Modern gradients
        static let primaryGradient = LinearGradient(
            colors: [accent, accentAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let headerGradient = LinearGradient(
            colors: [.blue.opacity(0.8), .purple.opacity(0.6), .indigo.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let surfaceGradient = LinearGradient(
            colors: [surface, surfaceAlt],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let glassGradient = LinearGradient(
            colors: [SwiftUI.Color.white.opacity(0.25), SwiftUI.Color.white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Achievement tier colors with enhanced vibrancy
        static let bronzeGradient = LinearGradient(
            colors: [SwiftUI.Color.orange.opacity(0.8), SwiftUI.Color.brown.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let silverGradient = LinearGradient(
            colors: [SwiftUI.Color.gray.opacity(0.8), SwiftUI.Color.secondary.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let goldGradient = LinearGradient(
            colors: [SwiftUI.Color.yellow.opacity(0.8), SwiftUI.Color.orange.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let platinumGradient = LinearGradient(
            colors: [SwiftUI.Color.cyan.opacity(0.8), SwiftUI.Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let legendaryGradient = LinearGradient(
            colors: [SwiftUI.Color.pink.opacity(0.8), SwiftUI.Color.purple.opacity(0.6), SwiftUI.Color.blue.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Additional gradients for enhanced UI
        static let backgroundGradient = LinearGradient(
            colors: [SwiftUI.Color(uiColor: UIColor.systemBackground), SwiftUI.Color(uiColor: UIColor.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let accentGradient = LinearGradient(
            colors: [accent, accent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warningGradient = LinearGradient(
            colors: [warning, warning.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let successGradient = LinearGradient(
            colors: [success, success.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let dangerGradient = LinearGradient(
            colors: [danger, danger.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let premiumGradient = LinearGradient(
            colors: [premium, premium.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Typography
    enum Font {
        static let display = SwiftUI.Font.system(size: 36, weight: .bold, design: .rounded)
        static let displayLarge = SwiftUI.Font.system(size: 42, weight: .black, design: .rounded)
        static let title = SwiftUI.Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title2 = SwiftUI.Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
        static let subheadline = SwiftUI.Font.system(size: 15, weight: .regular, design: .rounded)
        static let body = SwiftUI.Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodyEmphasized = SwiftUI.Font.system(size: 16, weight: .medium, design: .rounded)
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption2 = SwiftUI.Font.system(size: 11, weight: .regular, design: .rounded)
        static let footnote = SwiftUI.Font.system(size: 13, weight: .medium, design: .rounded)
        
        // Specialized fonts for UI elements
        static let button = SwiftUI.Font.system(size: 16, weight: .semibold, design: .rounded)
        static let tabItem = SwiftUI.Font.system(size: 10, weight: .medium, design: .rounded)
        static let navTitle = SwiftUI.Font.system(size: 20, weight: .bold, design: .rounded)
    }

    // MARK: Layout
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 12
        static let extraSmallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 24
        static let cardPadding: CGFloat = 20
        static let compactCardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 28
        static let itemSpacing: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let compactItemSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 16
        
        // Animation durations
        static let fastAnimation: Double = 0.2
        static let standardAnimation: Double = 0.3
        static let slowAnimation: Double = 0.5
        static let bounceAnimation: Double = 0.6
        
        // Interaction feedback
        static let hapticIntensity: CGFloat = 0.5
        static let pressScale: CGFloat = 0.96
        static let hoverScale: CGFloat = 1.02
        
        // Standard edge insets
        static let edgeInsets = EdgeInsets(
            top: verticalPadding, 
            leading: horizontalPadding, 
            bottom: verticalPadding, 
            trailing: horizontalPadding
        )
        
        // Grid layouts
        static let compactGrid = Array(repeating: GridItem(.flexible(), spacing: itemSpacing), count: 2)
        static let standardGrid = Array(repeating: GridItem(.flexible(), spacing: itemSpacing), count: 3)
        static let wideGrid = Array(repeating: GridItem(.flexible(), spacing: itemSpacing), count: 4)
    }
    
    // MARK: Enhanced Shadows & Effects
    enum Shadow {
        static let subtle = ShadowStyle(color: SwiftUI.Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        static let small = ShadowStyle(color: SwiftUI.Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: SwiftUI.Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
        static let large = ShadowStyle(color: SwiftUI.Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
        static let dramatic = ShadowStyle(color: SwiftUI.Color.black.opacity(0.24), radius: 16, x: 0, y: 8)
        
        // Colored shadows for special effects
        static let accentGlow = ShadowStyle(color: Color.accent.opacity(0.4), radius: 12, x: 0, y: 6)
        static let successGlow = ShadowStyle(color: Color.success.opacity(0.3), radius: 8, x: 0, y: 4)
        static let warningGlow = ShadowStyle(color: Color.warning.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: Animation Presets
    enum Animation {
        static let gentle = SwiftUI.Animation.easeInOut(duration: Layout.standardAnimation)
        static let snappy = SwiftUI.Animation.easeOut(duration: Layout.fastAnimation)
        static let bouncy = SwiftUI.Animation.spring(response: Layout.bounceAnimation, dampingFraction: 0.7)
        static let elastic = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let smooth = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 30)
        
        // Specialized animations for different UI elements
        static let cardAppear = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let buttonPress = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: 0.4)
    }
}

// Enhanced shadow style struct
struct ShadowStyle {
    let color: SwiftUI.Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func apply(to view: some View) -> some View {
        view.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - Enhanced View Extensions

extension View {
    /// Applies the premium card appearance with enhanced styling
    func dsPremiumCard(style: DSCardStyle = .standard) -> some View {
        self
            .padding(DS.Layout.cardPadding)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .modifier(ShadowViewModifier(shadow: style.shadow))
    }
    
    /// Applies interactive card behavior with press animations
    func dsInteractiveCard(onTap: @escaping () -> Void) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onTap()
            }
            .scaleEffect(1.0)
            .animation(DS.Animation.buttonPress, value: false)
    }
    
    /// Applies glass morphism effect
    func dsGlassMorphism(intensity: Double = 0.8) -> some View {
        self
            .background(.ultraThinMaterial.opacity(intensity))
            .overlay(
                DS.Color.glassGradient
                    .blendMode(.overlay)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(SwiftUI.Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    /// Applies floating animation
    func dsFloating(offset: CGFloat = 10, duration: Double = 3.0) -> some View {
        modifier(FloatingModifier(offset: offset, duration: duration))
    }
    
    /// Applies shimmer loading effect
    func dsShimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
    
    /// Applies premium button styling
    func dsPremiumButton(
        style: DSButtonStyle = .primary,
        isPressed: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        modifier(PremiumButtonModifier(style: style, isPressed: isPressed, isDisabled: isDisabled))
    }
    
    /// Standard animation wrapper with enhanced presets
    func dsAnimated<T: Equatable>(_ value: T, animation: SwiftUI.Animation = DS.Animation.gentle) -> some View {
        self.animation(animation, value: value)
    }
    
    /// Enhanced section spacing with better visual rhythm
    func dsSectionSpacing() -> some View {
        self.padding(.bottom, DS.Layout.sectionSpacing)
    }
    
    /// Enhanced item spacing
    func dsItemSpacing() -> some View {
        self.padding(.bottom, DS.Layout.itemSpacing)
    }
    
    /// Standard horizontal padding for content
    func dsHorizontalPadding() -> some View {
        self.padding(.horizontal, DS.Layout.horizontalPadding)
    }
    
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
}

// MARK: - Enhanced Card Styles

enum DSCardStyle {
        case standard
    case prominent
    case glass
    case premium
    case minimal
    case gradient
    case selected
    case subtle
    
    var background: AnyView {
        switch self {
        case .standard:
            return AnyView(DS.Color.surface)
        case .prominent:
            return AnyView(DS.Color.surfaceGradient)
        case .glass:
            return AnyView(Color.clear)
        case .premium:
            return AnyView(DS.Color.primaryGradient.opacity(0.1))
        case .minimal:
            return AnyView(DS.Color.surfaceAlt)
        case .gradient:
            return AnyView(DS.Color.primaryGradient.opacity(0.15))
        case .selected:
            return AnyView(DS.Color.accent.opacity(0.1))
        case .subtle:
            return AnyView(DS.Color.surface.opacity(0.8))
        }
    }
    
    var borderColor: SwiftUI.Color {
        switch self {
        case .standard, .minimal:
            return DS.Color.divider.opacity(0.1)
        case .prominent:
            return DS.Color.accent.opacity(0.2)
        case .glass:
            return SwiftUI.Color.white.opacity(0.2)
        case .premium:
            return DS.Color.accent.opacity(0.3)
        case .gradient:
            return DS.Color.accent.opacity(0.4)
        case .selected, .subtle:
            return DS.Color.accent.opacity(0.2)
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard, .minimal: return 0.5
        case .prominent, .premium: return 1
        case .glass: return 1.5
        case .gradient: return 1
        case .selected, .subtle: return 1
        }
    }
    
    var shadow: ShadowStyle {
        switch self {
        case .minimal: return DS.Shadow.subtle
        case .standard: return DS.Shadow.small
        case .prominent: return DS.Shadow.medium
        case .glass: return DS.Shadow.large
        case .premium: return DS.Shadow.accentGlow
        case .gradient: return DS.Shadow.medium
        case .selected: return DS.Shadow.accentGlow
        case .subtle: return DS.Shadow.subtle
        }
    }
}

// MARK: - Enhanced Button Styles

enum DSButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case ghost
    
    var backgroundColor: AnyView {
        switch self {
        case .primary:
            return AnyView(DS.Color.primaryGradient)
        case .secondary:
            return AnyView(DS.Color.accent.opacity(0.1))
        case .tertiary:
            return AnyView(DS.Color.surface)
        case .destructive:
            return AnyView(LinearGradient(colors: [.red.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .ghost:
            return AnyView(Color.clear)
        }
    }
    
    var foregroundColor: SwiftUI.Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary, .tertiary, .ghost:
            return DS.Color.accent
        }
    }
    
    var borderColor: SwiftUI.Color {
        switch self {
        case .primary, .destructive:
            return .clear
        case .secondary:
            return DS.Color.accent.opacity(0.3)
        case .tertiary:
            return DS.Color.divider
        case .ghost:
            return DS.Color.accent.opacity(0.5)
        }
    }
}

// MARK: - View Modifiers

struct ShadowViewModifier: ViewModifier {
    let shadow: ShadowStyle
    
    func body(content: Content) -> some View {
        shadow.apply(to: content)
    }
}

struct FloatingModifier: ViewModifier {
    let offset: CGFloat
    let duration: Double
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -offset : 0)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .opacity(isActive ? 1 : 0)
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                if isActive {
                    phase = 300
                }
            }
    }
}

struct PremiumButtonModifier: ViewModifier {
    let style: DSButtonStyle
    let isPressed: Bool
    let isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(DS.Font.button)
            .foregroundColor(isDisabled ? DS.Color.secondary : style.foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if isDisabled {
                        DS.Color.surfaceAlt
                    } else {
                        style.backgroundColor
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style == .ghost || style == .tertiary ? 1 : 0)
            )
            .scaleEffect(isPressed ? DS.Layout.pressScale : 1.0)
            .animation(DS.Animation.buttonPress, value: isPressed)
            .disabled(isDisabled)
    }
}

// MARK: - Reusable Premium Components

/// Premium section header with enhanced styling
struct DSPremiumSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String
    let icon: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        actionTitle: String = "View All",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Icon and title section
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(DS.Font.title3)
                            .foregroundColor(DS.Color.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Action button
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            Text(actionTitle)
                                .font(DS.Font.footnote)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(DS.Color.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.Color.accent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Decorative accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(DS.Color.primaryGradient)
                .frame(width: 40, height: 3)
        }
        .padding(.bottom, 12)
    }
}

/// Enhanced progress indicator with multiple styles
struct DSEnhancedProgressBar: View {
    let value: Double
    let total: Double
    let style: ProgressStyle
    let showPercentage: Bool
    
    enum ProgressStyle {
        case linear
        case circular
        case ring
    }
    
    init(
        value: Double,
        total: Double = 1.0,
        style: ProgressStyle = .linear,
        showPercentage: Bool = false
    ) {
        self.value = value
        self.total = total
        self.style = style
        self.showPercentage = showPercentage
    }
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }
    
    var body: some View {
        switch style {
        case .linear:
            linearProgress
        case .circular:
            circularProgress
        case .ring:
            ringProgress
        }
    }
    
    private var linearProgress: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.surfaceAlt)
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.primaryGradient)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(DS.Animation.smooth, value: progress)
                }
            }
            .frame(height: 8)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(DS.Font.caption2)
                    .foregroundColor(DS.Color.secondary)
            }
        }
    }
    
    private var circularProgress: some View {
        ZStack {
            Circle()
                .stroke(DS.Color.surfaceAlt, lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(DS.Color.primaryGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(DS.Animation.smooth, value: progress)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(DS.Font.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.primary)
            }
        }
        .frame(width: 60, height: 60)
    }
    
    private var ringProgress: some View {
        ZStack {
            Circle()
                .stroke(DS.Color.surfaceAlt, lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [DS.Color.accent, DS.Color.accentAlt]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DS.Animation.elastic, value: progress)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(DS.Font.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.accent)
            }
        }
        .frame(width: 50, height: 50)
    }
}

/// Premium loading state with enhanced animations
struct DSPremiumLoadingView: View {
    let message: String?
    let style: LoadingStyle
    
    enum LoadingStyle {
        case standard
        case dots
        case pulse
        case shimmer
    }
    
    init(message: String? = nil, style: LoadingStyle = .standard) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .standard:
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .tint(DS.Color.accent)
                    
            case .dots:
                DotsLoadingView()
                
            case .pulse:
                PulseLoadingView()
                
            case .shimmer:
                ShimmerLoadingView()
            }
            
            if let message = message {
                Text(message)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

/// Animated dots loading indicator
struct DotsLoadingView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(DS.Color.accent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

/// Pulse loading indicator
struct PulseLoadingView: View {
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        Circle()
            .fill(DS.Color.primaryGradient)
            .frame(width: 60, height: 60)
            .scaleEffect(scale)
            .opacity(2.0 - scale)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: scale
            )
            .onAppear {
                scale = 1.2
            }
    }
}

/// Shimmer loading placeholder
struct ShimmerLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.Color.surfaceAlt)
                .frame(height: 20)
                .dsShimmer()
            
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.Color.surfaceAlt)
                .frame(height: 16)
                .dsShimmer()
            
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.Color.surfaceAlt)
                .frame(height: 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsShimmer()
        }
    }
}

// MARK: - Modern Card Component

/// Enhanced card with modern styling and multiple style options
struct DSModernCard<Content: View>: View {
    let content: Content
    let style: DSCardStyle
    
    init(style: DSCardStyle = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DS.Layout.cardPadding)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
                         .modifier(ShadowViewModifier(shadow: style.shadow))
          }
} 

// MARK: - Missing Standard Components

/// Standard section header with title and optional action button
struct DSSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String
    
    init(title: String, actionTitle: String = "View All", action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(DS.Font.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            if let action = action {
                Button(actionTitle) {
                    action()
                }
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.accent)
            }
        }
        .padding(.bottom, 8)
    }
}

/// Modern section container with enhanced styling
struct DSModernSectionContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String = "View All",
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let action = action {
                        Button(action: action) {
                            HStack(spacing: 4) {
                                Text(actionTitle)
                                    .font(DS.Font.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(DS.Color.accent)
                        }
                    }
                }
                
                // Decorative line
                Rectangle()
                    .fill(DS.Color.accent.opacity(0.3))
                    .frame(width: 30, height: 2)
                    .clipShape(Capsule())
            }
            
            content
        }
        .padding(.bottom, DS.Layout.sectionSpacing)
    }
}

/// Standard empty state view
struct DSEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(DS.Color.secondary.opacity(0.6))
            
            Text(title)
                .font(DS.Font.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DS.Color.secondary)
            
            Text(message)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

/// Enhanced button styles for different use cases
struct DSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            .shadow(color: DS.Color.accent.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
         }
}

/// Progress bar with consistent styling
struct DSProgressBar: View {
    let value: Double
    let total: Double?
    let color: SwiftUI.Color
    
    init(value: Double, color: SwiftUI.Color) {
        self.value = value
        self.total = 1.0
        self.color = color
    }
    
    init(value: Double, total: Double, color: SwiftUI.Color) {
        self.value = value
        self.total = total
        self.color = color
    }
    
    var body: some View {
        ProgressView(value: value, total: total ?? 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .scaleEffect(x: 1, y: 1.5, anchor: .center)
    }
}

/// Profile daily challenge card
struct ProfileDailyChallengeCard: View {
    let title: String
    let progress: Double
    let reward: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isCompleted ? .green : DS.Color.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DS.Font.body)
                    .fontWeight(.medium)
                    .foregroundColor(DS.Color.primary)
                
                if !isCompleted {
                    DSProgressBar(value: progress, color: DS.Color.accent)
                        .frame(height: 4)
                }
                
                Text(reward)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

/// Profile recent match card
struct ProfileRecentMatchCard: View {
    let opponent: String
    let result: String
    let score: String
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(opponent)")
                    .font(DS.Font.body)
                    .fontWeight(.medium)
                    .foregroundColor(DS.Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(date)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(result)
                    .font(DS.Font.body)
                    .fontWeight(.semibold)
                    .foregroundColor(result == "Win" ? .green : .red)
                
                Text(score)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
        }
        .padding()
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

/// Monthly performance card
struct MonthlyPerformanceCard: View {
    let title: String
    let value: String
    let trend: String
    let color: SwiftUI.Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
            
            Text(value)
                .font(DS.Font.title2)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(trend)
                .font(DS.Font.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

/// Detailed stat card
struct DetailedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: SwiftUI.Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(DS.Font.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(DS.Font.headline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(title)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

// MARK: - Additional Components

/// Progress ring component
struct DSProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: SwiftUI.Color
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60, color: SwiftUI.Color = DS.Color.accent) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
        .frame(width: size, height: size)
    }
}

/// Animated counter component
struct DSAnimatedCounter: View {
    let value: Int
    let duration: Double
    @State private var animatedValue: Int = 0
    
    init(value: Int, duration: Double = 1.0) {
        self.value = value
        self.duration = duration
    }
    
    var body: some View {
        Text("\(animatedValue)")
            .font(DS.Font.title)
            .fontWeight(.bold)
            .contentTransition(.numericText())
            .onAppear {
                animateCounter()
            }
            .onChange(of: value) { _, _ in
                animateCounter()
            }
    }
    
    private func animateCounter() {
        let steps = 20
        let stepValue = value / steps
        let stepDuration = duration / Double(steps)
        
        animatedValue = 0
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    animatedValue = min(stepValue * i, value)
                }
            }
        }
    }
}

/// Quick stat badge for profile displays
struct QuickStatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradient: Bool
    
    init(title: String, value: String, icon: String, color: Color, gradient: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.gradient = gradient
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if gradient {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                } else {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(gradient ? .white : color)
            }
            
            Text(value)
                .font(DS.Font.subheadline)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(title)
                .font(DS.Font.caption2)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

// MARK: - Advanced Animation System

extension DS {
    enum Transition {
        static let slideIn = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
        
        static let slideUp = AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
        
        static let scaleAndFade = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        
        static let flipCard = AnyTransition.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
        
        static let blur = AnyTransition.modifier(
            active: BlurModifier(radius: 10),
            identity: BlurModifier(radius: 0)
        )
        
        static let hero = AnyTransition.asymmetric(
            insertion: .scale(scale: 1.2).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
    
    enum TimingCurve {
        static let easeInOutBack = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let easeInBack = SwiftUI.Animation.easeIn(duration: 0.4)
        static let easeOutBack = SwiftUI.Animation.easeOut(duration: 0.4)
        static let easeInOutCirc = SwiftUI.Animation.easeInOut(duration: 0.6)
        static let easeInOutExpo = SwiftUI.Animation.easeInOut(duration: 0.8)
    }
    
    enum SpringPreset {
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let snappy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let wobbly = SwiftUI.Animation.spring(response: 0.8, dampingFraction: 0.5)
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.9)
    }
}

// MARK: - Enhanced View Extensions for Animations

extension View {
    /// Applies hero animation entrance
    func dsHeroEntrance(delay: Double = 0) -> some View {
        modifier(HeroEntranceModifier(delay: delay))
    }
    
    /// Applies staggered list animation
    func dsStaggeredAppear(index: Int, total: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index, total: total))
    }
    
    /// Applies pulse animation
    func dsPulse(isActive: Bool = true, scale: CGFloat = 1.05) -> some View {
        modifier(PulseModifier(isActive: isActive, scale: scale))
    }
    
    /// Applies bouncy press animation
    func dsBouncyPress() -> some View {
        modifier(BouncyPressModifier())
    }
    
    /// Applies smooth scale transition
    func dsSmoothScale(isPressed: Bool) -> some View {
        scaleEffect(isPressed ? DS.Layout.pressScale : 1.0)
            .animation(DS.SpringPreset.quick, value: isPressed)
    }
    
    /// Applies magnetic hover effect
    func dsMagneticHover(isHovered: Bool = false) -> some View {
        modifier(MagneticHoverModifier(isHovered: isHovered))
    }
    
    /// Applies typewriter text animation
    func dsTypewriter(text: String, speed: Double = 0.05) -> some View {
        modifier(TypewriterModifier(text: text, speed: speed))
    }
    
    // ParticleEffectModifier functionality moved to TournamentDesignSystem.swift
    
    /// Applies smooth rotation animation
    func dsRotating(isActive: Bool = true, duration: Double = 2.0) -> some View {
        modifier(RotatingModifier(isActive: isActive, duration: duration))
    }
    
    /// Applies breathing animation
    func dsBreathing(isActive: Bool = true) -> some View {
        modifier(BreathingModifier(isActive: isActive))
    }
}

// MARK: - Advanced Animation Modifiers

struct BlurModifier: ViewModifier {
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

struct HeroEntranceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 30)
            .animation(DS.SpringPreset.bouncy.delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let total: Int
    @State private var isVisible = false
    
    private var delay: Double {
        Double(index) * 0.1
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : -50)
            .animation(DS.SpringPreset.gentle.delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct PulseModifier: ViewModifier {
    let isActive: Bool
    let scale: CGFloat
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .animation(
                isActive ? 
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                .default,
                value: isPulsing
            )
            .onAppear {
                isPulsing = isActive
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
    }
}

struct BouncyPressModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(DS.SpringPreset.quick) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DS.SpringPreset.bouncy) {
                        isPressed = false
                    }
                }
            }
    }
}

struct MagneticHoverModifier: ViewModifier {
    let isHovered: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(
                color: DS.Color.accent.opacity(isHovered ? 0.3 : 0),
                radius: isHovered ? 10 : 0,
                x: 0,
                y: isHovered ? 5 : 0
            )
            .animation(DS.SpringPreset.gentle, value: isHovered)
    }
}

struct TypewriterModifier: ViewModifier {
    let text: String
    let speed: Double
    @State private var displayedText = ""
    
    func body(content: Content) -> some View {
        Text(displayedText)
            .onAppear {
                typeWriter()
            }
    }
    
    private func typeWriter() {
        for (index, character) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * speed) {
                displayedText += String(character)
            }
        }
    }
}

// ParticleEffectModifier moved to TournamentDesignSystem.swift

struct RotatingModifier: ViewModifier {
    let isActive: Bool
    let duration: Double
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .animation(
                isActive ? 
                Animation.linear(duration: duration).repeatForever(autoreverses: false) : 
                .default,
                value: rotation
            )
            .onAppear {
                if isActive {
                    rotation = 360
                }
            }
    }
}

struct BreathingModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(
                isActive ? 
                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true) : 
                .default,
                value: scale
            )
            .onAppear {
                if isActive {
                    scale = 1.1
                }
            }
    }
}

// MARK: - Supporting Data Structures

struct ParticleData {
    let id = UUID()
    var position = CGPoint(x: CGFloat.random(in: 0...400), y: 400)
    let size = CGFloat.random(in: 2...8)
    var opacity: Double = 1.0
}

// MARK: - Text Display Extensions

extension View {
    /// Applies consistent text truncation handling for titles
    func dsTextTitle() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// Applies consistent text truncation handling for body text
    func dsTextBody(lines: Int = 2) -> some View {
        self
            .lineLimit(lines)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// Applies consistent text truncation handling for captions
    func dsTextCaption(lines: Int = 1) -> some View {
        self
            .lineLimit(lines)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// Applies consistent text truncation handling for descriptions
    func dsTextDescription(lines: Int = 3) -> some View {
        self
            .lineLimit(lines)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// Improved button responsiveness with haptic feedback
    func dsResponsiveButton(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self
            .onTapGesture {
                UIImpactFeedbackGenerator(style: style).impactOccurred()
            }
            .dsBouncyPress()
    }
    
    /// Improved animation performance for complex views
    func dsOptimizedAnimation<T: Equatable>(_ value: T, duration: Double = 0.3) -> some View {
        self
            .animation(.easeInOut(duration: duration), value: value)
            .drawingGroup() // Optimize complex animations
    }
} 