import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/lesson_model.dart';
import '../../providers/lesson_provider.dart';
import '../../utils/auth_helper.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/loading_widget.dart';
import 'qr_display_screen.dart';

/// Экран активных занятий
class ActiveLessonsScreen extends StatefulWidget {
  const ActiveLessonsScreen({super.key});

  @override
  State<ActiveLessonsScreen> createState() => _ActiveLessonsScreenState();
}

class _ActiveLessonsScreenState extends State<ActiveLessonsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActiveLessons();
  }

  /// Загрузка активных занятий
  Future<void> _loadActiveLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacherId = AuthHelper.getCurrentUserId(context);

      if (teacherId != null) {
        final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
        await lessonProvider.loadActiveLessons(teacherId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки активных занятий: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-коды занятий'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveLessons,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Consumer<LessonProvider>(
              builder: (context, lessonProvider, child) {
                if (lessonProvider.errorMessage != null) {
                  return _buildErrorWidget(lessonProvider.errorMessage!);
                }

                if (lessonProvider.activeLessons.isEmpty) {
                  return _buildEmptyWidget();
                }

                return RefreshIndicator(
                  onRefresh: _loadActiveLessons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessonProvider.activeLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessonProvider.activeLessons[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LessonCard(
                          lesson: lesson,
                          onTap: () => _openQRDisplay(lesson),
                          onRefreshQR: () => _refreshQR(lesson.id),
                          onEndLesson: () => _endLesson(lesson.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  /// Виджет ошибки
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadActiveLessons,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет пустого состояния
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет активных занятий',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте новое занятие, чтобы начать отмечать посещаемость',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.add),
              label: const Text('Создать занятие'),
            ),
          ],
        ),
      ),
    );
  }

  /// Открытие экрана с QR-кодом
  void _openQRDisplay(LessonModel lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRDisplayScreen(lesson: lesson),
      ),
    );
  }

  /// Обновление QR-кода
  Future<void> _refreshQR(String lessonId) async {
    try {
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      final success = await lessonProvider.refreshLessonQR(lessonId);
      
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
    }
  }

  /// Завершение занятия
  Future<void> _endLesson(String lessonId) async {
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
        final success = await lessonProvider.endLesson(lessonId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Занятие завершено'),
              backgroundColor: Colors.green,
            ),
          );
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
