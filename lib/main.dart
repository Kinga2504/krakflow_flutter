import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  List<Task> tasks = [
    Task(title: "Labolatorium 4", deadline: "jutro", done: true, priority: "wysoki"),
    Task(title: "Projekt z metodologi", deadline: "dzisiaj", done: false, priority: "średni"),
    Task(title: "Przeczytać książkę", deadline: "w tym tygodniu", done: false, priority: "niski"),
    Task(title: "Zrobić zakupy", deadline: "w tym tygodniu", done: true, priority: "niski"),
  ];

  @override
  Widget build(BuildContext context) {

    int doneCount = tasks.where((task) => task.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("KrakFlow")
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Masz dziś ${tasks.length} zadania (${doneCount} wykonanych)"),
            SizedBox(height: 16),
            Text("Dzisiejsze zadania"),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(
                    title: tasks[index].title,
                    subtitle: "termin: ${tasks[index].deadline} | priorytet: ${tasks[index].priority}",
                    icon: tasks[index].done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

