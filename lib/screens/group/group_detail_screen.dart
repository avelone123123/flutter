import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/services/web_group_service.dart';
import 'package:smart_attendance/models/group_model.dart';
import 'package:smart_attendance/screens/group/add_students_screen.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  // Для веб
  GroupModel? _webGroup;
  List<Map<String, dynamic>> _webStudents = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebGroup();
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _loadWebGroup();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWebGroup() async {
    if (!mounted) return;
    
    setState(() {
      if (_webGroup == null) _isLoading = true;
      _errorMessage = null;
    });

    try {
      final webService = WebGroupService();
      final group = await webService.getGroup(widget.groupId);
      final students = await webService.getGroupStudents(widget.groupId);
      if (!mounted) return;
      setState(() {
        _webGroup = group;
        _webStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали группы'),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWebGroup,
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit group screen
            },
          ),
        ],
      ),
      body: kIsWeb ? _buildWebView() : _buildMobileView(),
    );
  }

  Widget _buildWebView() {
    if (_isLoading && _webGroup == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWebGroup,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_webGroup == null) {
      return const Center(child: Text('Группа не найдена'));
    }

    final group = _webGroup!;
    final studentIds = group.studentIds;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Курс: ${group.course}'),
                Text('Год: ${group.year}'),
                Text('Студентов: ${studentIds.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Кнопка добавления студентов
        ElevatedButton.icon(
          onPressed: () => _navigateToAddStudents(),
          icon: const Icon(Icons.person_add),
          label: Text(AppLocalizations.of(context)?.addStudents ?? 'Добавить студентов'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          'Студенты',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_webStudents.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Студенты не добавлены'),
            ),
          )
        else
          ..._webStudents.map((student) {
            final name = student['name'] ?? 'Студент';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(name.substring(0, 1).toUpperCase()),
                ),
                title: Text(name),
                subtitle: Text(student['email'] ?? ''),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMobileView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Группа не найдена'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final studentIds = List<String>.from(data['studentIds'] ?? []);

        return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Без названия',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Курс: ${data['course'] ?? '-'}'),
                      Text('Год: ${data['year'] ?? '-'}'),
                      Text('Студентов: ${studentIds.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Кнопка добавления студентов
              ElevatedButton.icon(
                onPressed: () => _navigateToAddStudents(),
                icon: const Icon(Icons.person_add),
                label: Text(AppLocalizations.of(context)?.addStudents ?? 'Добавить студентов'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Студенты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...studentIds.map((studentId) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Card(
                        child: ListTile(
                          leading: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    final name = userData?['name'] ?? 'Студент';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(name.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(name),
                        subtitle: Text(userData?['email'] ?? ''),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      );
  }
  
  /// Навигация к экрану добавления студентов
  void _navigateToAddStudents() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStudentsScreen(groupId: widget.groupId),
      ),
    );

    if (result == true) {
      if (kIsWeb) {
        _loadWebGroup();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.success ?? 'Успешно')),
        );
      }
    }
  }
}
