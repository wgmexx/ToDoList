import SwiftUI
import Speech

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.createdDate, ascending: false)],
        animation: .default
    ) private var tasks: FetchedResults<Task>
    
    @State private var searchQuery = ""
    @State private var selectedTask: Task? = nil
    @State private var showingCustomMenu = false
    @State private var blurBackground = false
    @State private var isEditTaskActive = false
    @State private var taskPosition: CGRect = .zero
    
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("Задачи")
                        .padding(.top, 20)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.todoWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                    
                    SearchBar(text: $searchQuery)
                        .padding(.horizontal, 10)
                    
                    ScrollView {
                        ForEach(tasks.filter { task in
                            searchQuery.isEmpty || task.title?.lowercased().contains(searchQuery.lowercased()) ?? false
                        }) { task in
                            HStack(alignment: .top) {
                                Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                                    .foregroundColor(task.isCompleted ? .todoYellow : .todoStroke)
                                    .font(.title)
                                    .onTapGesture {
                                        toggleCompletion(task)
                                    }
                                
                                VStack(alignment: .leading) {
                                    Text(task.title ?? "Untitled")
                                        .font(.system(size: 16))
                                        .strikethrough(task.isCompleted, color: .todoStroke)
                                        .foregroundColor(task.isCompleted ? .todoStroke : .todoWhite)
                                    
                                    Text(task.subtitle ?? "")
                                        .font(.system(size: 12))
                                        .foregroundColor(task.isCompleted ? .todoStroke : .todoWhite)
                                        .lineLimit(2)
                                        .padding(.top, 2)
                                    
                                    if let createdDate = task.createdDate {
                                        Text("\(formattedDate(createdDate))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.todoStroke)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedTask == task && showingCustomMenu ? Color.todoGray : Color.clear
                            )
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                            .onTapGesture { _ in
                                        selectedTask = task
                                        taskPosition = calculateTaskPosition(for: task)
                                        blurBackground = true
                                        showingCustomMenu.toggle()
                                    }
                            
                            .zIndex(selectedTask == task ? 1 : 0)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .scrollContentBackground(.hidden)
                    .background(.todoBlack)
                    .accentColor(.todoYellow)
                    
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22))
                            .foregroundColor(.clear)
                            .frame(width: 68, height: 44)
                        
                        
                        Text(tasks.count == 1 ? String(format: NSLocalizedString("task.count.one", comment: ""), tasks.count) :
                             (tasks.count % 10 == 1 && tasks.count % 100 != 11) ? String(format: NSLocalizedString("task.count.one", comment: ""), tasks.count) :
                             (tasks.count % 10 >= 2 && tasks.count % 10 <= 4 && !(tasks.count % 100 >= 10 && tasks.count % 100 <= 20)) ? String(format: NSLocalizedString("task.count.few", comment: ""), tasks.count) :
                             String(format: NSLocalizedString("task.count.many", comment: ""), tasks.count))
                        
                        .font(.system(size: 11))
                        .foregroundColor(.todoWhite)
                        .frame(maxWidth: .infinity)
                        
                        NavigationLink(destination: TaskDetailView(task: $selectedTask)) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 22))
                                .foregroundColor(.todoYellow)
                                .frame(width: 68, height: 44)
                        }
                    }
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity)
                    .background(.todoGray)
                }
                .background(.todoBlack)
                .navigationBarTitleDisplayMode(.inline)
                
                if blurBackground {
                    BlurView(style: .systemMaterialDark)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingCustomMenu = false
                            blurBackground = false
                            selectedTask = nil
                        }
                }
                
                if let selectedTask = selectedTask {
                    VStack {
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(selectedTask.title ?? "Untitled")
                                    .font(.system(size: 16))
                                    .strikethrough(selectedTask.isCompleted, color: .todoStroke)
                                    .foregroundColor(selectedTask.isCompleted ? .todoStroke : .todoWhite)
                                
                                Text(selectedTask.subtitle ?? "")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTask.isCompleted ? .todoStroke : .todoWhite)
                                    .lineLimit(2)
                                    .padding(.top, 2)
                                
                                if let createdDate = selectedTask.createdDate {
                                    Text("\(formattedDate(createdDate))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.todoStroke)
                                        .padding(.top, 2)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(.todoGray)
                        .cornerRadius(12)
                        .position(x: (UIScreen.main.bounds.width / 2) - 15, y: UIScreen.main.bounds.height / 2.3)
                    }
                    .padding(.horizontal, 15)
                }
                
                if showingCustomMenu && selectedTask != nil {
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            
                            ContextMenu(
                                selectedTask: $selectedTask,
                                isEditTaskActive: $isEditTaskActive,
                                shareTask: shareTask,
                                deleteTask: deleteTask,
                                hideMenu: {
                                    showingCustomMenu = false
                                    blurBackground = false
                                }
                                
                            )
                            
                            .transition(.move(edge: .bottom))
                            .zIndex(1)
                            .frame(width: 280)
                            .background(.todoGray)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal, 10)
                            .position(
                                x: geometry.size.width / 2,
                                y: UIScreen.main.bounds.height - 295
                            )
                        }
                        
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .background {
                if selectedTask != nil {
                    NavigationLink(
                        destination: TaskDetailView(task: $selectedTask)
                            .onDisappear{
                                selectedTask = nil
                            },
                        isActive: $isEditTaskActive,
                        label: { EmptyView() }
                    )
                    .hidden()
                }
                
                
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
        .accentColor(.todoYellow)
    }
    
    private func calculateTaskPosition(for task: Task) -> CGRect {
        return CGRect.zero
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach { task in
                PersistenceController.shared.deleteTask(task)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTask = nil
                }
            }
        }
    }
    
    private func deleteTask(_ task: Task) {
        PersistenceController.shared.deleteTask(task)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectedTask = nil
        }
    }
    
    private func toggleCompletion(_ task: Task) {
        PersistenceController.shared.toggleCompletion(for: task)
        
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
    
    private func shareTask(_ task: Task) {
        let activityController = UIActivityViewController(activityItems: [task.title ?? "No Title", task.subtitle ?? "No Description"], applicationActivities: nil)
        
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(activityController, animated: true, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTask = nil
                }
            })
        }
    }
    
}
