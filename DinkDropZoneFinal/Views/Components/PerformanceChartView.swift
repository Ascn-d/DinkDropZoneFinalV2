import SwiftUI

struct PerformanceChartView: View {
    let data: [(date: Date, elo: Int, winRate: Double)]
    
    @State private var selectedDataPoint: Int? = nil
    @State private var showingWinRate = false
    
    // Add PerformanceMetric enum
    enum PerformanceMetric: String, CaseIterable {
        case elo = "ELO"
        case winRate = "Win Rate"
    }
    
    // Optional property to control which metric to show
    var selectedMetric: PerformanceMetric = .elo
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var minElo: Int {
        guard let min = data.map({ $0.elo }).min() else { return 0 }
        return max(0, min - 50)
    }
    
    private var maxElo: Int {
        guard let max = data.map({ $0.elo }).max() else { return 1100 }
        return max + 50
    }
    
    private var eloRange: Int {
        maxElo - minElo
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Header
            chartHeader
            
            // Chart
            chartContent
        }
    }
    
    // MARK: - View Components
    
    private var chartHeader: some View {
        HStack {
            metricButton
            
            Spacer()
            
            selectedPointInfo
        }
    }
    
    private var metricButton: some View {
        Button(action: {
            withAnimation {
                // No action needed as selectedMetric is now controlled from outside
            }
        }) {
            HStack(spacing: 8) {
                Text(selectedMetric == .winRate ? "Win Rate" : "ELO Rating")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
            }
            .foregroundColor(selectedMetric == .winRate ? .green : .blue)
        }
    }
    
    private var selectedPointInfo: some View {
        Group {
            if let selectedIndex = selectedDataPoint, selectedIndex < data.count {
                let point = data[selectedIndex]
                Text("\(dateFormatter.string(from: point.date)): \(selectedMetric == .winRate ? "\(Int(point.winRate * 100))%" : "\(point.elo) ELO")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                EmptyView()
            }
        }
    }
    
    private var chartContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                gridLines
                
                // Y-axis labels (left side)
                yAxisLabels
                    .offset(x: -30)
                
                // Chart lines
                chartLines(in: geometry)
                
                // Data points
                dataPoints(in: geometry)
                
                // X-axis labels (bottom)
                xAxisLabels
                    .offset(y: geometry.size.height + 10)
            }
            .padding(.leading, 30) // Make room for Y-axis labels
            .padding(.bottom, 20) // Make room for X-axis labels
        }
    }
    
    private var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(0..<5) { i in
                Group {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    if i < 4 {
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var yAxisLabels: some View {
        VStack(spacing: 0) {
            ForEach(0..<5) { i in
                Group {
                    if selectedMetric == .winRate {
                        Text("\(100 - i * 20)%")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .frame(width: 25, alignment: .trailing)
                    } else {
                        Text("\(maxElo - (i * eloRange / 4))")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .frame(width: 25, alignment: .trailing)
                    }
                    
                    if i < 4 {
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func chartLines(in geometry: GeometryProxy) -> some View {
        Path { path in
            let width = geometry.size.width - 10
            let height = geometry.size.height
            let stepX = width / CGFloat(data.count - 1)
            
            for i in 0..<data.count {
                let point = data[i]
                let x = stepX * CGFloat(i)
                
                // Calculate y based on ELO or win rate
                let y: CGFloat
                if selectedMetric == .winRate {
                    y = height - CGFloat(point.winRate) * height
                } else {
                    let normalizedElo = Double(point.elo - minElo) / Double(eloRange)
                    y = height - CGFloat(normalizedElo) * height
                }
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(selectedMetric == .winRate ? Color.green : Color.blue, lineWidth: 2)
    }
    
    private func dataPoints(in geometry: GeometryProxy) -> some View {
        ForEach(0..<data.count, id: \.self) { i in
            dataPointCircle(for: i, in: geometry)
        }
    }
    
    private func dataPointCircle(for index: Int, in geometry: GeometryProxy) -> some View {
        let point = data[index]
        let position = calculatePosition(for: point, at: index, in: geometry)
        
        return Circle()
            .fill(selectedMetric == .winRate ? Color.green : Color.blue)
            .frame(width: 8, height: 8)
            .position(x: position.x, y: position.y)
            .onTapGesture {
                withAnimation {
                    selectedDataPoint = index
                }
            }
    }
    
    private func calculatePosition(for point: (date: Date, elo: Int, winRate: Double), at index: Int, in geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width - 10
        let height = geometry.size.height
        let stepX = width / CGFloat(data.count - 1)
        let x = stepX * CGFloat(index)
        
        // Calculate y based on ELO or win rate
        let y: CGFloat
        if selectedMetric == .winRate {
            y = height - CGFloat(point.winRate) * height
        } else {
            let normalizedElo = Double(point.elo - minElo) / Double(eloRange)
            y = height - CGFloat(normalizedElo) * height
        }
        
        return CGPoint(x: x, y: y)
    }
    
    private var xAxisLabels: some View {
        HStack(spacing: 0) {
            ForEach(data, id: \.date) { point in
                Group {
                    Text(dateFormatter.string(from: point.date))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    
                    if point.date != data.last?.date {
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleData = [
        (date: Date().addingTimeInterval(-24 * 60 * 60 * 28), elo: 1050, winRate: 0.45),
        (date: Date().addingTimeInterval(-24 * 60 * 60 * 21), elo: 1080, winRate: 0.48),
        (date: Date().addingTimeInterval(-24 * 60 * 60 * 14), elo: 1130, winRate: 0.52),
        (date: Date().addingTimeInterval(-24 * 60 * 60 * 7), elo: 1170, winRate: 0.56),
        (date: Date(), elo: 1200, winRate: 0.60)
    ]
    
    return PerformanceChartView(data: sampleData)
        .frame(height: 200)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding()
} 