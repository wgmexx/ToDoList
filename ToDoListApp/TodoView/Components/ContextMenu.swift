import SwiftUI

struct ContextMenu: View {
    @Binding var selectedTask: Task?
    @Binding var isEditTaskActive: Bool
    var shareTask: (Task) -> Void
    var deleteTask: (Task) -> Void
    var hideMenu: () -> Void
    
    var body: some View {
        VStack {
            Button(action: {
                isEditTaskActive = true
                hideMenu()
                
            }) {
                HStack {
                    Text("Редактировать")
                        .foregroundColor(.todoBlack)
                        .padding(.leading, 10)
                        .padding(.bottom, 5)
                    Spacer()
                    Image("todoEdit")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .padding(.trailing, 10)
                }
            }
            
            Divider()
            
            Button(action: {
                if let task = selectedTask {
                    shareTask(task)
                    hideMenu()
                }
            }) {
                HStack {
                    Text("Поделиться")
                        .foregroundColor(.todoBlack)
                        .padding(.leading, 10)
                        .padding(.vertical, 5)
                    Spacer()
                    Image("todoShare")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .padding(.trailing, 10)
                }
            }
            
            Divider()
            
            Button(action: {
                if let task = selectedTask {
                    deleteTask(task)
                    hideMenu()
                }
            }) {
                HStack {
                    Text("Удалить")
                        .foregroundColor(.todoRed)
                        .padding(.top, 5)
                        .padding(.leading, 10)
                    Spacer()
                    Image("todoTrash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .foregroundColor(.todoRed)
                        .padding(.trailing, 10)
                }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 5)
        .background(.todoContext)
        .font(.system(size: 17))
        .fontWeight(.regular)
        .frame(width: 280)
        .cornerRadius(10)
    }
}
