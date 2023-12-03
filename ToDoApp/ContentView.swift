//
//  ContentView.swift
//  ToDoApp
//
//  Created by Amr Adwan on 23/11/2023.
//

import SwiftUI
import UserNotifications

// Task Priority Enum
enum TaskPriority: String, Codable, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct Task: Identifiable, Codable {
    let id: UUID
    var description: String
    var isCompleted: Bool
    var priority: TaskPriority = .medium
    var dueDate: Date?
    
    init(id: UUID = UUID(), description: String, isCompleted: Bool = false, priority: TaskPriority = .medium, dueDate: Date? = nil) {
        self.id = id
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
    }
}

struct ContentView: View {
    @AppStorage("Tasks") private var tasksData: Data = Data()
    @State private var newTaskDescription: String = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var dueDate: Date?
    @State private var selectedFilter: TaskFilter = .all

    enum TaskFilter {
        case all, completed, incomplete
    }

    private var filteredTasks: [Task] {
        switch selectedFilter {
        case .all:
            return tasks
        case .completed:
            return tasks.filter { $0.isCompleted }
        case .incomplete:
            return tasks.filter { !$0.isCompleted }
        }
    }
    
    private var tasks: [Task] {
        get {
            (try? JSONDecoder().decode([Task].self, from: tasksData)) ?? []
        }
        set {
            tasksData = (try? JSONEncoder().encode(newValue)) ?? Data()
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

            Picker("Priority", selection: $selectedPriority) {
                ForEach(TaskPriority.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            DatePicker("Due Date", selection: Binding(
                get: { self.dueDate ?? Date() },
                set: { self.dueDate = $0 }
            ), displayedComponents: .date)
            .padding()

            Button(action: addTask) {
                Text("Add Task")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .background(Color.blue)
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding(.horizontal)

            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(TaskFilter.all)
                Text("Completed").tag(TaskFilter.completed)
                Text("Incomplete").tag(TaskFilter.incomplete)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(filteredTasks) { task in
                        taskRow(for: task)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                if success {
                    print("Authorization granted")
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func taskRow(for task: Task) -> some View {
        HStack {
            VStack(alignment: .leading) {
                    Text(task.description)
                        .foregroundColor(task.isCompleted ? .gray : .black)
                        .strikethrough(task.isCompleted)
                    if let dueDate = task.dueDate {
                        Text("Due: \(dueDate, formatter: DateFormatter.taskDateFormat)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
            }
            Spacer()
            Text(task.priority.rawValue)
                .font(.caption)
                .foregroundColor(.purple)
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

    // Method to add a new task
    func addTask() {
        if !newTaskDescription.isEmpty {
            var updatedTasks = tasks
            let newTask = Task(description: newTaskDescription, isCompleted: false, priority: selectedPriority, dueDate: dueDate)
            updatedTasks.append(newTask)
            tasksData = (try? JSONEncoder().encode(updatedTasks)) ?? Data()
            scheduleNotification(for: newTask) // Schedule notification
            newTaskDescription = ""
            dueDate = nil
        }
    }

    // Method to delete a task
    func deleteTask(_ taskToDelete: Task) {
        var updatedTasks = tasks
        updatedTasks.removeAll { $0.id == taskToDelete.id }
        tasksData = (try? JSONEncoder().encode(updatedTasks)) ?? Data()
    }

    func toggleTaskCompletion(_ taskId: UUID) {
        var updatedTasks = tasks
        if let index = updatedTasks.firstIndex(where: { $0.id == taskId }) {
            updatedTasks[index].isCompleted.toggle()
            tasksData = (try? JSONEncoder().encode(updatedTasks)) ?? Data()
        }
    }

    func scheduleNotification(for task: Task) {
        guard let dueDate = task.dueDate, !task.isCompleted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.description
        content.sound = UNNotificationSound.default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// Date formatter extension
extension DateFormatter {
    static let taskDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
