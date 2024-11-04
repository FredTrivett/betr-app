import Foundation

struct DayBoundary {
    static let reflectionCutoffHour = 5 // 5 AM cutoff
    
    static func isWithinReflectionPeriod(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the given date
        let startOfDate = calendar.startOfDay(for: date)
        
        // Calculate the cutoff time (5 AM the next day)
        let cutoffDate = calendar.date(byAdding: .day, value: 1, to: startOfDate)!
        let cutoffTime = calendar.date(
            bySettingHour: reflectionCutoffHour,
            minute: 0,
            second: 0,
            of: cutoffDate
        )!
        
        // Check if current time is before the cutoff
        return now <= cutoffTime
    }
    
    static func getEffectiveDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // If it's before 5 AM, return yesterday's date
        if hour < reflectionCutoffHour {
            return calendar.date(byAdding: .day, value: -1, to: now)!
        }
        
        return now
    }
    
    static func canReflectOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Can reflect on today
        if calendar.isDate(normalizedDate, inSameDayAs: today) {
            return true
        }
        
        // Can reflect on yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(normalizedDate, inSameDayAs: yesterday) {
            return true
        }
        
        return false
    }
} 