import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/lesson_model.dart';
import '../../providers/lesson_provider.dart';
import '../../services/qr_service.dart';
import '../../widgets/qr_code_widget.dart';
import '../../widgets/loading_widget.dart';

/// Экран отображения QR-кода занятия
class QRDisplayScreen extends StatefulWidget {
  final LessonModel lesson;

  const QRDisplayScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final QRService _qrService = QRService();
  Timer? _timer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Запуск таймера обновления
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-код занятия'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshQR,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информация о занятии
            _buildLessonInfo(),
            const SizedBox(height: 24),

            // QR-код
            _buildQRCode(),
            const SizedBox(height: 24),

            // Таймер обратного отсчёта
            _buildCountdownTimer(),
            const SizedBox(height: 24),

            // Статистика посещаемости
            _buildAttendanceStats(),
            const SizedBox(height: 24),

            // Кнопки действий
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Информация о занятии
  Widget _buildLessonInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.subject,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.lesson.type.displayName} • ${widget.lesson.groupName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.lesson.dateString} • ${widget.lesson.timeRange}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Аудитория: ${widget.lesson.classroom}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.lesson.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Примечания: ${widget.lesson.notes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// QR-код
  Widget _buildQRCode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'QR-код для отметки посещаемости',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            QRCodeWidget(
              data: widget.lesson.qrCode,
              size: 250,
            ),
            const SizedBox(height: 16),
            Text(
              'Студенты должны отсканировать этот QR-код для отметки посещаемости',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Таймер обратного отсчёта
  Widget _buildCountdownTimer() {
    final timeUntilExpires = widget.lesson.timeUntilQrExpires;
    final isExpired = timeUntilExpires.isNegative;
    final totalMinutes = timeUntilExpires.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final seconds = timeUntilExpires.inSeconds % 60;

    return Card(
      color: isExpired 
          ? Theme.of(context).colorScheme.errorContainer
          : totalMinutes < 10 
              ? Theme.of(context).colorScheme.tertiaryContainer
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              isExpired ? Icons.timer_off : Icons.timer,
              size: 32,
              color: isExpired 
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : totalMinutes < 10 
                      ? Theme.of(context).colorScheme.onTertiaryContainer
                      : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              isExpired ? 'QR-код истёк' : 'Время действия QR-кода',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isExpired 
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : totalMinutes < 10 
                        ? Theme.of(context).colorScheme.onTertiaryContainer
                        : null,
              ),
            ),
            const SizedBox(height: 8),
            if (!isExpired)
              Text(
                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: totalMinutes < 10 
                      ? Theme.of(context).colorScheme.onTertiaryContainer
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            if (isExpired) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _refreshQR,
                icon: _isRefreshing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRefreshing ? 'Обновление...' : 'Обновить QR-код'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Статистика посещаемости
  Widget _buildAttendanceStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика посещаемости',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Отметились',
                  widget.lesson.attendanceMarked.length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Всего студентов',
                  '0', // Здесь нужно получить количество студентов группы
                  Icons.people,
                  Theme.of(context).colorScheme.primary,
                ),
                _buildStatItem(
                  'Процент',
                  '0%', // Здесь нужно вычислить процент
                  Icons.percent,
                  Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Элемент статистики
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Кнопки действий
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _refreshQR,
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isRefreshing ? 'Обновление...' : 'Обновить QR-код'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _endLesson,
            icon: const Icon(Icons.stop),
            label: const Text('Завершить занятие'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  /// Обновление QR-кода
  Future<void> _refreshQR() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      final success = await lessonProvider.refreshLessonQR(widget.lesson.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR-код обновлён'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка обновления QR-кода'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Завершение занятия
  Future<void> _endLesson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить занятие'),
        content: const Text('Вы уверены, что хотите завершить это занятие? После завершения студенты не смогут отмечать посещаемость.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
        final success = await lessonProvider.endLesson(widget.lesson.id);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Занятие завершено'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка завершения занятия'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
