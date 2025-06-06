import SwiftUI
import Charts

struct PerformanceChartView: View {
    let data: [PerformanceData]
    let selectedMetric: PerformanceMetric
    
    enum PerformanceMetric: String, CaseIterable {
        case elo = "ELO"
        case winRate = "Win Rate"
        case matches = "Matches"
    }
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(selectedMetric.rawValue, value(for: point))
                )
                .foregroundStyle(selectedMetric.color)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value(selectedMetric.rawValue, value(for: point))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatValue(doubleValue))
                    }
                }
            }
        }
        .frame(height: 200)
        .padding(.vertical)
    }
    
    private func value(for point: PerformanceData) -> Double {
        switch selectedMetric {
        case .elo:
            return Double(point.elo)
        case .winRate:
            return point.winRate * 100
        case .matches:
            return Double(point.matches)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .elo:
            return "\(Int(value))"
        case .winRate:
            return "\(Int(value))%"
        case .matches:
            return "\(Int(value))"
        }
    }
}

extension PerformanceChartView.PerformanceMetric {
    var color: Color {
        switch self {
        case .elo:
            return .blue
        case .winRate:
            return .green
        case .matches:
            return .purple
        }
    }
}

#Preview {
    PerformanceChartView(
        data: PerformanceData.generateSampleData(),
        selectedMetric: .elo
    )
    .padding()
} 