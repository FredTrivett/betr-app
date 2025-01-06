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
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 1)
                    )
                
                Text(day.singleLetter)
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(isSelected ? .white : .blue)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
    }
} 