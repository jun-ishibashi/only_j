import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gsheets/gsheets.dart';
import 'dart:io';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), // Changed to indigo
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  int _selectedIndex = 0;
  late List<Widget> _screens;
  int _nextId = 1; // Initialize the ID counter

  void _addExpense(Expense expense) {
    expense.id = _nextId.toString(); // Assign a unique incrementing ID as a string
    _nextId++;
    _expenses.add(expense);
    print('Expense added: ${expense.toJson()}'); // デバッグログを追加

    // 最新のデータを反映するために_screensを再構築
    setState(() {
      _screens = [
        HomeTab(expenses: _expenses),
        ExpenseListScreen(expenses: _expenses, onDeleteExpense: deleteExpense),
        ExpenseInputScreen(onAddExpense: _addExpense),
        ExpenseSummaryScreen(expenses: _expenses),
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(expenses: _expenses),
      ExpenseListScreen(
        expenses: _expenses,
        onDeleteExpense: deleteExpense, // Pass the deleteExpense method
      ),
      ExpenseInputScreen(onAddExpense: _addExpense),
      ExpenseSummaryScreen(expenses: _expenses),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void deleteExpense(String expenseId) {
    print('Attempting to delete expense with ID: $expenseId'); // Debugging statement
    setState(() {
      _expenses.removeWhere((expense) => expense.id == expenseId);
      print('Updated expenses list:'); // Debugging statement
      for (var expense in _expenses) {
        print(expense.toJson()); // Debugging statement
      }
    });

    markExpenseAsDeleted(expenseId).then((_) {
      print('Expense marked as deleted in Google Sheets: $expenseId');
    }).catchError((error) {
      print('Failed to mark expense as deleted: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(
          Icons.account_balance_wallet, // Temporary logo icon
          size: 40,
          color: Colors.white,
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Summary',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.indigo,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        selectedIconTheme: IconThemeData(size: 30),
        unselectedIconTheme: IconThemeData(size: 24),
      ), // Closing the BottomNavigationBar
    ); // Closing the Scaffold
  }
}

class ExpenseInputScreen extends StatefulWidget {
  final Function(Expense) onAddExpense;

  ExpenseInputScreen({required this.onAddExpense});

  @override
  _ExpenseInputScreenState createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  final _titleController = TextEditingController(); // 新しいコントローラー
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  String _selectedCurrency = 'JPY';

  // Move _categoryIcons to the class level for proper scope
  final Map<String, IconData> _categoryIcons = {
    'Grocery Shopping': Icons.shopping_cart,
    'Dining Out': Icons.restaurant,
    'Tobacco': Icons.smoking_rooms,
    'Transport': Icons.directions_car,
    'Entertainment': Icons.movie,
    'Rent': Icons.home,
    'Daily Essentials': Icons.shopping_bag,
  };

  // Show a success popup when an expense is added
  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredTitle.isEmpty || enteredAmount == null || _selectedDate == null) {
      return;
    }

    final newExpense = Expense(
      id: DateTime.now().toString(), // 一意の識別子を追加
      title: enteredTitle, // 新しいフィールド
      category: _selectedCategory,
      amount: enteredAmount,
      date: _selectedDate!,
      note: _noteController.text,
      currency: _selectedCurrency,
    );

    widget.onAddExpense(newExpense);

    // Show success popup
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Success'),
        content: Text('Expense added successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate to HOME screen
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
              homeScreenState?._onItemTapped(0);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );

    // 入力フィールドをクリア
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = 'Food';
      _selectedCurrency = 'JPY';
    });

    // Close the keyboard
    FocusScope.of(context).unfocus();

    // Export to Google Sheets
    exportExpenseToSheet(newExpense).then((_) {
      print('Expense exported to Google Sheets: ${newExpense.toJson()}');
    }).catchError((error) {
      print('Failed to export expense: $error');
    });
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController, // 新しいフィールド
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              // Replace the DropdownButtonFormField for category selection with an icon-based selection

              // Add a row of selectable icons for categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _categoryIcons.entries.map((entry) {
                    final category = entry.key;
                    final icon = entry.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        width: 60, // Button width
                        height: 60, // Button height
                        margin: EdgeInsets.symmetric(horizontal: 8), // Add spacing between items
                        decoration: BoxDecoration(
                          color: _selectedCategory == category ? Colors.indigo.shade100 : Colors.grey.shade200,
                          border: Border.all(
                            color: _selectedCategory == category ? Colors.indigo : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              icon,
                              color: _selectedCategory == category ? Colors.indigo : Colors.grey,
                              size: 30, // Icon size
                            ),
                            Positioned(
                              bottom: 2, // Adjust text position
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 7, // Text size
                                  color: _selectedCategory == category ? Colors.indigo : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 10),
              // Replace the DropdownButtonFormField for currency selection with buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = 'JPY';
                        });
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selectedCurrency == 'JPY' ? Colors.indigo.shade100 : Colors.grey.shade200,
                          border: Border.all(
                            color: _selectedCurrency == 'JPY' ? Colors.indigo : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'JPY',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCurrency == 'JPY' ? Colors.indigo : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = 'AUD';
                        });
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selectedCurrency == 'AUD' ? Colors.indigo.shade100 : Colors.grey.shade200,
                          border: Border.all(
                            color: _selectedCurrency == 'AUD' ? Colors.indigo : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'AUD',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCurrency == 'AUD' ? Colors.indigo : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'Note (Optional)'),
                maxLines: 1, // 一行に変更
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No date selected'
                          : 'Selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: Text('Choose Date'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  final List<Expense> expenses;
  final Function(String) onDeleteExpense; // Callback for deleting an expense

  ExpenseListScreen({required this.expenses, required this.onDeleteExpense});

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Entertainment': Icons.movie,
    'Other': Icons.category,
    'Grocery Shopping': Icons.shopping_cart,
    'Tobacco': Icons.smoking_rooms,
    'Dining Out': Icons.restaurant,
    'Rent': Icons.home,
    'Daily Essentials': Icons.shopping_bag,
  };

  final Map<String, Color> _categoryColors = {
    'Food': Colors.green,
    'Transport': Colors.blue,
    'Entertainment': Colors.red,
    'Other': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.expenses.isEmpty
          ? Center(
              child: Text(
                'No expenses added yet',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: widget.expenses.length,
              itemBuilder: (ctx, index) {
                final expense = widget.expenses[index];
                final categoryIcon = _categoryIcons[expense.category] ?? Icons.category;
                final categoryColor = _categoryColors[expense.category] ?? Colors.grey;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: categoryColor,
                      child: Icon(
                        categoryIcon,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(expense.title),
                    subtitle: Text(
                      '${expense.date.toLocal()}'.split(' ')[0],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${expense.currency} ${expense.amount.toStringAsFixed(2)}'),
                            if (expense.note.isNotEmpty)
                              Text(
                                expense.note,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            widget.onDeleteExpense(expense.id); // Use the callback
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ExpenseSummaryScreen extends StatefulWidget {
  final List<Expense> expenses;

  ExpenseSummaryScreen({required this.expenses});

  @override
  _ExpenseSummaryScreenState createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCurrency = 'JPY';
  final Map<String, double> _exchangeRates = {
    'JPY': 1.0,
    'AUD': 0.012, // Example exchange rate
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchExchangeRates(); // Fetch exchange rates on initialization
  }

  Future<void> _fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/JPY'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _exchangeRates.clear();
            _exchangeRates['JPY'] = 1.0; // Base currency
            if (data['rates']['AUD'] != null) {
              _exchangeRates['AUD'] = (data['rates']['AUD'] is int)
                  ? (data['rates']['AUD'] as int).toDouble()
                  : data['rates']['AUD'];
            }
          });
        }
      } else {
        print('Failed to fetch exchange rates: ${response.statusCode}');
      }
    } catch (error) {
      if (mounted) {
        print('Error fetching exchange rates: $error');
      }
    }
  }

  double _convertCurrency(double amount) {
    return amount * _exchangeRates[_selectedCurrency]!;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, double>{};
    for (var expense in widget.expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'By Category'),
            Tab(text: 'By Month'),
          ],
        ),
        actions: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _selectedCurrency,
                  items: _exchangeRates.keys.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // By Category
          ListView.builder(
            itemCount: categoryTotals.length,
            itemBuilder: (ctx, index) {
              final category = categoryTotals.keys.elementAt(index);
              final amount = _convertCurrency(categoryTotals[category]!);
              return ListTile(
                title: Text(category),
                trailing: Text('${_selectedCurrency} ${amount.toStringAsFixed(2)}'),
              );
            },
          ),
          // By Month
          ListView.builder(
            itemCount: 12, // Assuming 12 months
            itemBuilder: (ctx, index) {
              final month = DateFormat('MMMM').format(DateTime(0, index + 1));
              final monthlyTotal = widget.expenses
                  .where((expense) => expense.date.month == index + 1)
                  .fold(0.0, (sum, expense) => sum + expense.amount);
              final convertedTotal = _convertCurrency(monthlyTotal);
              return ListTile(
                title: Text(month),
                trailing: Text('${_selectedCurrency} ${convertedTotal.toStringAsFixed(2)}'),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Expenseモデルの定義
class Expense {
  String id; // 一意の識別子
  final String title; // 支出のタイトル
  final String category; // カテゴリ
  final double amount; // 支出額
  final DateTime date; // 支出日
  final String note; // ノート
  final String currency; // 通貨

  Expense({
    required this.id,
    required this.title, // 新しいフィールド
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.currency = 'JPY',
  });

  // JSON形式への変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title, // 新しいフィールド
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'currency': currency,
    };
  }

  // JSONからの生成
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'], // 新しいフィールド
      category: json['category'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      note: json['note'] ?? '',
      currency: json['currency'] ?? 'JPY',
    );
  }
}

// 今月の支出合計を計算する関数
double calculateMonthlyExpenseTotal(List<Expense> expenses) {
  final now = DateTime.now();
  final currentMonth = DateFormat('yyyy-MM').format(now);

  return expenses
      .where((expense) => DateFormat('yyyy-MM').format(expense.date) == currentMonth)
      .fold(0.0, (sum, expense) => sum + expense.amount);
}

// ExpenseStorageクラスの定義
class ExpenseStorage {
  static const String _key = 'expenses';

  // データを保存する
  static Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  // データを取得する
  static Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Expense.fromJson(json)).toList();
  }
}

