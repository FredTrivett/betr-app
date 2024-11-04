import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let completionStatus: DayCompletionStatus
    let isFutureDate: Bool
    let reflectionRating: ReflectionRating?
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Circle()
                        .strokeBorder(isToday ? .blue : .clear, lineWidth: 2)
                )
            
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isFutureDate ? .secondary : .primary)
                
                if !isFutureDate {
                    completionIndicator
                }
            }
        }
        .opacity(isFutureDate ? 0.5 : 1.0)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var backgroundColor: Color {
        if isFutureDate {
            return .clear
        }
        if isSelected {
            return .blue.opacity(0.3)
        }
        if let rating = reflectionRating {
            switch rating {
            case .better:
                return .green.opacity(0.2)
            case .same:
                return .orange.opacity(0.2)
            case .worse:
                return .red.opacity(0.2)
            }
        }
        switch completionStatus {
        case .full:
            return .green.opacity(0.3)
        case .partial:
            return .yellow.opacity(0.3)
        case .none:
            return .clear
        }
    }
    
    private var completionIndicator: some View {
        Group {
            switch completionStatus {
            case .full:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 8))
            case .partial:
                Image(systemName: "circle.bottomhalf.filled")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 8))
            case .none:
                EmptyView()
            }
        }
    }
}

#Preview {
    DayCell(
        date: Date(),
        isSelected: true,
        isToday: true,
        completionStatus: .full,
        isFutureDate: false,
        reflectionRating: nil
    )
} 