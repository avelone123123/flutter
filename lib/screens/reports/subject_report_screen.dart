import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/utils/auth_helper.dart';
import '../../services/web_lesson_service.dart';
import '../../models/lesson_model.dart';

/// Экран отчётов по предметам
class SubjectReportScreen extends StatefulWidget {
  const SubjectReportScreen({super.key});

  @override
  State<SubjectReportScreen> createState() => _SubjectReportScreenState();
}

class _SubjectReportScreenState extends State<SubjectReportScreen> {
  String get _currentUserId => AuthHelper.getCurrentUserId(context) ?? '';
  
  List<LessonModel> _webLessons = [];
  bool _isLoading = false;
  String? _error;
  
  final WebLessonService _webLessonService = WebLessonService();
  
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebData();
    }
  }
  
  Future<void> _loadWebData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      _webLessons = await _webLessonService.getTeacherLessons(_currentUserId);
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
    
    if (_webLessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subject, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет занятий для отчетов',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Создайте занятие, чтобы видеть отчеты',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Группировка занятий по предметам
    final Map<String, List<LessonModel>> subjectGroups = {};
    for (final lesson in _webLessons) {
      if (!subjectGroups.containsKey(lesson.subject)) {
        subjectGroups[lesson.subject] = [];
      }
      subjectGroups[lesson.subject]!.add(lesson);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjectGroups.length,
      itemBuilder: (context, index) {
        final subject = subjectGroups.keys.elementAt(index);
        final subjectLessons = subjectGroups[subject]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.subject),
            title: Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('Занятий: ${subjectLessons.length}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Всего занятий', '${subjectLessons.length}'),
                    const SizedBox(height: 8),
                    _buildStatRow('Предстоящих', '${subjectLessons.where((l) => l.date.isAfter(DateTime.now())).length}'),
                    const SizedBox(height: 8),
                    _buildStatRow('Завершенных', '${subjectLessons.where((l) => l.date.isBefore(DateTime.now())).length}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFirebaseView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
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

        final lessons = snapshot.data?.docs ?? [];

        if (lessons.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subject, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет занятий для отчетов',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Создайте занятие, чтобы видеть отчеты по предметам',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Группировка по предметам
        final Map<String, List<DocumentSnapshot>> subjectGroups = {};
        for (var lesson in lessons) {
          final data = lesson.data() as Map<String, dynamic>;
          final subject = data['subject'] ?? 'Без предмета';
          if (!subjectGroups.containsKey(subject)) {
            subjectGroups[subject] = [];
          }
          subjectGroups[subject]!.add(lesson);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Отчеты по предметам',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...subjectGroups.entries.map((entry) {
              final subject = entry.key;
              final subjectLessons = entry.value;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const Icon(Icons.subject, color: Colors.blue),
                  title: Text(
                    subject,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Занятий: ${subjectLessons.length}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Всего проведено занятий: ${subjectLessons.length}'),
                          const SizedBox(height: 8),
                          ...subjectLessons.take(5).map((lessonDoc) {
                            final lessonData = lessonDoc.data() as Map<String, dynamic>;
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              title: Text(lessonData['groupName'] ?? 'Группа'),
                              subtitle: Text(lessonData['type'] ?? 'Занятие'),
                            );
                          }).toList(),
                          if (subjectLessons.length > 5)
                            Text('...и еще ${subjectLessons.length - 5}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  /// Вспомогательный метод для отображения строки статистики
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
