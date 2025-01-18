import SwiftUI
import Charts

struct ProgressChart: View {
    let data: [(date: Date, value: Int, hasReflection: Bool, rating: ReflectionRating?)]
    let timeFrame: TimeFrame
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch timeFrame {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "MMM d"
        }
        return formatter
    }
    
    private var yAxisRange: ClosedRange<Int> {
        let values = data.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        return (minValue - 1)...(maxValue + 1)
    }
    
    var body: some View {
        Chart(data, id: \.date) { item in
            // Main line
            LineMark(
                x: .value("Date", dateFormatter.string(from: item.date)),
                y: .value("Progress", item.value)
            )
            .foregroundStyle(item.rating?.color ?? .gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
            
            // Dots for days with reflections
            if item.hasReflection {
                PointMark(
                    x: .value("Date", dateFormatter.string(from: item.date)),
                    y: .value("Progress", item.value)
                )
                .foregroundStyle(item.rating?.color ?? .gray.opacity(0.3))
                .symbolSize(50)
            }
        }
        .chartYScale(domain: yAxisRange)
        .chartYAxis {
            AxisMarks { value in
                if let intValue = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(intValue)")
                    }
                }
            }
        }
        .frame(height: 200)
        .padding()
    }
}

// Helper extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 