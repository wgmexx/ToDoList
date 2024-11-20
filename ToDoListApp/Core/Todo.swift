
    struct TodoResponse: Codable {
        var todos: [Todo]
        var total: Int
        var skip: Int
        var limit: Int
    }

    struct Todo: Codable {
        var id: Int
        var todo: String
        var completed: Bool
        var userId: Int
        var description: String?
        var createdAt: String?
    }
