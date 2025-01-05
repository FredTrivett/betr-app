import SwiftUI

struct DayToggle: View {
    let day: Weekday
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.blue, lineWidth: 1)
                    )
                
                Text(day.singleLetter)
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .blue)
            }
            .frame(width: 36, height: 36)
        }
    }
} 