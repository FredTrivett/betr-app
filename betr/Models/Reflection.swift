import Foundation

struct Reflection: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    
    init(id: UUID = UUID(), date: Date = Date(), content: String) {
        self.id = id
        self.date = date
        self.content = content
    }
}

// Extension for helper methods
extension Reflection {
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    static var empty: Reflection {
        Reflection(content: "")
    }
} 