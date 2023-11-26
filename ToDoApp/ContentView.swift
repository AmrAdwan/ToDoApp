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
    
    // Convert tasksData into an array of Task objects
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
            Text("My ToDo List")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.top)

            TextField("Enter new task", text: $newTaskDescription)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)

            Button(action: addTask) {
                Text("Add Task")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .background(Color.blue)
            .padding(.horizontal) // Apply padding to the button itself
            .cornerRadius(10)
            .shadow(radius: 2)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(tasks) { task in
                        taskRow(for: task)
                    }
                }
                .padding(.horizontal) // Apply padding to match other elements
            }
        }
        .padding(.horizontal)
    }
    
    func taskRow(for task: Task) -> some View {
        HStack {
            Text(task.description)
                .foregroundColor(task.isCompleted ? .gray : .black)
                .strikethrough(task.isCompleted)
            Spacer()
            Button(action: { toggleTaskCompletion(task.id) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            Button(action: { deleteTask(task) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(white: 0.98))
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    func addTask() {
        if !newTaskDescription.isEmpty {
            var updatedTasks = tasks
            updatedTasks.append(Task(description: newTaskDescription))
            saveTasks(updatedTasks)
            newTaskDescription = ""
        }
    }

    func deleteTask(_ taskToDelete: Task) {
        var updatedTasks = tasks
        updatedTasks.removeAll { $0.id == taskToDelete.id }
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
