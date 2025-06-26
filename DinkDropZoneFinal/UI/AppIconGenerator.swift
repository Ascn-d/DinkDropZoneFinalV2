import SwiftUI
import UIKit

/// Generates beautiful app icons for DinkDrop with pickleball theme
struct AppIconGenerator {
    
    static func generateAppIcon() -> UIImage {
        let size: CGFloat = 1024
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background gradient (purple to blue pickleball theme)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0).cgColor,
                                        UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0).cgColor,
                                        UIColor(red: 0.1, green: 0.6, blue: 1.0, alpha: 1.0).cgColor
                                    ] as CFArray,
                                    locations: [0.0, 0.5, 1.0])!
            
            cgContext.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: 0),
                                       end: CGPoint(x: size, y: size),
                                       options: [])
            
            // Add subtle texture overlay
            cgContext.setBlendMode(.overlay)
            cgContext.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            cgContext.fill(CGRect(x: 0, y: 0, width: size, height: size))
            cgContext.setBlendMode(.normal)
            
            // Main pickleball paddle
            drawPaddleIcon(in: cgContext, size: size)
            
            // Pickleball with holes
            drawPickleball(in: cgContext, size: size)
            
            // Dynamic motion lines
            drawMotionLines(in: cgContext, size: size)
            
            // "Drop Zone" geometric shape
            drawDropZoneShape(in: cgContext, size: size)
            
            // Subtle app name at bottom (optional)
            drawAppTitle(in: cgContext, size: size)
        }
    }
    
    private static func drawPaddleIcon(in context: CGContext, size: CGFloat) {
        let paddleCenter = CGPoint(x: size * 0.35, y: size * 0.4)
        let paddleWidth: CGFloat = size * 0.25
        let paddleHeight: CGFloat = size * 0.35
        
        // Paddle face (rounded rectangle)
        let paddleRect = CGRect(x: paddleCenter.x - paddleWidth/2,
                               y: paddleCenter.y - paddleHeight/2,
                               width: paddleWidth,
                               height: paddleHeight)
        
        // Paddle shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 8, height: 8), blur: 20, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        
        // Paddle face gradient
        let paddleGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [
                                        UIColor.white.cgColor,
                                        UIColor(white: 0.9, alpha: 1.0).cgColor
                                      ] as CFArray,
                                      locations: [0.0, 1.0])!
        
        let paddlePath = UIBezierPath(roundedRect: paddleRect, cornerRadius: paddleWidth * 0.4)
        context.addPath(paddlePath.cgPath)
        context.clip()
        context.drawLinearGradient(paddleGradient,
                                 start: CGPoint(x: paddleRect.minX, y: paddleRect.minY),
                                 end: CGPoint(x: paddleRect.maxX, y: paddleRect.maxY),
                                 options: [])
        context.restoreGState()
        
        // Paddle handle
        let handleWidth: CGFloat = size * 0.08
        let handleHeight: CGFloat = size * 0.15
        let handleRect = CGRect(x: paddleCenter.x - handleWidth/2,
                               y: paddleCenter.y + paddleHeight/2 - 10,
                               width: handleWidth,
                               height: handleHeight)
        
        context.setFillColor(UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0).cgColor)
        context.fillEllipse(in: handleRect)
        
        // Handle grip lines
        context.setStrokeColor(UIColor(red: 0.4, green: 0.3, blue: 0.1, alpha: 1.0).cgColor)
        context.setLineWidth(3)
        for i in 0..<4 {
            let y = handleRect.minY + CGFloat(i + 1) * handleRect.height / 5
            context.move(to: CGPoint(x: handleRect.minX + 10, y: y))
            context.addLine(to: CGPoint(x: handleRect.maxX - 10, y: y))
            context.strokePath()
        }
    }
    
    private static func drawPickleball(in context: CGContext, size: CGFloat) {
        let ballCenter = CGPoint(x: size * 0.7, y: size * 0.3)
        let ballRadius: CGFloat = size * 0.12
        
        // Ball shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 6, height: 6), blur: 15, color: UIColor.black.withAlphaComponent(0.25).cgColor)
        
        // Ball gradient (bright yellow-green)
        let ballGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0).cgColor,
                                        UIColor(red: 0.8, green: 1.0, blue: 0.2, alpha: 1.0).cgColor
                                    ] as CFArray,
                                    locations: [0.0, 1.0])!
        
        context.fillEllipse(in: CGRect(x: ballCenter.x - ballRadius,
                                      y: ballCenter.y - ballRadius,
                                      width: ballRadius * 2,
                                      height: ballRadius * 2))
        
        context.drawRadialGradient(ballGradient,
                                 startCenter: CGPoint(x: ballCenter.x - ballRadius * 0.3,
                                                     y: ballCenter.y - ballRadius * 0.3),
                                 startRadius: 0,
                                 endCenter: ballCenter,
                                 endRadius: ballRadius,
                                 options: [])
        context.restoreGState()
        
        // Pickleball holes pattern
        context.setFillColor(UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0).cgColor)
        let holeRadius: CGFloat = ballRadius * 0.15
        
        // Create classic pickleball hole pattern
        let holePositions: [(CGFloat, CGFloat)] = [
            (0, -0.6), (0.4, -0.4), (-0.4, -0.4),
            (0.6, 0), (-0.6, 0), (0, 0),
            (0.4, 0.4), (-0.4, 0.4), (0, 0.6)
        ]
        
        for (dx, dy) in holePositions {
            let holeCenter = CGPoint(x: ballCenter.x + dx * ballRadius,
                                   y: ballCenter.y + dy * ballRadius)
            context.fillEllipse(in: CGRect(x: holeCenter.x - holeRadius,
                                          y: holeCenter.y - holeRadius,
                                          width: holeRadius * 2,
                                          height: holeRadius * 2))
        }
    }
    
    private static func drawMotionLines(in context: CGContext, size: CGFloat) {
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.7).cgColor)
        context.setLineWidth(4)
        context.setLineCap(.round)
        
        // Dynamic curved motion lines behind the ball
        let startX = size * 0.45
        let startY = size * 0.35
        
        for i in 0..<3 {
            let offset = CGFloat(i) * 15
            context.move(to: CGPoint(x: startX - offset, y: startY + offset))
            
            let controlPoint1 = CGPoint(x: startX + 30 - offset, y: startY - 20 + offset)
            let controlPoint2 = CGPoint(x: startX + 80 - offset, y: startY + 30 + offset)
            let endPoint = CGPoint(x: size * 0.6 - offset, y: startY + 10 + offset)
            
            context.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
            context.strokePath()
        }
    }
    
    private static func drawDropZoneShape(in context: CGContext, size: CGFloat) {
        // Modern geometric "drop zone" target at bottom right
        let centerX = size * 0.75
        let centerY = size * 0.75
        let radius = size * 0.15
        
        context.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        context.setLineWidth(3)
        
        // Outer circle
        context.strokeEllipse(in: CGRect(x: centerX - radius,
                                        y: centerY - radius,
                                        width: radius * 2,
                                        height: radius * 2))
        
        // Inner circles (target rings)
        for i in 1...2 {
            let innerRadius = radius * (1.0 - CGFloat(i) * 0.3)
            context.strokeEllipse(in: CGRect(x: centerX - innerRadius,
                                            y: centerY - innerRadius,
                                            width: innerRadius * 2,
                                            height: innerRadius * 2))
        }
        
        // Center dot
        let dotRadius = radius * 0.1
        context.fillEllipse(in: CGRect(x: centerX - dotRadius,
                                      y: centerY - dotRadius,
                                      width: dotRadius * 2,
                                      height: dotRadius * 2))
    }
    
    private static func drawAppTitle(in context: CGContext, size: CGFloat) {
        // Subtle "DD" monogram at bottom
        let fontSize: CGFloat = size * 0.1
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .black),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        
        let text = "DD"
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(x: (size - textSize.width) / 2,
                             y: size * 0.85,
                             width: textSize.width,
                             height: textSize.height)
        
        // Text shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 2, height: 2), blur: 8, color: UIColor.black.withAlphaComponent(0.5).cgColor)
        text.draw(in: textRect, withAttributes: attributes)
        context.restoreGState()
    }
}

// MARK: - App Icon Preview View for SwiftUI

struct AppIconPreview: View {
    @State private var iconImage: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            if let iconImage = iconImage {
                Image(uiImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            
            Button("Generate App Icon") {
                iconImage = AppIconGenerator.generateAppIcon()
            }
            .dsPremiumButton()
        }
        .padding()
        .onAppear {
            iconImage = AppIconGenerator.generateAppIcon()
        }
    }
}

#Preview {
    AppIconPreview()
} 