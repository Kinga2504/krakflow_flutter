import 'dart:convert';
import 'package:http/http.dart' as http;
import '../task_repository.dart';
import 'dart:developer';

class TaskApiService {

  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final url = Uri.parse("$baseUrl/todos");

    log("Adres zapytania: $url", name: "TaskApiService");

    final response = await http.get(url);

    log("Kod odpowiedzi HTTP: ${response.statusCode}", name: "TaskApiService");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      log("Liczba pobranych zadań: ${todos.length}", name: "TaskApiService");

      return todos.map((todo) {
        return Task(
          title: todo["todo"],
          deadline: "brak",
          done: todo["completed"],
          priority: "średni",
          id: todo["id"],
        );
      }).toList();
    } else {
      log(
        "Nie udało się pobrać zadań",
        name: "TaskApiService",
        error: response.statusCode,
      );
      throw Exception("Błąd pobierania danych");
    }
  }
}

