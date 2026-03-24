import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  List<Task> tasks = [
    Task(title: "Labolatorium 4", deadline: "jutro"),
    Task(title: "Projekt z metodologi", deadline: "dzisiaj"),
    Task(title: "Przeczytać książkę", deadline: "w tym tygodniu"),
    Task(title: "Zrobić zakupy", deadline: "w tym tygodniu")
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        child: Center(
          children: [
            Text("Dzisiejsze zadania"),
            style: TextStyle(
              fontSize:21,
              fontWeight.bold,
            ),
          ]
        appBar: AppBar(
            title: Text("KrakFlow")),

        body: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return Text(tasks[index].title);
          },
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;

  Task({required this.title, required this.deadline});
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
