import 'package:hive_ce/hive.dart';
import '../task_repository.dart';
import 'dart:developer';

class TaskLocalDatabase {
  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {
    return _box.values.map((item) {
      return Task.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();

    for (final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
  }
static Future<void> addTask (Task task) async {
    await _box.put(task.id, task.toMap());
    log("Dodano zadanie: ${task.title}", name: "TaskLocalDatabase");
}
static Future<void>  updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
    log("Edytowano lub zmieniono status zadania: ${task.title}, done: ${task.done}",
      name: "TaskLocalDatabase",);
}
static Future<void> deleteTask(int id) async {
    await _box.delete(id);
    log("Usunięto zadanie o id: $id", name: "TaskLocalDatabase");
}
static Future<void>  deleteAllTasks() async {
    await _box.clear();
    log("Usunięto wszystkie zadania", name: "TaskLocalDatabase");
}
static bool isEmpty() {
    return _box.isEmpty;
  }
}