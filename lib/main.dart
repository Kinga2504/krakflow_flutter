import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'services/task_local_database.dart';
import 'services/task_sync_service.dart';
import 'dart:math';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const Ekran());
  }
}

class Ekran extends StatefulWidget {
  const Ekran({super.key});

  @override
  State<Ekran> createState() => _EkranState();
}

class _EkranState extends State<Ekran> {

  String selectedFilter = "wszystkie";

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
      todoTasksCount = tasks.where((task) => !task.done).length;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Potwierdzenie"),
                    content: Text(
                      "Czy na pewno chcesz usunąć wszystkie zadania?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await TaskLocalDatabase.deleteAllTasks();

                          if (!context.mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Usunięto wszystkie zadania"),
                            ),
                          );
                        },
                        child: Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Wszystkie: $allTasksCount | Wykonane: $doneTasksCount | Do zrobienia: $todoTasksCount",
          ),
          Expanded(
            child: TaskListScreen(
              onTasksLoaded: updateCounters,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddTaskScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final ValueChanged<List<Task>> onTasksLoaded;
  const TaskListScreen({
    super.key,
    required this.onTasksLoaded,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  Future<void> addTask(Task task) async {
    await TaskLocalDatabase.addTask(task);
      tasksFuture = loadTasks();
    }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Błąd: ${snapshot.error}"));
        }

        final tasks = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onTasksLoaded(tasks);
        });

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return Dismissible(
              key: ValueKey(task.id),
              onDismissed: (direction) async {
                await TaskLocalDatabase.deleteTask(task.id);

                setState(() {
                  tasksFuture = loadTasks();
                });
              },

              child: TaskCard(
                title: task.title,
                subtitle:
                    "termin: ${task.deadline} | priorytet: ${task.priority}",
                done: task.done,
                onChanged: (value) async {
                  final isDone = value ?? false;
                  final wasDone = task.done;

                  final updatedTask = Task(
                    id: task.id,
                    title: task.title,
                    deadline: task.deadline,
                    priority: task.priority,
                    done: isDone,
                  );
                  await TaskLocalDatabase.updateTask(updatedTask);

                  if (!wasDone && isDone) {
                    await NotificationService.showTaskDoneNotification(task.title);
                  }

                  setState(() {
                    tasksFuture = loadTasks();
                  });
                },
                onTap: () async {
                  final Task? updatedTask = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskScreen(task: task),
                    ),
                  );
                  if (updatedTask != null) {
                    await TaskLocalDatabase.updateTask(updatedTask);
                    setState(() {
                      tasksFuture = loadTasks();
                    });
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                  id: Random().nextInt(1000000),
                );

                Navigator.pop(context, newTask);
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  EditTaskScreen({super.key, required this.task});

  late final TextEditingController titleController = TextEditingController(
    text: task.title,
  );

  late final TextEditingController deadlineController = TextEditingController(
    text: task.deadline,
  );

  late final TextEditingController priorityController = TextEditingController(
    text: task.priority,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edycja zadania")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                  id: task.id,
                );

                Navigator.pop(context, updatedTask);
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: done, onChanged: onChanged),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: done ? Colors.grey : Colors.black),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