class HomeTab extends StatefulWidget {
  final List<Expense> expenses;

  HomeTab({required this.expenses});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCurrency = 'JPY';
  final Map<String, double> _exchangeRates = {
    'JPY': 1.0,
    'AUD': 83.33, // Corrected example rate (1 AUD = 83.33 JPY)
  };

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/$_selectedCurrency'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            data['rates'].forEach((key, value) {
              if (value != null) {
                _exchangeRates[key] = (value is int) ? value.toDouble() : value;
              }
            });
          });
        }
      } else {
        print('Failed to fetch exchange rates: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching exchange rates: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = widget.expenses.fold(0.0, (sum, expense) {
      if (_selectedCurrency == 'AUD' && expense.currency == 'JPY') {
        // Convert JPY to AUD
        return sum + (expense.amount * _exchangeRates['AUD']!);
      } else if (_selectedCurrency == 'JPY' && expense.currency == 'AUD') {
        // Convert AUD to JPY
        return sum + (expense.amount / _exchangeRates['AUD']!);
      } else {
        // No conversion needed
        return sum + expense.amount;
      }
    });

    final dailyTotal = widget.expenses
        .where((expense) =>
            expense.date.toLocal().day == DateTime.now().day &&
            expense.date.toLocal().month == DateTime.now().month &&
            expense.date.toLocal().year == DateTime.now().year)
        .fold(0.0, (sum, expense) {
      if (_selectedCurrency == 'AUD' && expense.currency == 'JPY') {
        // Convert JPY to AUD
        return sum + (expense.amount * _exchangeRates['AUD']!);
      } else if (_selectedCurrency == 'JPY' && expense.currency == 'AUD') {
        // Convert AUD to JPY
        return sum + (expense.amount / _exchangeRates['AUD']!);
      } else {
        // No conversion needed
        return sum + expense.amount;
      }
    });

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Welcome to Your Expense Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Track your expenses effortlessly',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = 'JPY';
                        });
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selectedCurrency == 'JPY' ? Colors.indigo.shade100 : Colors.grey.shade200,
                          border: Border.all(
                            color: _selectedCurrency == 'JPY' ? Colors.indigo : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'JPY',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCurrency == 'JPY' ? Colors.indigo : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = 'AUD';
                        });
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selectedCurrency == 'AUD' ? Colors.indigo.shade100 : Colors.grey.shade200,
                          border: Border.all(
                            color: _selectedCurrency == 'AUD' ? Colors.indigo : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'AUD',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCurrency == 'AUD' ? Colors.indigo : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 20),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Total Expenses This Month',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${_selectedCurrency} ${monthlyTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Today\'s Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${_selectedCurrency} ${dailyTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Google Sheets export functionality
