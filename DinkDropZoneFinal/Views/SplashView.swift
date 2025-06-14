//
//  SplashView.swift
//

import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.accentColor, Color.blue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Image(systemName: "sportscourt")
                .resizable()
                .scaledToFit()
                .frame(width: animate ? 180 : 60)
                .foregroundColor(.white)
                .opacity(animate ? 1 : 0.3)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        animate = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isActive = false
                        }
                    }
                }
        }
    }
}

#Preview {
    SplashView(isActive: .constant(true))
}
