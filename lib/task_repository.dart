class TaskRepository {
  static List<Task> tasks = [
    Task(title: "Labolatorium 4", deadline: "jutro", done: true, priority: "wysoki"),
    Task(title: "Projekt z metodologi", deadline: "dzisiaj", done: false, priority: "średni"),
    Task(title: "Przeczytać książkę", deadline: "w tym tygodniu", done: false, priority: "niski"),
    Task(title: "Zrobić zakupy", deadline: "w tym tygodniu", done: true, priority: "niski"),
  ];
}

class Task {
  final String title;
  final String deadline;
  bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}