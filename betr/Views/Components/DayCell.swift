import SwiftUI

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date?
    let taskViewModel: TaskListViewModel
    
    private var isSelected: Bool {
        selectedDate.map { Calendar.current.isDate(date, inSameDayAs: $0) } ?? false
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
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
            
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(isFutureDate ? .secondary : .primary)
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
        
        if isSelected {
            return baseColor.opacity(baseColor == .clear ? 0.3 : 0.4)
        }
        
        return baseColor.opacity(baseColor == .clear ? 0 : 0.2)
    }
}

#Preview {
    DayCell(
        date: Date(),
        selectedDate: .constant(nil),
        taskViewModel: TaskListViewModel(),
        completionStatus: .full,
        isFutureDate: false,
        reflectionRating: nil
    )
} 