const _spreadsheetId = '1ZUBYXFaYWfLv7j2sYNs41cVd9lJTjzlY1fATGItBqGM';

Future<void> exportExpenseToSheet(Expense expense) async {
  final credentials = Platform.environment['GOOGLE_CLOUD_CREDENTIALS'];
  if (credentials == null) {
    throw Exception('Google Cloud credentials not found in environment variables.');
  }

  final gsheets = GSheets(credentials);
  final spreadsheet = await gsheets.spreadsheet(_spreadsheetId);
  final sheet = spreadsheet.sheets.first;

  await sheet.values.appendRow([
    expense.id, // Unique ID of the expense
    expense.date.toIso8601String(), // Date of the expense
    expense.currency, // Currency of the expense
    expense.amount, // Amount of the expense
    expense.title, // Title of the expense
    expense.category, // Category of the expense
    'active', // Status of the expense (active by default)
  ]);
}

Future<void> markExpenseAsDeleted(String expenseId) async {
  final credentials = Platform.environment['GOOGLE_CLOUD_CREDENTIALS'];
  if (credentials == null) {
    throw Exception('Google Cloud credentials not found in environment variables.');
  }

  final gsheets = GSheets(credentials);
  final spreadsheet = await gsheets.spreadsheet(_spreadsheetId);
  final sheet = spreadsheet.sheets.first;

  final rows = await sheet.values.allRows();
  for (int i = 0; i < rows.length; i++) {
    if (rows[i].isNotEmpty && rows[i][0] == expenseId) { // Search by ID in column A
      await sheet.values.insertValue('deleted', column: 7, row: i + 1); // Mark as deleted in column G
      break;
    }
  }
}
