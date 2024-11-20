import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ToDoListApp")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        checkAndLoadData()
    }

    private func checkAndLoadData() {
        DispatchQueue.global(qos: .background).async {
            let context = self.container.viewContext
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()

            do {
                let taskCount = try context.count(for: fetchRequest)
                if taskCount == 0 {
                    self.fetchDataFromAPI { success in
                        if success {
                            print("Данные успешно загружены с API и сохранены в Core Data.")
                        } else {
                            print("Ошибка при загрузке данных с API.")
                        }
                    }
                } else {
                    print("Данные уже существуют в Core Data, загрузка из API не требуется.")
                }
            } catch {
                print("Ошибка при проверке Core Data: \(error)")
            }
        }
    }

    private func fetchDataFromAPI(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://dummyjson.com/todos")!

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                completion(false)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(false)
                return
            }

            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(TodoResponse.self, from: data)

                self.saveTasks(apiResponse.todos)
                completion(true)
            } catch {
                print("Error decoding data: \(error)")
                completion(false)
            }
        }

        task.resume()
    }

    private func saveTasks(_ tasks: [Todo]) {
        DispatchQueue.global(qos: .background).async {
            let context = self.container.viewContext

            for task in tasks {
                let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", task.id)

                do {
                    let existingTasks = try context.fetch(fetchRequest)
                    if existingTasks.isEmpty {
                        // Если задача не существует, добавляем новую
                        let newTask = Task(context: context)
                        newTask.id = Int16(task.id)
                        newTask.title = task.todo
                        newTask.isCompleted = task.completed

                        newTask.createdDate = task.createdAt.flatMap { self.dateFromString($0) } ?? Date()

                        newTask.subtitle = task.description
                    }
                } catch {
                    print("Error checking for existing task: \(error)")
                }
            }

            self.saveContext()
        }
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: dateString)
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func fetchTasks(with searchQuery: String = "", completion: @escaping ([Task]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

            if !searchQuery.isEmpty {
                fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchQuery)
            }

            do {
                let tasks = try self.container.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(tasks)
                }
            } catch {
                print("Error fetching tasks: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }

    func saveTask(id: Int16? = nil, title: String, subtitle: String, createdDate: Date, isCompleted: Bool = false) {
        DispatchQueue.global(qos: .background).async {
            let context = self.container.viewContext

            if let taskId = id {
                let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", taskId)

                do {
                    let existingTasks = try context.fetch(fetchRequest)
                    if let existingTask = existingTasks.first {
                        existingTask.title = title
                        existingTask.subtitle = subtitle
                        existingTask.createdDate = createdDate
                        existingTask.isCompleted = isCompleted
                        self.saveContext()
                        return
                    }
                } catch {
                    print("Error fetching task for update: \(error)")
                }
            }

            let newTask = Task(context: context)

            if id == nil {
                let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
                do {
                    let tasks = try context.fetch(fetchRequest)
                    let maxId = (tasks.first?.id ?? 0) + 1
                    newTask.id = maxId
                } catch {
                    print("Error fetching tasks to determine max id: \(error)")
                    newTask.id = 1
                }
            } else {
                newTask.id = id!
            }

            newTask.title = title
            newTask.subtitle = subtitle
            newTask.createdDate = createdDate
            newTask.isCompleted = isCompleted

            self.saveContext()
        }
    }

    func deleteTask(_ task: Task) {
        DispatchQueue.global(qos: .background).async {
            let context = self.container.viewContext
            context.delete(task)
            self.saveContext()
        }
    }

    func toggleCompletion(for task: Task) {
        DispatchQueue.global(qos: .background).async {
            task.isCompleted.toggle()
            self.saveContext()
        }
    }
}
