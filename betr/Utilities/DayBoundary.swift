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
        let effectiveDate = getEffectiveDate()
        
        // Can reflect on the effective date
        if calendar.isDate(date, inSameDayAs: effectiveDate) {
            return true
        }
        
        // If it's before 5 AM, can also reflect on yesterday
        let hour = calendar.component(.hour, from: Date())
        if hour < reflectionCutoffHour {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: effectiveDate)!
            return calendar.isDate(date, inSameDayAs: yesterday)
        }
        
        return false
    }
} 