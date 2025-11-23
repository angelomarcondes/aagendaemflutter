import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Tarefa {
  String id;
  String titulo;
  bool concluida;

  Tarefa({
    required this.id,
    required this.titulo,
    this.concluida = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'concluida': concluida,
  };

  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
    id: json['id'],
    titulo: json['titulo'],
    concluida: json['concluida'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
  runApp(const AgendaDiariaApp());
}

class AgendaDiariaApp extends StatelessWidget {
  const AgendaDiariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Estudante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF8B25FD),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF340068),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String _userName = "Estudante";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      String? lastEmail = prefs.getString('last_email');
      if (lastEmail != null) {
        _userName = lastEmail.split('@')[0];
      }
      _isLoading = false;
    });
  }

  void _setLoggedIn(bool value, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
    if (value) {
      await prefs.setString('last_email', email);
    }

    setState(() {
      _isLoggedIn = value;
      _userName = email.split('@')[0];
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn
        ? CalendarScreen(userName: _userName, onLogout: _logout)
        : AuthScreen(onLogin: (email) => _setLoggedIn(true, email));
  }
}

class AuthScreen extends StatefulWidget {
  final Function(String) onLogin;
  const AuthScreen({required this.onLogin, super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;

  void _authenticate() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Preencha todos os campos.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('user_$email');

    if (_isLogin) {
      if (storedUser != null) {
        final userData = jsonDecode(storedUser);
        if (userData['password'] == password) {
          widget.onLogin(email);
        } else {
          setState(() => _errorText = 'Senha incorreta.');
        }
      } else {
        setState(() => _errorText = 'Usuário não encontrado.');
      }
    } else {
      if (storedUser == null) {
        final userData = jsonEncode({'email': email, 'password': password});
        await prefs.setString('user_$email', userData);
        widget.onLogin(email);
      } else {
        setState(() => _errorText = 'Usuário já existe.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            _isLogin ? 'Bem Vindo!' : 'Criar Conta',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF8B25FD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email)),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: Icon(Icons.lock)),
                          ),
                          const SizedBox(height: 20),
                          if (_errorText != null)
                            Text(_errorText!,
                                style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _authenticate,
                              child: Text(_isLogin ? 'ENTRAR' : 'CADASTRAR'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _isLogin = !_isLogin;
                              _errorText = null;
                            }),
                            child: Text(_isLogin
                                ? 'Não tem conta? Cadastre-se'
                                : 'Já tem conta? Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final String userName;
  final VoidCallback onLogout;
  const CalendarScreen(
      {required this.userName, required this.onLogout, super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _goToTaskList() {
    if (_selectedDay != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TaskListScreen(selectedDate: _selectedDay!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.userName.isNotEmpty
        ? "${widget.userName[0].toUpperCase()}${widget.userName.substring(1)}"
        : "Visitante";

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.purple),
              onPressed: widget.onLogout)
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bem Vindo,",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF340068),
                  ),
                ),
                Text(
                  "$displayName!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF340068),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF8B25FD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      locale: 'pt_BR',
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarStyle: const CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF8B25FD),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Color(0x808B25FD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _goToTaskList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF340068),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Selecionar o dia",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final DateTime selectedDate;
  const TaskListScreen({required this.selectedDate, super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Tarefa> _tasks = [];
  bool _isLoading = true;

  String get _taskKey =>
      'tasks_${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(_taskKey);
    setState(() {
      if (tasksString != null) {
        final List<dynamic> jsonList = jsonDecode(tasksString);
        _tasks = jsonList.map((json) => Tarefa.fromJson(json)).toList();
      } else {
        _tasks = [];
      }
      _sortTasks();
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
    jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_taskKey, jsonString);
  }

  void _addTask(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(Tarefa(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titulo: title,
        ));
        _sortTasks();
        _saveTasks();
      });
    }
  }

  void _toggleTask(Tarefa task) {
    setState(() {
      task.concluida = !task.concluida;
      _sortTasks();
      _saveTasks();
    });
  }

  void _removeTask(Tarefa task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
      _saveTasks();
    });
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
      return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    });
  }

  void _showAddTaskDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Adicionar Tarefa'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ex: Estudar Flutter',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              child:
              const Text('Cancelar', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF340068),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Adicionar'),
              onPressed: () {
                _addTask(controller.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(""),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tarefas do Dia",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF340068),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF8B25FD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Dia $formattedDate",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _tasks.isEmpty
                          ? Center(
                        child: Text(
                          "Nenhuma tarefa ainda.",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                          : ListView.separated(
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 10),
                            leading: Icon(
                              task.concluida
                                  ? Icons.check_circle
                                  : Icons.circle,
                              color: task.concluida
                                  ? Colors.green
                                  : Colors.blue,
                              size: 20,
                            ),
                            title: Text(
                              task.titulo,
                              style: TextStyle(
                                decoration: task.concluida
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.concluida
                                    ? Colors.grey
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _toggleTask(task),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _removeTask(task),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: InkWell(
                      onTap: _showAddTaskDialog,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5))
                            ]),
                        child: const Icon(Icons.add,
                            color: Color(0xFF8B25FD), size: 35),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}