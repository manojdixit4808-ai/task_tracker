import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const TaskApp());
}

class TaskApp extends StatefulWidget {
  const TaskApp({super.key});

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  bool _isDarkMode = false;
  bool _isHindi = false;
  Color _primaryColor = Colors.indigo;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _toggleLanguage() {
    setState(() {
      _isHindi = !_isHindi;
    });
  }

  void _changeColorTheme(Color color) {
    setState(() {
      _primaryColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Manoj's Daily Tasks",
      theme: ThemeData(
        useMaterial3: true,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        colorSchemeSeed: _primaryColor,
      ),
      home: LoginScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
        onChangeColor: _changeColorTheme,
        currentColor: _primaryColor,
        isHindi: _isHindi,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Function(Color) onChangeColor;
  final Color currentColor;
  final bool isHindi;
  final VoidCallback onToggleLanguage;

  const LoginScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onChangeColor,
    required this.currentColor,
    required this.isHindi,
    required this.onToggleLanguage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainTaskScreen(
            username: "Manoj Sharma",
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            onChangeColor: widget.onChangeColor,
            currentColor: widget.currentColor,
            isHindi: widget.isHindi,
            onToggleLanguage: widget.onToggleLanguage,
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainTaskScreen(
            username: "Manoj Sharma",
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            onChangeColor: widget.onChangeColor,
            currentColor: widget.currentColor,
            isHindi: widget.isHindi,
            onToggleLanguage: widget.onToggleLanguage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool h = widget.isHindi;
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: widget.onToggleLanguage,
            child: Text(h ? "English" : "हिंदी", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                "Manoj's Daily Tasks",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(h ? "अपने दैनिक कार्यों को प्रबंधित करने के लिए लॉगिन करें" : "Login to manage your daily tasks"),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: h ? 'आपका नाम / यूजरनेम' : 'Your Name / Username',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _handleLogin,
                  child: Text(h ? 'लॉग इन करें' : 'LOG IN', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainTaskScreen extends StatefulWidget {
  final String username;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Function(Color) onChangeColor;
  final Color currentColor;
  final bool isHindi;
  final VoidCallback onToggleLanguage;

  const MainTaskScreen({
    super.key,
    required this.username,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onChangeColor,
    required this.currentColor,
    required this.isHindi,
    required this.onToggleLanguage,
  });

  @override
  State<MainTaskScreen> createState() => _MainTaskScreenState();
}

class _MainTaskScreenState extends State<MainTaskScreen> {
  List<Map<String, dynamic>> _tasks = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_tasks', jsonEncode(_tasks));
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTasks = prefs.getString('saved_tasks');
    if (savedTasks != null) {
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(jsonDecode(savedTasks));
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            onChangeColor: widget.onChangeColor,
            currentColor: widget.currentColor,
            isHindi: widget.isHindi,
            onToggleLanguage: widget.onToggleLanguage,
          ),
        ),
      );
    }
  }

  Future<void> _scheduleAlarm(String title, DateTime scheduledTime, int id) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'task_channel_id',
        'Task Alarms',
        channelDescription: 'Channel for Task alarms and reminders',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Task Reminder: $title',
        'It is time to complete your task!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("Alarm error: $e");
    }
  }

  void _showColorPicker() {
    bool h = widget.isHindi;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h ? "ऐप का थीम कलर चुनें" : "Choose App Theme Color", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    widget.onChangeColor(Colors.indigo);
                    Navigator.pop(context);
                  },
                  child: const CircleAvatar(backgroundColor: Colors.indigo, radius: 25),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onChangeColor(Colors.teal);
                    Navigator.pop(context);
                  },
                  child: const CircleAvatar(backgroundColor: Colors.teal, radius: 25),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onChangeColor(Colors.deepPurple);
                    Navigator.pop(context);
                  },
                  child: const CircleAvatar(backgroundColor: Colors.deepPurple, radius: 25),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    bool h = widget.isHindi;
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    List<String> categories = h 
        ? ['व्यक्तिगत', 'कार्य', 'फिटनेस', 'पढ़ाई', 'खरीदारी']
        : ['Personal', 'Work', 'Fitness', 'Study', 'Shopping'];
    List<String> priorities = h
        ? ['उच्च', 'मध्यम', 'कम']
        : ['High', 'Medium', 'Low'];

    String category = categories[0];
    String priority = priorities[1];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(h ? 'नया कार्य और अलार्म जोड़ें' : 'Create Task & Alarm'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: h ? 'कार्य का नाम' : 'Task Title'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(labelText: h ? 'श्रेणी / फ़ोल्डर' : 'Folder / Category'),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setDialogState(() => category = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: InputDecoration(labelText: h ? 'प्राथमिकता' : 'Priority Level'),
                    items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setDialogState(() => priority = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${h ? 'अलार्म समय:' : 'Alarm Time:'} ${selectedTime.format(context)}"),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: Text(h ? 'समय बदलें' : 'Pick Time'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(h ? 'रद्द करें' : 'Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  
                  final now = DateTime.now();
                  DateTime scheduledDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  if (scheduledDateTime.isBefore(now)) {
                    scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
                  }

                  int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

                  setState(() {
                    _tasks.add({
                      'title': titleController.text.trim(),
                      'isDone': false,
                      'category': category,
                      'priority': priority,
                      'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
                      'time': selectedTime.format(context),
                      'notifId': notificationId,
                    });
                  });
                  _saveTasks();
                  _scheduleAlarm(titleController.text.trim(), scheduledDateTime, notificationId);
                  Navigator.pop(context);
                },
                child: Text(h ? 'सहेजें' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool h = widget.isHindi;
    int completed = _tasks.where((t) => t['isDone'] == true).length;
    double progress = _tasks.isEmpty ? 0.0 : completed / _tasks.length;

    List<String> categories = h 
        ? ['सभी', 'व्यक्तिगत', 'कार्य', 'फिटनेस', 'पढ़ाई', 'खरीदारी']
        : ['All', 'Personal', 'Work', 'Fitness', 'Study', 'Shopping'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manoj's Tasks"),
        actions: [
          TextButton(
            onPressed: widget.onToggleLanguage,
            child: Text(h ? "English" : "हिंदी", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${h ? "स्वागत है" : "Welcome"}, Manoj Sharma!', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(progress * 100).toInt()}% ${h ? "पूरा हुआ" : "Done"}'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, minHeight: 8),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat || (_selectedCategory == 'All' && idx == 0),
                    onSelected: (_) => setState(() => _selectedCategory = idx == 0 ? 'All' : cat),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? Center(child: Text(h ? 'कोई कार्य नहीं मिला!' : 'No tasks found!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tasks.length,
                    itemBuilder: (context, idx) {
                      final task = _tasks[idx];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: task['isDone'],
                            onChanged: (val) {
                              setState(() => _tasks[idx]['isDone'] = val);
                              _saveTasks();
                            },
                          ),
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              decoration: task['isDone'] ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text('${task['category']} • ${task['priority']} • ⏰ ${task['time'] ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => _tasks.removeAt(idx));
                              _saveTasks();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

