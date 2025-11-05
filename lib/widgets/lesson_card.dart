import 'package:flutter/material.dart';
import '../models/lesson_model.dart';

/// Карточка занятия
class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback? onTap;
  final VoidCallback? onRefreshQR;
  final VoidCallback? onEndLesson;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.onRefreshQR,
    this.onEndLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.subject,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Информация о занятии
              Text(
                '${lesson.type.displayName} • ${lesson.groupName}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '${lesson.dateString} • ${lesson.timeRange}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'Аудитория: ${lesson.classroom}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Статистика посещаемости
              _buildAttendanceStats(context),
              
              const SizedBox(height: 16),
              
              // Кнопки действий
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Чип статуса
  Widget _buildStatusChip(BuildContext context) {
    if (lesson.isCurrentlyActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Активно',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (lesson.isQrExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Истёк',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Неактивно',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  /// Статистика посещаемости
  Widget _buildAttendanceStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          context,
          'Отметились',
          lesson.attendanceMarked.length.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          context,
          'Всего студентов',
          '0', // Здесь нужно получить количество студентов группы
          Icons.people,
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          context,
          'Процент',
          '0%', // Здесь нужно вычислить процент
          Icons.percent,
          Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  /// Элемент статистики
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onRefreshQR != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRefreshQR,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Обновить QR'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        
        if (onRefreshQR != null && onEndLesson != null)
          const SizedBox(width: 8),
        
        if (onEndLesson != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEndLesson,
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('Завершить'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
