//
//  ContentView.swift
//  ToDoApp
//
//  Created by Amr Adwan on 23/11/2023.
//

import SwiftUI

struct Task: Identifiable, Codable {
    let id: UUID
    var description: String
    var isCompleted: Bool

    init(id: UUID = UUID(), description: String, isCompleted: Bool = false) {
        self.id = id
        self.description = description
        self.isCompleted = isCompleted
    }
}

struct ContentView: View {
    @AppStorage("Tasks") private var tasksData: String = ""
    @State private var newTaskDescription: String = ""

    private var tasks: [Task] {
        get {
            (try? JSONDecoder().decode([Task].self, from: Data(tasksData.utf8))) ?? []
        }
        set {
            tasksData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? ""
        }
    }
    
    var body: some View {
        VStack {
            TextField("Enter new task", text: $newTaskDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Add Task") {
                addTask()
            }
            .padding()

            List {
                ForEach(tasks) { task in
                    HStack {
                        Text(task.description)
                            .strikethrough(task.isCompleted, color: .gray)
                        Spacer()
                        Button(action: {
                            toggleTaskCompletion(task.id)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                        }
                    }
                }
                .onDelete(perform: deleteTask)
            }
        }
    }

    func addTask() {
        if !newTaskDescription.isEmpty {
            var updatedTasks = tasks
            updatedTasks.append(Task(description: newTaskDescription))
            saveTasks(updatedTasks)
            newTaskDescription = ""
        }
    }


    func deleteTask(at offsets: IndexSet) {
        var updatedTasks = tasks
        updatedTasks.remove(atOffsets: offsets)
        saveTasks(updatedTasks)
    }


    func toggleTaskCompletion(_ taskId: UUID) {
        var updatedTasks = tasks
        if let index = updatedTasks.firstIndex(where: { $0.id == taskId }) {
            updatedTasks[index].isCompleted.toggle()
            saveTasks(updatedTasks)
        }
    }


    func saveTasks(_ tasks: [Task]) {
        tasksData = (try? String(data: JSONEncoder().encode(tasks), encoding: .utf8)) ?? ""
    }


    func loadTasks() {
        if let savedTasks = UserDefaults.standard.object(forKey: "Tasks") as? [String] {
            // Update tasksData directly
            tasksData = (try? String(data: JSONEncoder().encode(savedTasks), encoding: .utf8)) ?? ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
