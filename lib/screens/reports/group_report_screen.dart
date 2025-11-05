import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/utils/auth_helper.dart';
import '../../services/web_group_service.dart';
import '../../services/web_lesson_service.dart';
import '../../models/group_model.dart';
import '../../models/lesson_model.dart';

/// Экран отчётов по группам
class GroupReportScreen extends StatefulWidget {
  const GroupReportScreen({super.key});

  @override
  State<GroupReportScreen> createState() => _GroupReportScreenState();
}

class _GroupReportScreenState extends State<GroupReportScreen> {
  String? _selectedGroupId;
  String get _currentUserId => AuthHelper.getCurrentUserId(context) ?? '';
  
  List<GroupModel> _webGroups = [];
  List<LessonModel> _webLessons = [];
  bool _isLoading = false;
  String? _error;
  
  final WebGroupService _webGroupService = WebGroupService();
  final WebLessonService _webLessonService = WebLessonService();
  
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebData();
    }
  }
  
  Future<void> _loadWebData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      _webGroups = await _webGroupService.getTeacherGroups(_currentUserId);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadWebLessons(String groupId) async {
    try {
      _webLessons = await _webLessonService.getGroupLessons(groupId);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading lessons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebView();
    } else {
      return _buildFirebaseView();
    }
  }
  
  Widget _buildWebView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWebData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    if (_webGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет групп для отчетов',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Создайте группу, чтобы видеть отчеты',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _selectedGroupId,
            decoration: const InputDecoration(
              labelText: 'Выберите группу',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group),
            ),
            items: _webGroups.map((group) {
              return DropdownMenuItem(
                value: group.id,
                child: Text(group.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedGroupId = value);
              if (value != null) {
                _loadWebLessons(value);
              }
            },
          ),
        ),
        if (_selectedGroupId != null)
          Expanded(
            child: _buildWebGroupReport(_selectedGroupId!),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Выберите группу для просмотра отчета',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildFirebaseView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('teacherId', isEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data?.docs ?? [];

        if (groups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет групп для отчетов',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Создайте группу, чтобы видеть отчеты',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'Выберите группу',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                items: groups.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['name'] ?? 'Без названия'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGroupId = value);
                },
              ),
            ),
            if (_selectedGroupId != null)
              Expanded(
                child: _buildGroupReport(_selectedGroupId!),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Выберите группу для просмотра отчета',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildWebGroupReport(String groupId) {
    final totalLessons = _webLessons.length;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статистика группы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Text('Всего занятий: $totalLessons'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupReport(String groupId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .where('groupId', isEqualTo: groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lessons = snapshot.data!.docs;
        final totalLessons = lessons.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика группы',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text('Всего занятий: $totalLessons'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
