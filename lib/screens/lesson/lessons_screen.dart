import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/screens/lesson/create_lesson_screen.dart';
import 'package:smart_attendance/screens/lesson/lesson_detail_screen.dart';
import 'package:smart_attendance/utils/auth_helper.dart';
import 'package:smart_attendance/models/lesson_model.dart';
import 'package:smart_attendance/services/web_lesson_service.dart';
import 'dart:async';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({Key? key}) : super(key: key);

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get _currentUserId => AuthHelper.getCurrentUserId(context) ?? '';
  
  // Для веб - используем периодическое обновление
  List<LessonModel> _webLessons = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (kIsWeb) {
      _loadWebLessons();
      // Автообновление каждые 5 секунд для веб
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _loadWebLessons();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWebLessons() async {
    if (!mounted) return;
    
    try {
      final webService = WebLessonService();
      final lessons = await webService.getTeacherLessons(_currentUserId);
      if (mounted) {
        setState(() {
          _webLessons = lessons;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Занятия'),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWebLessons,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Сегодня'),
            Tab(text: 'Предстоящие'),
            Tab(text: 'Прошедшие'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          kIsWeb ? _buildWebLessonsList('today') : _buildLessonsList('today'),
          kIsWeb ? _buildWebLessonsList('upcoming') : _buildLessonsList('upcoming'),
          kIsWeb ? _buildWebLessonsList('past') : _buildLessonsList('past'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateLesson(),
        icon: const Icon(Icons.add),
        label: const Text('Новое занятие'),
      ),
    );
  }

  // Веб-версия списка занятий
  Widget _buildWebLessonsList(String type) {
    if (_isLoading && _webLessons.isEmpty) {
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
              onPressed: _loadWebLessons,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Фильтрация занятий по типу
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<LessonModel> filteredLessons;
    if (type == 'today') {
      filteredLessons = _webLessons.where((lesson) {
        return lesson.date.isAfter(todayStart) && lesson.date.isBefore(todayEnd);
      }).toList();
    } else if (type == 'upcoming') {
      filteredLessons = _webLessons.where((lesson) {
        return lesson.date.isAfter(todayEnd);
      }).toList();
    } else {
      filteredLessons = _webLessons.where((lesson) {
        return lesson.date.isBefore(todayStart);
      }).toList();
    }

    filteredLessons.sort((a, b) => type == 'past' 
        ? b.date.compareTo(a.date) 
        : a.date.compareTo(b.date));

    if (filteredLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              type == 'today'
                  ? 'Нет занятий на сегодня'
                  : type == 'upcoming'
                      ? 'Нет предстоящих занятий'
                      : 'Нет прошедших занятий',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWebLessons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLessons.length,
        itemBuilder: (context, index) {
          final lesson = filteredLessons[index];
          return _LessonCard(
            lessonId: lesson.id,
            subject: lesson.subject,
            type: lesson.type.displayName,
            groupName: lesson.groupName,
            classroom: lesson.classroom,
            date: lesson.date,
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            attendanceCount: lesson.attendanceMarked.length,
            onTap: () => _navigateToLessonDetail(lesson.id),
          );
        },
      ),
    );
  }

  Widget _buildLessonsList(String type) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    Query query = FirebaseFirestore.instance
        .collection('lessons')
        .where('teacherId', isEqualTo: _currentUserId);

    if (type == 'today') {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
          .orderBy('date');
    } else if (type == 'upcoming') {
      query = query
          .where('date', isGreaterThan: Timestamp.fromDate(todayEnd))
          .orderBy('date')
          .limit(20);
    } else {
      query = query
          .where('date', isLessThan: Timestamp.fromDate(todayStart))
          .orderBy('date', descending: true)
          .limit(20);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  type == 'today'
                      ? 'Нет занятий на сегодня'
                      : type == 'upcoming'
                          ? 'Нет предстоящих занятий'
                          : 'Нет прошедших занятий',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                if (type != 'past')
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateLesson(),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать занятие'),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final doc = lessons[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();

              return _LessonCard(
                lessonId: doc.id,
                subject: data['subject'] ?? 'Без названия',
                type: data['type'] ?? 'Занятие',
                groupName: data['groupName'] ?? '',
                classroom: data['classroom'] ?? '',
                date: date,
                startTime: data['startTime'] ?? '',
                endTime: data['endTime'] ?? '',
                attendanceCount: (data['attendanceMarked'] as List?)?.length ?? 0,
                onTap: () => _navigateToLessonDetail(doc.id),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToCreateLesson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateLessonScreen()),
    );
    
    if (result == true && mounted) {
      if (kIsWeb) {
        _loadWebLessons();
      } else {
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Занятие успешно создано')),
      );
    }
  }

  void _navigateToLessonDetail(String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(lessonId: lessonId),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String lessonId;
  final String subject;
  final String type;
  final String groupName;
  final String classroom;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int attendanceCount;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lessonId,
    required this.subject,
    required this.type,
    required this.groupName,
    required this.classroom,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.attendanceCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ru');
    final isToday = DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isToday
                ? Colors.green.withOpacity(0.1)
                : Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isToday ? Icons.event_available : Icons.event,
            color: isToday ? Colors.green : Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type • $groupName'),
            Text('📅 ${dateFormat.format(date)} • 🕐 $startTime - $endTime'),
            if (classroom.isNotEmpty) Text('📍 $classroom'),
            Text(
              '✓ $attendanceCount отметились',
              style: TextStyle(
                color: attendanceCount > 0 ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
