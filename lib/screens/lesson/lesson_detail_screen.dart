import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/screens/lesson/qr_display_screen_enhanced.dart';
import '../../services/api_service.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  // Web state
  Map<String, dynamic>? _webLesson;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebLesson();
    }
  }

  Future<void> _loadWebLesson() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/lessons/${widget.lessonId}');
      if (mounted) {
        setState(() {
          _webLesson = response;
          _isLoading = false;
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
    if (kIsWeb) {
      return _buildWebView();
    }
    return _buildFirebaseView();
  }

  Widget _buildWebView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали занятия'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteLesson(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Ошибка: $_errorMessage'))
              : _webLesson == null
                  ? const Center(child: Text('Занятие не найдено'))
                  : _buildLessonContent(_webLesson!),
    );
  }

  Widget _buildFirebaseView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали занятия'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit lesson screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteLesson(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Занятие не найдено'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildLessonContent(data);
        },
      ),
    );
  }

  Widget _buildLessonContent(Map<String, dynamic> data) {
    // Parse date - handle both Timestamp (Firebase) and String (API)
    DateTime date;
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      date = DateTime.parse(data['date'] as String);
    } else {
      date = DateTime.now();
    }

    final attendanceList = data['attendance'] is List
        ? (data['attendance'] as List)
        : List<String>.from(data['attendanceMarked'] ?? []);

    // Get title/subject
    final title = data['title'] ?? data['subject'] ?? 'Без названия';
    final groupName = data['group'] is Map
        ? data['group']['name'] ?? '-'
        : data['groupName'] ?? '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Основная информация
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.class_,
                  label: 'Тип',
                  value: data['type'] ?? '-',
                ),
                _InfoRow(
                  icon: Icons.group,
                  label: 'Группа',
                  value: groupName,
                ),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Дата',
                  value: DateFormat('dd MMM yyyy', 'ru').format(date),
                ),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Время',
                  value: '${data['startTime'] ?? '-'} - ${data['endTime'] ?? '-'}',
                ),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Аудитория',
                  value: data['classroom'] ?? '-',
                ),
                if (data['description'] != null && data['description'].toString().isNotEmpty)
                  _InfoRow(
                    icon: Icons.notes,
                    label: 'Описание',
                    value: data['description'],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Статистика посещаемости
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Посещаемость',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      label: 'Присутствуют',
                      value: attendanceList.length.toString(),
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                    _StatCard(
                      label: 'Всего студентов',
                      value: (data['totalStudents'] ?? 0).toString(),
                      color: Colors.blue,
                      icon: Icons.people,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Список присутствующих
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Присутствующие студенты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                if (attendanceList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Пока никто не отметился',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else if (kIsWeb)
                  ...attendanceList.map((att) {
                    final name = att is Map
                        ? (att['student']?['name'] ?? att['studentId'] ?? 'Студент')
                        : att.toString();
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(name.toString()),
                      subtitle: const Text('Присутствует'),
                    );
                  })
                else
                  ...(attendanceList as List).map((studentId) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(studentId.toString())
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                          );
                        }

                        final userData = userSnapshot.data!.data()
                            as Map<String, dynamic>?;
                        final name = userData?['name'] ?? 'Студент';

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(name),
                          subtitle: const Text('Присутствует'),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Кнопка показа QR-кода
        ElevatedButton.icon(
          onPressed: () => _showQRCode(),
          icon: const Icon(Icons.qr_code),
          label: const Text('Показать QR-код'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _showQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrDisplayScreen(lessonId: widget.lessonId),
      ),
    );
  }

  Future<void> _deleteLesson() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить занятие?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (kIsWeb) {
          final apiService = ApiService();
          await apiService.delete('/lessons/${widget.lessonId}');
        } else {
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(widget.lessonId)
              .delete();
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Занятие удалено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
