import XCTest
import CoreData
@testable import ToDoListApp

class PersistenceControllerTests: XCTestCase {

    var persistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        
        persistenceController = PersistenceController(inMemory: true)
        mockContext = persistenceController.container.viewContext
    }

    override func tearDown() {
        persistenceController = nil
        mockContext = nil
        super.tearDown()
    }

    func testSaveTask() {
        let title = "Test Task"
        let subtitle = "Test subtitle"
        let createdDate = Date()

        persistenceController.saveTask(title: title, subtitle: subtitle, createdDate: createdDate)

        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try? mockContext.fetch(fetchRequest)

        XCTAssertNotNil(tasks)
        XCTAssertEqual(tasks?.count, 1)
        XCTAssertEqual(tasks?.first?.title, title)
        XCTAssertEqual(tasks?.first?.subtitle, subtitle)
        XCTAssertEqual(tasks?.first?.createdDate, createdDate)
    }

    func testFetchTasks() {
        let task1 = Task(context: mockContext)
        task1.title = "Task 1"
        task1.subtitle = "Subtitle 1"
        task1.createdDate = Date()

        let task2 = Task(context: mockContext)
        task2.title = "Task 2"
        task2.subtitle = "Subtitle 2"
        task2.createdDate = Date()

        try? mockContext.save()

        persistenceController.fetchTasks { tasks in
            XCTAssertEqual(tasks.count, 2)
            XCTAssertEqual(tasks.first?.title, "Task 1")
        }
    }

    func testDeleteTask() {
        let task = Task(context: mockContext)
        task.title = "Task to delete"
        task.subtitle = "Subtitle"
        task.createdDate = Date()

        try? mockContext.save()

        persistenceController.deleteTask(task)

        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try? mockContext.fetch(fetchRequest)

        XCTAssertNotNil(tasks)
        XCTAssertTrue(tasks?.isEmpty ?? false)
    }

    func testToggleCompletion() {
        let task = Task(context: mockContext)
        task.title = "Task to toggle"
        task.subtitle = "Subtitle"
        task.createdDate = Date()
        task.isCompleted = false

        try? mockContext.save()

        persistenceController.toggleCompletion(for: task)

        XCTAssertTrue(task.isCompleted)
    }
}
