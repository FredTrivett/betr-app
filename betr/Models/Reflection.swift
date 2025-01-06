import Foundation

struct Reflection: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    private(set) var content: String
    
    init(id: UUID = UUID(), date: Date = Date(), content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Reflection content cannot be empty")
        }
        
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
    
    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func updating(content newContent: String) -> Reflection {
        Reflection(id: id, date: date, content: newContent)
    }
}

// Extension for CustomDebugStringConvertible
extension Reflection: CustomDebugStringConvertible {
    var debugDescription: String {
        "Reflection(date: \(formattedDate), content: \(content))"
    }
} 