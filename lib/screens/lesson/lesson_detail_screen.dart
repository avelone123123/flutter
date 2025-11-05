import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/screens/lesson/qr_display_screen_enhanced.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  Widget build(BuildContext context) {
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
          final date = (data['date'] as Timestamp).toDate();
          final attendanceList = List<String>.from(data['attendanceMarked'] ?? []);

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
                        data['subject'] ?? 'Без названия',
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
                        value: data['groupName'] ?? '-',
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
                      else
                        ...attendanceList.map((studentId) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(studentId)
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
                        }).toList(),
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
        },
      ),
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
        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .delete();

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
