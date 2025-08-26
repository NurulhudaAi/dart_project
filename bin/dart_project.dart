import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show stdin, stdout;

void main() async {
  print('===== Login =====');
  // Get username and password
  stdout.write('Username: ');
  String? username = stdin.readLineSync()?.trim();
  stdout.write('Password: ');
  String? password = stdin.readLineSync()?.trim();
  // Check if username and password are not empty
  if (username == null ||
      password == null ||
      username.isEmpty ||
      password.isEmpty) {
    print('Incomplete input');
    return;
  }

  final body = {'username': username, 'password': password};
  //URL
  final url = Uri.parse('http://localhost:8000/login');
  final response = await http.post(url, body: body);

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    print(result);

    // Get userId from response
    final userId = result['userId'];
    final nameUser = result['username'] ?? username;
    if (userId != null) {
      await showTrackingApp(userId as int, nameUser as String);
    }
  } else if (response.statusCode == 401 || response.statusCode == 500) {
    final result = response.body;
    print(result);
  } else {
    print('Unknown error');
  }
}

// fuction Show Menu
Future<void> showTrackingApp(int userId, String username) async {
  while (true) {
    print('================== Expenses Tracking App ==================');
    print('Welcome $username');
    print('1. All expenses');
    print('2. Today\'s expenses');
    print('3. Exit');
    stdout.write('Choose... ');
    String? choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        await showAllExpenses(userId);
        break;
      case '2':
        await showTodayExpenses(userId);
        break;
      case '3':
        print('----- Bye -----');
        return;
      default:
        print('Invalid choice');
    }
  }
}

// Function to show all expenses
Future<void> showAllExpenses(int userId) async {
  final url = Uri.parse('http://localhost:8000/expenses/$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResult = json.decode(response.body) as List;

    int total = 0;
    print('---------------------- All expenses ----------------------');
    for (var exp in jsonResult) {
      final dt = DateTime.parse(exp["date"]);
      final dtaLocal = dt.toLocal();
      print(
        '${exp["id"]}. ${exp["item"]} : ${exp["paid"]}฿ : ${dtaLocal.toString()}',
      );
      total += exp['paid'] as int;
    }
    print('Total expenses = $total฿');
  } else if (response.statusCode == 404) {
    print('No expenses found.');
  } else {
    print('Error: ${response.statusCode}');
  }
}

// Function to show today's expenses
Future<void> showTodayExpenses(int userId) async {
  final url = Uri.parse('http://localhost:8000/expenses/$userId/today');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResult = jsonDecode(response.body) as List;

    int total = 0;
    print('---------------------- Today\'s expenses ----------------------');
    for (var exp in jsonResult) {
      final dt = DateTime.parse(exp["date"]);
      final dtaLocal = dt.toLocal();
      print(
        '${exp["id"]}. ${exp["item"]} : ${exp["paid"]}฿ : ${dtaLocal.toString()}',
      );
      total += exp['paid'] as int;
    }
    print('Total expenses = $total฿');
  } else if (response.statusCode == 404) {
    print('No expenses found for today.');
  } else {
    print('Error: ${response.statusCode}');
  }
}

// function for Search expenses by keyword
Future<void> searchExpenses(int userId) async {
  stdout.write('Enter keyword to search: ');
  String? keyword = stdin.readLineSync()?.trim();

  if (keyword == null || keyword.isEmpty) {
    print('Keyword cannot be empty');
    return;
  }

  final url = Uri.parse('http://localhost:8000/expenses/$userId/search?keyword=$keyword');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResult = jsonDecode(response.body) as List;

    if (jsonResult.isEmpty) {
      print('No expenses found matching the keyword "$keyword".');
      return;
    }

    int total = 0;
    print('---------------------- Search results for "$keyword" ----------------------');
    for (var exp in jsonResult) {
      final dt = DateTime.parse(exp["date"]);
      final dtaLocal = dt.toLocal();
      print(
        '${exp["id"]}. ${exp["item"]} : ${exp["paid"]}฿ : ${dtaLocal.toString()}',
      );
      total += exp['paid'] as int;
    }
    print('Total expenses matching "$keyword" = $total฿');
  } else if (response.statusCode == 404) {
    print('No expenses found matching the keyword "$keyword".');
  } else {
    print('Error: ${response.statusCode}');
  }
}




















// function for Add new expense





















// Fuction for Delte expense by id