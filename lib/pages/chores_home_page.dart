// pages/chores_home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared_preferences
import 'dart:convert'; // Import for JSON encoding/decoding
import '../models/chore.dart'; // Import the Chore model

class ChoresHomePage extends StatefulWidget {
  const ChoresHomePage({super.key});

  @override
  State<ChoresHomePage> createState() => _ChoresHomePageState();
}

class _ChoresHomePageState extends State<ChoresHomePage> {
  // Initialize an empty map for chores
  Map<String, List<Chore>> _choresByDay = {};
  bool _isLoading = true; // State to handle initial data loading

  @override
  void initState() {
    super.initState();
    _loadChores();
  }

  // Method to load chores from shared preferences
  Future<void> _loadChores() async {
    final prefs = await SharedPreferences.getInstance();
    final choresJsonString = prefs.getString('chores_data');
    if (choresJsonString != null) {
      final decodedData = json.decode(choresJsonString) as Map<String, dynamic>;
      final loadedChoresByDay = <String, List<Chore>>{};
      decodedData.forEach((day, choresList) {
        loadedChoresByDay[day] = (choresList as List<dynamic>)
            .map((choreJson) => Chore.fromJson(choreJson as Map<String, dynamic>))
            .toList();
      });
      setState(() {
        _choresByDay = loadedChoresByDay;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to save chores to shared preferences
  Future<void> _saveChores() async {
    final prefs = await SharedPreferences.getInstance();
    final choresJson = <String, dynamic>{};
    _choresByDay.forEach((day, chores) {
      choresJson[day] = chores.map((c) => c.toJson()).toList();
    });
    final choresJsonString = json.encode(choresJson);
    await prefs.setString('chores_data', choresJsonString);
  }

  // A method to delete a chore from the list
  void _deleteChore(Chore chore) {
    setState(() {
      _choresByDay.forEach((day, choresList) {
        choresList.removeWhere((c) => c.title == chore.title && c.day == chore.day);
      });
      // Remove days that have no chores left
      _choresByDay.removeWhere((key, value) => value.isEmpty);
    });
    _saveChores(); // Save data after deleting a chore
  }

  double get _totalEarnings {
    double total = 0;
    _choresByDay.forEach((day, chores) {
      for (var chore in chores) {
        if (chore.isApprovedByParent) {
          total += chore.price;
        }
      }
    });
    return total;
  }

  // A method for the child to mark a chore as complete
  void _toggleChoreCompletion(Chore chore) {
    setState(() {
      chore.isCompletedByChild = !chore.isCompletedByChild;
      if (!chore.isCompletedByChild) {
        // If the child unchecks, the parent approval is also reset
        chore.isApprovedByParent = false;
      }
    });
    _saveChores(); // Save data after state change
  }

  // A method for the parent to approve a completed chore
  void _approveChore(Chore chore) {
    if (chore.isCompletedByChild) {
      setState(() {
        chore.isApprovedByParent = true;
      });
    }
    _saveChores(); // Save data after state change
  }

  // Method to show a dialog for adding a new chore
  Future<void> _showAddChoreDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    String? selectedDay;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('הוספת משימה חדשה'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'שם המשימה'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'תשלום (₪)'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'יום בשבוע'),
                    value: selectedDay,
                    items: const [
                      'יום ראשון', 'יום שני', 'יום שלישי', 'יום רביעי',
                      'יום חמישי', 'יום שישי', 'יום שבת'
                    ].map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedDay = newValue;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('ביטול'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('הוסף'),
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      selectedDay != null) {
                    final newChore = Chore(
                      day: selectedDay!,
                      title: titleController.text,
                      price: double.parse(priceController.text),
                    );
                    _addChore(newChore);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to add a new chore to the list
  void _addChore(Chore newChore) {
    setState(() {
      if (!_choresByDay.containsKey(newChore.day)) {
        _choresByDay[newChore.day] = [];
      }
      _choresByDay[newChore.day]!.add(newChore);
    });
    _saveChores(); // Save data after adding a new chore
  }

  // A method to build the list of all chores
  List<Chore> _getAllChores() {
    List<Chore> allChores = [];
    _choresByDay.keys.forEach((day) {
      allChores.addAll(_choresByDay[day]!);
    });
    return allChores;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> daysOfWeek = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];
    final List<String> tabTitles = ['הכל', ...daysOfWeek];

    return DefaultTabController(
      length: tabTitles.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('אפליקציית מטלות'),
          backgroundColor: Colors.deepPurple.shade50,
          bottom: TabBar(
            isScrollable: true,
            tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl, // Set RTL for Hebrew
          child: Column(
            children: [
              _buildEarningsWidget(),
              const Divider(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          // Tab for all chores (history)
                          _getAllChores().isEmpty
                              ? Center(
                                  child: Text(
                                    'לחץ על כפתור הפלוס כדי להוסיף משימה',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : ListView(
                                  children: _getAllChores().map((chore) => _buildChoreCard(chore)).toList(),
                                ),
                          // Tabs for each day of the week
                          ...daysOfWeek.map((day) {
                            final dayKey = 'יום $day';
                            final choresForDay = _choresByDay[dayKey] ?? [];
                            return choresForDay.isEmpty
                                ? Center(
                                    child: Text(
                                      'אין משימות ליום $day',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : ListView(
                                    children: choresForDay.map((chore) => _buildChoreCard(chore)).toList(),
                                  );
                          }).toList(),
                        ],
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddChoreDialog,
          tooltip: 'הוסף משימה',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Widget to display the total earnings
  Widget _buildEarningsWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'סך הכל שהרווחת:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            '${_totalEarnings.toStringAsFixed(2)} ₪',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build a single chore item with Dismissible functionality
  Widget _buildChoreCard(Chore chore) {
    return Dismissible(
      key: Key(chore.title + chore.day), // Unique key for the Dismissible widget
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteChore(chore);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('משימה "${chore.title}" נמחקה')),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Checkbox for the child
              Checkbox(
                value: chore.isCompletedByChild,
                onChanged: (bool? value) {
                  _toggleChoreCompletion(chore);
                },
              ),
              const SizedBox(width: 12),
              // Chore title and price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chore.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: chore.isCompletedByChild
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: chore.isCompletedByChild
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    Text(
                      '${chore.price.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              // Parent's approval button/icon
              if (chore.isCompletedByChild && !chore.isApprovedByParent)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () => _approveChore(chore),
                  tooltip: 'אשר משימה',
                )
              else if (chore.isApprovedByParent)
                const Icon(Icons.verified, color: Colors.green),
              if (!chore.isCompletedByChild)
                const Icon(Icons.pending, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
