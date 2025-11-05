import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/utils/auth_helper.dart';
import '../../services/web_lesson_service.dart';
import '../../services/web_group_service.dart';
import '../../models/lesson_model.dart';
import '../../models/group_model.dart';

/// Экран детальной статистики
class DetailedStatsScreen extends StatefulWidget {
  const DetailedStatsScreen({super.key});

  @override
  State<DetailedStatsScreen> createState() => _DetailedStatsScreenState();
}

class _DetailedStatsScreenState extends State<DetailedStatsScreen> {
  List<LessonModel> _webLessons = [];
  List<GroupModel> _webGroups = [];
  bool _isLoading = false;
  String? _error;
  
  final WebLessonService _webLessonService = WebLessonService();
  final WebGroupService _webGroupService = WebGroupService();
  
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebData();
    }
  }
  
  Future<void> _loadWebData() async {
    final currentUserId = AuthHelper.getCurrentUserId(context) ?? '';
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      _webLessons = await _webLessonService.getTeacherLessons(currentUserId);
      _webGroups = await _webGroupService.getTeacherGroups(currentUserId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    
    if (_webLessons.isEmpty && _webGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет данных для статистики'),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(
          'Всего занятий',
          '${_webLessons.length}',
          Icons.event,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildStatsCard(
          'Всего групп',
          '${_webGroups.length}',
          Icons.group,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildStatsCard(
          'Предстоящих занятий',
          '${_webLessons.where((l) => l.date.isAfter(DateTime.now())).length}',
          Icons.schedule,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildStatsCard(
          'Завершенных занятий',
          '${_webLessons.where((l) => l.date.isBefore(DateTime.now())).length}',
          Icons.check_circle,
          Colors.purple,
        ),
      ],
    );
  }
  
  Widget _buildFirebaseView() {
    final currentUserId = AuthHelper.getCurrentUserId(context) ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .where('teacherId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, lessonsSnapshot) {
        if (lessonsSnapshot.hasError) {
          return Center(
            child: Text('Ошибка: ${lessonsSnapshot.error}'),
          );
        }

        if (lessonsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final lessons = lessonsSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .where('teacherId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, groupsSnapshot) {
            if (!groupsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final groups = groupsSnapshot.data!.docs;

            if (lessons.isEmpty && groups.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Нет данных для статистики'),
                  ],
                ),
              );
            }

            final totalGroups = groups.length;
            final totalLessons = lessons.length;
            int totalStudents = 0;
            for (var group in groups) {
              final data = group.data() as Map<String, dynamic>;
              totalStudents += (data['studentIds'] as List?)?.length ?? 0;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Детальная статистика',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow('Всего групп', totalGroups.toString()),
                        _buildStatRow('Всего занятий', totalLessons.toString()),
                        _buildStatRow('Всего студентов', totalStudents.toString()),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// Вспомогательный метод для отображения карточки статистики
  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
