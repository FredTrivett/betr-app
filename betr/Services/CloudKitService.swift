import Foundation
import CloudKit

protocol CloudServiceProtocol {
    func saveTask(_ task: Task, completion: @escaping (Result<Task, Error>) -> Void)
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void)
    func deleteTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void)
    func saveReflection(_ reflection: DailyReflection, completion: @escaping (Result<DailyReflection, Error>) -> Void)
    func fetchReflections(completion: @escaping (Result<[DailyReflection], Error>) -> Void)
    func deleteReflection(_ reflection: DailyReflection, completion: @escaping (Result<Void, Error>) -> Void)
}

class CloudKitService: CloudServiceProtocol {
    private let privateDB: CKDatabase
    private let localStorage: TaskStorageProtocol
    private let container: CKContainer
    
    init(localStorage: TaskStorageProtocol = TaskStorage()) {
        self.localStorage = localStorage
        self.container = CKContainer(identifier: "iCloud.com.FredericTRIVETT.growvy")
        self.privateDB = container.privateCloudDatabase
        
        // Check iCloud status
        container.accountStatus { [weak self] status, error in
            if let error = error {
                print("❌ iCloud Error: \(error.localizedDescription)")
                return
            }
            
            switch status {
            case .available:
                print("✅ iCloud is available")
            case .noAccount:
                print("❌ No iCloud account")
            case .restricted:
                print("❌ iCloud restricted")
            case .couldNotDetermine:
                print("❌ Could not determine iCloud status")
            case .temporarilyUnavailable:
                print("⚠️ iCloud temporarily unavailable")
            @unknown default:
                print("❓ Unknown iCloud status")
            }
        }
    }
    
    // MARK: - Task Methods
    
