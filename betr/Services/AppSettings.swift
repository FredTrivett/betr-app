import Foundation

struct AppSettings {
    private static let defaults = UserDefaults.standard
    private static let installationDateKey = "com.FredericTRIVETT.betr.installationDate"
    
    static var installationDate: Date {
        get {
            if let date = defaults.object(forKey: installationDateKey) as? Date {
                return date
            } else {
                let date = Date()
                defaults.set(date, forKey: installationDateKey)
                return date
            }
        }
    }
} 