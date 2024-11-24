import Foundation

/// Service for managing application-wide settings
struct AppSettings {
    /// UserDefaults instance for storing settings
    private static let defaults = UserDefaults.standard
    
    /// Key for storing installation date
    private static let installationDateKey = "com.FredericTRIVETT.betr.installationDate"
    
    /// The date when the app was first installed
    /// If not set, current date is used and stored
    static var installationDate: Date {
        get {
            if let date = defaults.object(forKey: installationDateKey) as? Date {
                return date
            }
            // Set initial installation date if not exists
            let date = Date()
            defaults.set(date, forKey: installationDateKey)
            return date
        }
    }
    
    /// Prevents initialization as this is a utility type
    private init() {}
} 