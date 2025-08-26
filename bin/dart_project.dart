import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
const String API_BASE = 'http://localhost:8000';

const String API_BASE = 'http://localhost:8000';

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
    print('1. All expense');
    print('2. Today\'s expense');
    print('3. Search expense');
    print('4. Add new expense');
    print('5. Delete an expense');
    print('6. Exit');
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
        await searchExpenses(userId);
        break;
      case '4':
        await addExpense(userId);
        break;
      case '5':
        stdout.write('Enter expense ID to delete: ');
        String? idStr = stdin.readLineSync()?.trim();
        int? expenseId = int.tryParse(idStr ?? '');
        if (expenseId == null) {
          print('Invalid expense ID');
          break;
        }
        await deleteExpenseById(userId, expenseId);
        break;
      case '6':
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

  final url = Uri.parse(
    'http://localhost:8000/expenses/$userId/search?keyword=$keyword',
  );
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResult = jsonDecode(response.body) as List;

    if (jsonResult.isEmpty) {
      print('No expenses found matching the keyword "$keyword".');
      return;
    }

    int total = 0;
    print(
      '---------------------- Search results for "$keyword" ----------------------',
    );
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
Future<void> addExpense(int userId) async {
  print('===== Add new item =====');
  stdout.write('Item: ');
  final item = (stdin.readLineSync() ?? '').trim();
  stdout.write('Paid: ');
  final paidStr = (stdin.readLineSync() ?? '').trim();
  final paid = int.tryParse(paidStr) ?? -1;

  if (item.isEmpty || paid < 0) {
    print('Invalid input');
    return;
  }

  final url = Uri.parse('$API_BASE/expenses'); 

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'item': item, 'paid': paid, 'user_id': userId}),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    print('Inserted!');
  } else {
    print('Insert failed: ${response.statusCode} ${response.body}');
  }
}

// Fuction for Delte expense by id
Future<bool> deleteExpenseById(int userId, int expenseId) async {
  try {
    final url = Uri.parse('$API_BASE/expenses/$userId/$expenseId');

    final res = await http.delete(url);
    if (res.statusCode == 200 || res.statusCode == 204) return true;
    if (res.statusCode == 404) { print('No expense with id $expenseId'); return false; }
    print('Error: ${res.statusCode} ${res.body}');
    return false;
  } catch (e) { print('Delete failed: $e'); return false; }
}

