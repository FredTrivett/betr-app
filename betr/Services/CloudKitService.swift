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
    
    init(localStorage: TaskStorageProtocol = TaskStorage()) {
        self.localStorage = localStorage
        let container = CKContainer(identifier: "iCloud.com.FredericTRIVETT.growvy")
        self.privateDB = container.privateCloudDatabase
    }
    
    // MARK: - Task Methods
    
    func saveTask(_ task: Task, completion: @escaping (Result<Task, Error>) -> Void) {
        let record = CKRecord(task: task)
        
        privateDB.save(record) { [weak self] savedRecord, error in
            if let error = error {
                // Fallback to local storage on CloudKit error
                do {
                    try self?.localStorage.saveTasks([task])
                    completion(.success(task))
                } catch {
                    completion(.failure(error))
                }
            } else if let savedRecord = savedRecord,
                      let task = Task(record: savedRecord) {
                completion(.success(task))
            }
        }
    }
    
    func fetchTasks(completion: @escaping (Result<[Task], Error>) -> Void) {
        let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
        
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
            switch result {
            case .success:
                let tasks = fetchedRecords.compactMap { Task(record: $0) }
                completion(.success(tasks))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        privateDB.add(operation)
    }
    
    func deleteTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        
        privateDB.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Reflection Methods
    
    func saveReflection(_ reflection: DailyReflection, completion: @escaping (Result<DailyReflection, Error>) -> Void) {
        let record = CKRecord(reflection: reflection)
        
        privateDB.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord,
                      let reflection = DailyReflection(record: savedRecord) {
                completion(.success(reflection))
            }
        }
    }
    
    func fetchReflections(completion: @escaping (Result<[DailyReflection], Error>) -> Void) {
        let query = CKQuery(recordType: "DailyReflection", predicate: NSPredicate(value: true))
        
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
            switch result {
            case .success:
                let reflections = fetchedRecords.compactMap { DailyReflection(record: $0) }
                completion(.success(reflections))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        privateDB.add(operation)
    }
    
    func deleteReflection(_ reflection: DailyReflection, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: reflection.id.uuidString)
        
        privateDB.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: - CKRecord Extensions

extension CKRecord {
    convenience init(task: Task) {
        self.init(recordType: "Task")
        self["id"] = task.id.uuidString as CKRecordValue
        self["title"] = task.title as CKRecordValue
        self["description"] = task.description as CKRecordValue
        self["isRecurring"] = task.isRecurring as CKRecordValue
        self["completedDates"] = task.completedDates.map { $0.timeIntervalSince1970 } as CKRecordValue
        self["excludedDates"] = task.excludedDates.map { $0.timeIntervalSince1970 } as CKRecordValue
        self["creationDate"] = task.creationDate.timeIntervalSince1970 as CKRecordValue
        self["lastModifiedDate"] = task.lastModifiedDate.timeIntervalSince1970 as CKRecordValue
        self["originalTaskId"] = task.originalTaskId?.uuidString as? CKRecordValue
        self["selectedDays"] = task.selectedDays.map { $0.rawValue } as CKRecordValue
        self["effectiveDate"] = task.effectiveDate.timeIntervalSince1970 as CKRecordValue
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
        guard let id = record["id"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let isRecurring = record["isRecurring"] as? Bool,
              let completedDates = record["completedDates"] as? [TimeInterval],
              let excludedDates = record["excludedDates"] as? [TimeInterval],
              let creationDate = record["creationDate"] as? TimeInterval,
              let lastModifiedDate = record["lastModifiedDate"] as? TimeInterval,
              let selectedDays = record["selectedDays"] as? [Int],
              let effectiveDate = record["effectiveDate"] as? TimeInterval else {
            return nil
        }
        
        let originalTaskId = record["originalTaskId"] as? String
        
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
            id: UUID(uuidString: id)!,
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