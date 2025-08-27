import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

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
    print('\n');
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
        await deleteExpense(userId);
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
// Use 'q' as the query parameter
Future<void> searchExpenses(int userId) async {
  stdout.write('Item to search: ');
  final keyword = stdin.readLineSync()?.trim() ?? '';

  if (keyword.isEmpty) {
    print('Keyword cannot be empty');
    return;
  }

  // Use only one correct URL, with 'q' as the query parameter
  final url = Uri.parse(
    'http://localhost:8000/expenses/$userId/search',
  ).replace(queryParameters: {'q': keyword});

  try {
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is! List) {
        print('Unexpected response format');
        return;
      }

      int total = 0;
      for (var exp in data) {
        final id = exp['id'];
        final item = exp['item'];
        final paid = (exp['paid'] is int)
            ? exp['paid'] as int
            : int.tryParse('${exp['paid']}') ?? 0;

        final dateStr = '${exp['date']}';
        DateTime? dt = DateTime.tryParse(dateStr.replaceFirst(' ', 'T'));
        final shown = (dt != null) ? dt.toLocal().toString() : dateStr;

        print('$id. $item : ${paid}฿ : $shown');
        total += paid;
      }
      print('Total expenses matching "$keyword" = ${total}฿');
    } else if (res.statusCode == 404) {
      print('No item: $keyword');
    } else if (res.statusCode == 400) {
      print('Missing or invalid keyword.');
    } else {
      print('Error: ${res.statusCode} ${res.body}');
    }
  } catch (e) {
    print('Search failed: $e');
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

  final url = Uri.parse('http://localhost:8000/expenses');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'item': item, 'paid': paid, 'user_id': userId}),
  );

  if (response.statusCode == 201) {
    print('Inserted!');
  } else {
    print('Insert failed: ${response.statusCode} ${response.body}');
  }
}

// Fuction for Delete expense by id
Future<void> deleteExpense(int userId) async {
  print('===== Delete an item =====');
  stdout.write('Item id: ');
  final idStr = stdin.readLineSync()?.trim();
  final eid = int.tryParse(idStr ?? '');

  if (eid == null) {
    print('Invalid expense ID');
    return;
  }
  try {
    final url = Uri.parse('http://localhost:8000/expenses/$userId/$eid');
    final res = await http.delete(url);

    if (res.statusCode == 200 || res.statusCode == 204) {
      print('Deleted!');
    } else if (res.statusCode == 404) {
      print('No item: $eid');
    } else {
      print('Error: ${res.statusCode} ${res.body}');
    }
  } catch (e) {
    print('Delete failed: $e');
  }
}