    func saveTask(_ task: Task, completion: @escaping (Result<Task, Error>) -> Void) {
        print("\n=== CLOUDKIT OPERATION ===")
        print("📱 Attempting to save task: '\(task.title)'")
        
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        
        // First try to fetch existing record
        privateDB.fetch(withRecordID: recordID) { [weak self] existingRecord, error in
            guard let self = self else { return }
            
            let record: CKRecord
            if let existingRecord = existingRecord {
                // Update existing record
                record = existingRecord
            } else {
                // Create new record
                record = CKRecord(recordType: "Task", recordID: recordID)
            }
            
            // Update record fields
            record["taskID"] = task.id.uuidString as CKRecordValue
            record["taskTitle"] = task.title as CKRecordValue
            record["taskDescription"] = task.description as CKRecordValue
            record["isRecurring"] = task.isRecurring as CKRecordValue
            record["completedDates"] = task.completedDates.map { $0.timeIntervalSince1970 } as CKRecordValue
            record["excludedDates"] = task.excludedDates.map { $0.timeIntervalSince1970 } as CKRecordValue
            record["taskCreatedAt"] = task.creationDate.timeIntervalSince1970 as CKRecordValue
            record["taskModifiedAt"] = task.lastModifiedDate.timeIntervalSince1970 as CKRecordValue
            record["selectedDays"] = task.selectedDays.map { $0.rawValue } as CKRecordValue
            record["effectiveAt"] = task.effectiveDate.timeIntervalSince1970 as CKRecordValue
            
            if let originalTaskId = task.originalTaskId {
                record["originalTaskID"] = originalTaskId.uuidString as CKRecordValue
            }
            
            // Save the record
            self.privateDB.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit Error: \(error.localizedDescription)")
                        print("======================\n")
                        completion(.failure(error))
                    } else if let savedRecord = savedRecord {
                        print("✅ Successfully saved to CloudKit!")
                        print("======================\n")
                        completion(.success(task))
                    }
                }
            }
        }
    }
    
    private func fallbackToLocalStorage(_ task: Task, completion: @escaping (Result<Task, Error>) -> Void) {
        do {
            try self.localStorage.saveTasks([task])
            print("📝 Fallback: Saved to local storage")
            print("======================\n")
            completion(.success(task))
        } catch {
            print("💥 Error: Failed to save to local storage")
            print("======================\n")
            completion(.failure(error))
        }
    }
    
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void) {
        print("\n=== CLOUDKIT OPERATION ===")
        print("🔍 Fetching all tasks...")
        
        let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "taskModifiedAt", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["taskID", "taskTitle", "taskDescription", "isRecurring", 
                               "completedDates", "excludedDates", "taskCreatedAt", 
                               "taskModifiedAt", "selectedDays", "effectiveAt", "originalTaskID"]
        
        var fetchedRecords: [CKRecord] = []
        var fetchErrors: [Error] = []
        
        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
                print("📝 Found task: '\(record["taskTitle"] ?? "Unknown")'")
            case .failure(let error):
                fetchErrors.append(error)
                print("❌ Error fetching record: \(error)")
            }
        }
        
        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if !fetchErrors.isEmpty {
                        print("⚠️ Some records failed to fetch: \(fetchErrors.count) errors")
                    }
                    let tasks = fetchedRecords.compactMap { Task(record: $0) }
                    print("✅ Successfully fetched \(tasks.count) tasks")
                    print("======================\n")
                    completion(.success(tasks))
                case .failure(let error):
                    print("❌ Fetch failed: \(error.localizedDescription)")
                    print("======================\n")
                    completion(.failure(error))
                }
            }
        }
        
        privateDB.add(operation)
    }
    
    func deleteTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        print("\n=== CLOUDKIT OPERATION ===")
        print("🗑️ Deleting task: '\(task.title)'")
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        
        privateDB.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                print("❌ Delete failed: \(error.localizedDescription)")
                print("======================\n")
                completion(.failure(error))
            } else {
                print("✅ Successfully deleted task")
                print("======================\n")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Reflection Methods
    
    func saveReflection(_ reflection: DailyReflection, completion: @escaping (Result<DailyReflection, Error>) -> Void) {
        print("\n=== CLOUDKIT OPERATION ===")
        print("📝 Saving reflection for \(reflection.date.formatted(date: .abbreviated, time: .omitted))")
        
        let record = CKRecord(recordType: "DailyReflection", recordID: CKRecord.ID(recordName: reflection.id.uuidString))
        record["id"] = reflection.id.uuidString as CKRecordValue
        record["date"] = reflection.date.timeIntervalSince1970 as CKRecordValue
        record["rating"] = reflection.rating.rawValue as CKRecordValue
        record["tasksCompleted"] = reflection.tasksCompleted as CKRecordValue
        record["totalTasks"] = reflection.totalTasks as CKRecordValue
        
        privateDB.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit Error: \(error.localizedDescription)")
                    print("======================\n")
                    completion(.failure(error))
                } else if let savedRecord = savedRecord {
                    print("✅ Successfully saved reflection!")
                    print("======================\n")
                    completion(.success(reflection))
                }
            }
        }
    }
    
    func fetchReflections(completion: @escaping (Result<[DailyReflection], Error>) -> Void) {
        print("\n=== CLOUDKIT OPERATION ===")
        print("🔍 Fetching all reflections...")
        
        let query = CKQuery(recordType: "DailyReflection", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        var fetchedRecords: [CKRecord] = []
        
        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure(let error):
                print("Error fetching record: \(error)")
            }
        }
        
        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let reflections = fetchedRecords.compactMap { record -> DailyReflection? in
                        guard let id = record["id"] as? String,
                              let date = record["date"] as? TimeInterval,
                              let ratingString = record["rating"] as? String,
                              let rating = ReflectionRating(rawValue: ratingString),
                              let tasksCompleted = record["tasksCompleted"] as? Int,
                              let totalTasks = record["totalTasks"] as? Int else {
                            return nil
                        }
                        
                        return DailyReflection(
                            id: UUID(uuidString: id) ?? UUID(),
                            date: Date(timeIntervalSince1970: date),
                            rating: rating,
                            tasksCompleted: tasksCompleted,
                            totalTasks: totalTasks
                        )
                    }
                    
                    print("✅ Successfully fetched \(reflections.count) reflections")
                    print("======================\n")
                    completion(.success(reflections))
                case .failure(let error):
                    print("❌ Fetch failed: \(error.localizedDescription)")
                    print("======================\n")
                    completion(.failure(error))
                }
            }
        }
        
        privateDB.add(operation)
    }
    
    func deleteReflection(_ reflection: DailyReflection, completion: @escaping (Result<Void, Error>) -> Void) {
        print("\n=== CLOUDKIT OPERATION ===")
        print("🗑️ Deleting reflection from \(reflection.date.formatted(date: .abbreviated, time: .omitted))")
        
        let recordID = CKRecord.ID(recordName: reflection.id.uuidString)
        
        privateDB.delete(withRecordID: recordID) { _, error in
            if let error = error {
                print("❌ Delete failed: \(error.localizedDescription)")
                print("======================\n")
                completion(.failure(error))
            } else {
                print("✅ Successfully deleted reflection")
                print("======================\n")
                completion(.success(()))
            }
        }
    }
}

// MARK: - CKRecord Extensions

