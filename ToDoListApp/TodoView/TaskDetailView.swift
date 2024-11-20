import SwiftUI
import CoreData

struct TaskDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var task: Task?
    
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var createdDate: Date = Date()
    
    var body: some View {
        VStack {
            TextField("Enter task title", text: $title)
                .font(.system(size: 34))
                .foregroundColor(.todoWhite)
                .background(.todoBlack)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            
            Text("\(formattedDate(createdDate))")
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.todoStroke)
                .padding(.horizontal, 20)
            
            TextEditor(text: $subtitle)
                .font(.system(size: 16))
                .foregroundColor(.todoWhite)
                .background(.todoBlack)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.top, 10)
            
            Spacer()
        }
        .background(.todoBlack)
        .navigationTitle(task == nil ? "Add Task" : "Edit Task")
        .onAppear {
            if let task = task {
                title = task.title ?? ""
                subtitle = task.subtitle ?? ""
                createdDate = task.createdDate ?? Date()
            }
        }
        .onDisappear {
            saveTask()
        }
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
        }
    }
    
    private func saveTask() {
        guard !title.isEmpty else { return }
        
        PersistenceController.shared.saveTask(
            id: task?.id,
            title: title,
            subtitle: subtitle,
            createdDate: createdDate,
            isCompleted: task?.isCompleted ?? false 
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
}
