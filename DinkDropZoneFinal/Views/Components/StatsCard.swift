import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    var color: Color = .accentColor
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity,minHeight: 70)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HStack { StatsCard(title: "Players", value: "16") }
        .padding()
} 