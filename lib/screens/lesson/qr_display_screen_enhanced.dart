import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/services/web_lesson_service.dart';
import '../../services/api_service.dart';
import 'dart:async';

class QrDisplayScreen extends StatefulWidget {
  final String lessonId;

  const QrDisplayScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  Map<String, dynamic>? _lessonData;
  String? _qrCode;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLessonData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (kIsWeb) {
        // Web: использовать REST API
        final webService = WebLessonService();
        final lesson = await webService.getLesson(widget.lessonId);
        
        if (lesson == null) {
          throw Exception('Занятие не найдено');
        }

        if (!mounted) return;
        setState(() {
          _lessonData = lesson.toJson();
          _qrCode = lesson.qrCode ?? widget.lessonId;
          _isLoading = false;
        });

        if (lesson.qrValidUntil != null) {
          _startTimer(lesson.qrValidUntil!);
        }
      } else {
        // Mobile: использовать Firebase
        final doc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .get();

        if (!doc.exists) {
          throw Exception('Занятие не найдено');
        }

        final data = doc.data()!;
        final qrValidUntil = (data['qrValidUntil'] as Timestamp?)?.toDate();

        if (!mounted) return;
        setState(() {
          _lessonData = data;
          _qrCode = data['qrCode'] ?? widget.lessonId;
          _isLoading = false;
        });

        if (qrValidUntil != null) {
          _startTimer(qrValidUntil);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer(DateTime endTime) {
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      final difference = endTime.difference(now).inSeconds;

      if (difference <= 0) {
        timer.cancel();
        if (mounted) setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds = difference);
      }
    });
  }

  Future<void> _refreshQrCode() async {
    try {
      // Генерация нового QR-кода
      final newQrCode = 'lesson_${widget.lessonId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final validUntil = now.add(const Duration(hours: 2));

      if (kIsWeb) {
        final apiService = ApiService();
        await apiService.refreshLessonQR(widget.lessonId, newQrCode);
      } else {
        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .update({
          'qrCode': newQrCode,
          'qrValidFrom': Timestamp.fromDate(now),
          'qrValidUntil': Timestamp.fromDate(validUntil),
        });
      }

      setState(() => _qrCode = newQrCode);
      _startTimer(validUntil);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR-код обновлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления QR-кода: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}ч ${minutes}м ${secs}с';
    } else if (minutes > 0) {
      return '${minutes}м ${secs}с';
    } else {
      return '${secs}с';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR-код занятия')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR-код занятия')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLessonData,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-код занятия'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQrCode,
            tooltip: 'Обновить QR-код',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Информация о занятии
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lessonData?['subject'] ?? 'Занятие',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Группа: ${_lessonData?['groupName'] ?? '-'}'),
                    Text('Тип: ${_lessonData?['type'] ?? '-'}'),
                    Text('Аудитория: ${_lessonData?['classroom'] ?? '-'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // QR-код
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _qrCode != null
                  ? QrImageView(
                      data: _qrCode!,
                      version: QrVersions.auto,
                      size: 280,
                      backgroundColor: Colors.white,
                    )
                  : const Text('QR-код не сгенерирован'),
            ),

            const SizedBox(height: 24),

            // Таймер
            if (_remainingSeconds > 0)
              Card(
                color: _remainingSeconds < 300
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: _remainingSeconds < 300
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QR действителен: ${_formatTime(_remainingSeconds)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds < 300
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Статистика посещаемости
            if (kIsWeb)
              _buildWebAttendanceCard()
            else
              StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .doc(widget.lessonId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final attendanceList = data?['attendanceMarked'] as List? ?? [];

                return _buildAttendanceCard(attendanceList, isWeb: false);
              },
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _refreshQrCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить QR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Закрыть занятие'),
                          content: const Text(
                            'Вы уверены? После закрытия студенты не смогут отметить посещаемость.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Закрыть'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        if (kIsWeb) {
                          final apiService = ApiService();
                          await apiService.endLesson(widget.lessonId);
                        } else {
                          await FirebaseFirestore.instance
                              .collection('lessons')
                              .doc(widget.lessonId)
                              .update({
                            'qrValidUntil': Timestamp.fromDate(DateTime.now()),
                            'closed': true,
                          });
                        }

                        if (mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Закрыть'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Инструкция
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Инструкция',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Покажите QR-код студентам\n'
                      '2. Студенты сканируют его на своих устройствах\n'
                      '3. Посещаемость автоматически отмечается\n'
                      '4. Следите за списком отметившихся в реальном времени',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAttendanceCard() {
    final attendanceList = _lessonData?['attendance'] as List? ?? [];
    return _buildAttendanceCard(attendanceList, isWeb: true);
  }

  Widget _buildAttendanceCard(List attendanceList, {required bool isWeb}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Отметились:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    '${attendanceList.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                ),
              ],
            ),
            if (attendanceList.isNotEmpty) ...[
              const Divider(),
              ...attendanceList.map((item) {
                String name;
                if (isWeb && item is Map) {
                  name = item['student']?['name'] ?? item['studentId'] ?? 'Студент';
                } else {
                  name = item.toString();
                }
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  title: Text(name),
                  trailing: const Text(
                    'Присутствует',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