extension CKRecord {
    convenience init(task: Task) {
        self.init(recordType: "Task")
        self["taskID"] = task.id.uuidString as CKRecordValue
        self["taskTitle"] = task.title as CKRecordValue
        self["taskDescription"] = task.description as CKRecordValue
        self["isRecurring"] = task.isRecurring as CKRecordValue
        
        // Handle empty arrays
        if task.completedDates.isEmpty {
            self["completedDates"] = [] as NSArray
        } else {
            self["completedDates"] = task.completedDates.map { $0.timeIntervalSince1970 } as CKRecordValue
        }
        
        if task.excludedDates.isEmpty {
            self["excludedDates"] = [] as NSArray
        } else {
            self["excludedDates"] = task.excludedDates.map { $0.timeIntervalSince1970 } as CKRecordValue
        }
        
        if task.selectedDays.isEmpty {
            self["selectedDays"] = [] as NSArray
        } else {
            self["selectedDays"] = task.selectedDays.map { $0.rawValue } as CKRecordValue
        }
        
        self["taskCreatedAt"] = task.creationDate.timeIntervalSince1970 as CKRecordValue
        self["taskModifiedAt"] = task.lastModifiedDate.timeIntervalSince1970 as CKRecordValue
        self["originalTaskID"] = task.originalTaskId?.uuidString as? CKRecordValue
        self["effectiveAt"] = task.effectiveDate.timeIntervalSince1970 as CKRecordValue
    }
    
    convenience init(reflection: DailyReflection) {
        self.init(recordType: "DailyReflection")
        self["id"] = reflection.id.uuidString as CKRecordValue
        self["date"] = reflection.date.timeIntervalSince1970 as CKRecordValue
        self["rating"] = reflection.rating.rawValue as CKRecordValue
        self["tasksCompleted"] = reflection.tasksCompleted as CKRecordValue
        self["totalTasks"] = reflection.totalTasks as CKRecordValue
    }
}

extension Task {
    init?(record: CKRecord) {
        guard let id = record["taskID"] as? String,
              let title = record["taskTitle"] as? String,
              let description = record["taskDescription"] as? String,
              let isRecurring = record["isRecurring"] as? Bool,
              let completedDates = record["completedDates"] as? [TimeInterval],
              let excludedDates = record["excludedDates"] as? [TimeInterval],
              let creationDate = record["taskCreatedAt"] as? TimeInterval,
              let lastModifiedDate = record["taskModifiedAt"] as? TimeInterval,
              let selectedDays = record["selectedDays"] as? [Int],
              let effectiveDate = record["effectiveAt"] as? TimeInterval else {
            return nil
        }
        
        let originalTaskId = record["originalTaskID"] as? String
        
        self.init(
            id: UUID(uuidString: id)!,
            title: title,
            description: description,
            isRecurring: isRecurring,
            completedDates: completedDates.map { Date(timeIntervalSince1970: $0) },
            excludedDates: excludedDates.map { Date(timeIntervalSince1970: $0) },
            creationDate: Date(timeIntervalSince1970: creationDate),
            lastModifiedDate: Date(timeIntervalSince1970: lastModifiedDate),
            originalTaskId: originalTaskId != nil ? UUID(uuidString: originalTaskId!) : nil,
            selectedDays: selectedDays.compactMap { Weekday(rawValue: $0) },
            effectiveDate: Date(timeIntervalSince1970: effectiveDate)
        )
    }
}

extension DailyReflection {
    init?(record: CKRecord) {
        guard let id = record["id"] as? String,
              let date = record["date"] as? TimeInterval,
              let ratingString = record["rating"] as? String,
              let rating = ReflectionRating(rawValue: ratingString),
              let tasksCompleted = record["tasksCompleted"] as? Int,
              let totalTasks = record["totalTasks"] as? Int else {
            return nil
        }
        
        self.init(
            id: UUID(uuidString: id) ?? UUID(),
            date: Date(timeIntervalSince1970: date),
            rating: rating,
            tasksCompleted: tasksCompleted,
            totalTasks: totalTasks
        )
    }
}

// Create a mock service for previews
class MockCloudService: CloudServiceProtocol {
    func saveTask(_ task: Task, completion: @escaping (Result<Task, Error>) -> Void) {
        completion(.success(task))
    }
    
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void) {
        completion(.success([]))
    }
    
    func deleteTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    func saveReflection(_ reflection: DailyReflection, completion: @escaping (Result<DailyReflection, Error>) -> Void) {
        completion(.success(reflection))
    }
    
    func fetchReflections(completion: @escaping (Result<[DailyReflection], Error>) -> Void) {
        completion(.success([]))
    }
    
    func deleteReflection(_ reflection: DailyReflection, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}

enum CloudKitError: Error {
    case notAvailable
} 