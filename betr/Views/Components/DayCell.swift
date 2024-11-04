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
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: 2)
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
    
    private var borderColor: Color {
        if !isToday {
            return .clear
        }
        
        if let rating = reflectionRating {
            return rating.color
        }
        
        return .blue
    }
    
    private var backgroundColor: Color {
        if isFutureDate {
            return .clear
        }
        
        let baseColor: Color
        if let rating = reflectionRating {
            baseColor = rating.color
        } else {
            switch completionStatus {
            case .full:
                baseColor = .green
            case .partial:
                baseColor = .yellow
            case .none:
                baseColor = .clear
            }
        }
        
        // If selected, return a darker version of the base color
        if isSelected {
            return baseColor.opacity(baseColor == .clear ? 0.3 : 0.4)  // Darker if selected
        }
        
        // Otherwise return the normal opacity
        return baseColor.opacity(baseColor == .clear ? 0 : 0.2)
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