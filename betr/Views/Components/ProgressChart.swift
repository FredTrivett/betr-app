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
        // Add some padding to the range
        return (minValue - 1)...(maxValue + 1)
    }
    
    var body: some View {
        Chart {
            // Line connecting all points
            ForEach(data, id: \.date) { item in
                LineMark(
                    x: .value("Date", dateFormatter.string(from: item.date)),
                    y: .value("Progress", item.value)
                )
                .foregroundStyle(.gray)
            }
            
            // Dots only for days with reflections
            ForEach(data.filter { $0.hasReflection }, id: \.date) { item in
                PointMark(
                    x: .value("Date", dateFormatter.string(from: item.date)),
                    y: .value("Progress", item.value)
                )
                .foregroundStyle(getPointColor(for: item.rating))
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
    
    private func getPointColor(for rating: ReflectionRating?) -> Color {
        guard let rating = rating else { return .clear }
        switch rating {
        case .better: return .green
        case .same: return .orange
        case .worse: return .red
        }
    }
}

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
} 