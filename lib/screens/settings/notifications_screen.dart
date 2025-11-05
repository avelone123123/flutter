import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_button.dart';

/// Экран настроек уведомлений
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  AppNotificationSettings _settings = AppNotificationSettings();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Загрузка настроек уведомлений
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _notificationService.getNotificationSettings();
      setState(() {
        _settings = settings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки настроек: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Сохранение настроек
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.updateNotificationSettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки уведомлений сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения настроек: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Отправка тестового уведомления
  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовое уведомление отправлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки уведомления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Общие настройки
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Общие настройки',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Все уведомления'),
                            subtitle: const Text('Включить/выключить все уведомления'),
                            value: _settings.allNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  allNotificationsEnabled: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Типы уведомлений
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Типы уведомлений',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Новые занятия'),
                            subtitle: const Text('Уведомления о новых занятиях'),
                            value: _settings.newLessons,
                            onChanged: _settings.allNotificationsEnabled ? (value) {
                              setState(() {
                                _settings = _settings.copyWith(newLessons: value);
                              });
                            } : null,
                          ),
                          SwitchListTile(
                            title: const Text('Изменения расписания'),
                            subtitle: const Text('Уведомления об изменениях в расписании'),
                            value: _settings.scheduleChanges,
                            onChanged: _settings.allNotificationsEnabled ? (value) {
                              setState(() {
                                _settings = _settings.copyWith(scheduleChanges: value);
                              });
                            } : null,
                          ),
                          SwitchListTile(
                            title: const Text('Напоминания о занятиях'),
                            subtitle: const Text('Напоминания перед началом занятий'),
                            value: _settings.lessonReminders,
                            onChanged: _settings.allNotificationsEnabled ? (value) {
                              setState(() {
                                _settings = _settings.copyWith(lessonReminders: value);
                              });
                            } : null,
                          ),
                          SwitchListTile(
                            title: const Text('Еженедельные отчеты'),
                            subtitle: const Text('Отчеты о посещаемости'),
                            value: _settings.weeklyReport,
                            onChanged: _settings.allNotificationsEnabled ? (value) {
                              setState(() {
                                _settings = _settings.copyWith(weeklyReport: value);
                              });
                            } : null,
                          ),
                          SwitchListTile(
                            title: const Text('Сообщения преподавателя'),
                            subtitle: const Text('Уведомления от преподавателя'),
                            value: _settings.teacherMessages,
                            onChanged: _settings.allNotificationsEnabled ? (value) {
                              setState(() {
                                _settings = _settings.copyWith(teacherMessages: value);
                              });
                            } : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Время напоминаний
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Время напоминаний',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Напоминать за'),
                            subtitle: Text(_settings.reminderTime),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _settings.allNotificationsEnabled ? _selectReminderTime : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Тестирование
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Тестирование',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _sendTestNotification,
                              icon: const Icon(Icons.notifications),
                              label: const Text('Отправить тестовое уведомление'),
                            ),
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

  /// Выбор времени напоминания
  Future<void> _selectReminderTime() async {
    final options = [
      '15 минут до',
      '30 минут до',
      '1 час до',
      '2 часа до',
      '1 день до',
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите время напоминания'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(option),
              onTap: () => Navigator.of(context).pop(option),
              selected: option == _settings.reminderTime,
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _settings = _settings.copyWith(reminderTime: result);
      });
    }
  }
}
