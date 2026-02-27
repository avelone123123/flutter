import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:form_validator/form_validator.dart';
import '../../models/lesson_model.dart';
import '../../models/group_model.dart';
import '../../services/web_group_service.dart';
import '../../services/web_lesson_service.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/auth_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

/// Экран создания нового занятия
class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _classroomController = TextEditingController();
  final _notesController = TextEditingController();
  
  GroupModel? _selectedGroup;
  LessonType _selectedType = LessonType.lecture;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  
  bool _isLoading = false;
  bool _isLoadingGroups = true;
  List<GroupModel> _groups = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Отложенная загрузка групп после завершения build фазы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _classroomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Загрузка групп преподавателя
  Future<void> _loadGroups() async {
    final teacherId = AuthHelper.getCurrentUserId(context);

    if (teacherId != null) {
      if (kIsWeb) {
        // Web: использовать REST API
        try {
          final webService = WebGroupService();
          final groups = await webService.getTeacherGroups(teacherId);
          if (mounted) {
            setState(() {
              _groups = groups;
              _isLoadingGroups = false;
            });
          }
        } catch (e) {
          debugPrint('Error loading groups: $e');
          if (mounted) {
            setState(() {
              _isLoadingGroups = false;
            });
          }
        }
      } else {
        // Mobile: использовать Provider
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        await groupProvider.loadGroups(teacherId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое занятие'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Заголовок
                    Text(
                      'Создание нового занятия',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Заполните информацию о занятии',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Выбор группы
                    if (kIsWeb)
                      _buildGroupDropdown(_groups)
                    else
                      Consumer<GroupProvider>(
                        builder: (context, groupProvider, child) {
                          return _buildGroupDropdown(groupProvider.groups);
                        },
                      ),
                    const SizedBox(height: 16),

                    // Предмет
                    CustomTextField(
                      controller: _subjectController,
                      labelText: 'Предмет *',
                      hintText: 'Например: Программирование',
                      validator: ValidationBuilder()
                          .required('Введите предмет')
                          .minLength(2, 'Название предмета должно содержать минимум 2 символа')
                          .maxLength(100, 'Название предмета не должно превышать 100 символов')
                          .build(),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Тип занятия
                    DropdownButtonFormField<LessonType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Тип занятия *',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      items: LessonType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Дата занятия
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата занятия *',
                          border: OutlineInputBorder(),
                          filled: true,
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Время начала и окончания
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Время начала *',
                                border: OutlineInputBorder(),
                                filled: true,
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _startTime.format(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Время окончания *',
                                border: OutlineInputBorder(),
                                filled: true,
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _endTime.format(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Аудитория
                    CustomTextField(
                      controller: _classroomController,
                      labelText: 'Аудитория *',
                      hintText: 'Например: 101, А-201',
                      validator: ValidationBuilder()
                          .required('Введите аудиторию')
                          .minLength(1, 'Введите аудиторию')
                          .maxLength(50, 'Название аудитории не должно превышать 50 символов')
                          .build(),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Примечания
                    CustomTextField(
                      controller: _notesController,
                      labelText: 'Примечания',
                      hintText: 'Дополнительная информация о занятии (необязательно)',
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),

                    // Сообщение об ошибке
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Кнопка создания занятия
                    CustomButton(
                      text: 'Создать занятие',
                      onPressed: _createLesson,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Кнопка отмены
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Выбор даты
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  /// Выбор времени начала
  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
        // Автоматически устанавливаем время окончания на 1.5 часа позже
        final endTime = TimeOfDay(
          hour: (time.hour + 1) % 24,
          minute: (time.minute + 30) % 60,
        );
        _endTime = endTime;
      });
    }
  }

  /// Выбор времени окончания
  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  /// Создание занятия
  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGroup == null) {
      setState(() {
        _errorMessage = 'Выберите группу';
      });
      return;
    }

    // Проверяем, что время окончания больше времени начала
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (endMinutes <= startMinutes) {
      setState(() {
        _errorMessage = 'Время окончания должно быть больше времени начала';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Получаем ID преподавателя
      final teacherId = AuthHelper.getCurrentUserId(context);

      if (teacherId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Создаём занятие
      final lesson = LessonModel(
        id: '', // Будет установлен в сервисе
        groupId: _selectedGroup!.id,
        groupName: _selectedGroup!.name,
        subject: _subjectController.text.trim(),
        type: _selectedType,
        date: _selectedDate,
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        classroom: _classroomController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        teacherId: teacherId,
        qrCode: '', // Будет сгенерирован в сервисе
        qrValidFrom: DateTime.now(),
        qrValidUntil: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        attendanceMarked: const [],
      );

      bool success = false;
      
      if (kIsWeb) {
        // Web: использовать REST API
        try {
          final webService = WebLessonService();
          final lessonId = await webService.createLesson(lesson);
          success = lessonId.isNotEmpty;
        } catch (e) {
          debugPrint('Error creating lesson on web: $e');
          success = false;
        }
      } else {
        // Mobile: использовать Provider
        final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
        success = await lessonProvider.createLesson(lesson);
      }
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Занятие успешно создано'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Не удалось создать занятие';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка создания занятия: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Виджет выпадающего списка групп
  Widget _buildGroupDropdown(List<GroupModel> groups) {
    if (_isLoadingGroups) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Группа *',
          border: OutlineInputBorder(),
          filled: true,
        ),
        child: Text('Загрузка групп...'),
      );
    }

    return DropdownButtonFormField<GroupModel>(
      value: _selectedGroup,
      decoration: const InputDecoration(
        labelText: 'Группа *',
        hintText: 'Выберите группу',
        border: OutlineInputBorder(),
        filled: true,
      ),
      items: groups.map((group) {
        return DropdownMenuItem(
          value: group,
          child: Text(group.fullName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGroup = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Выберите группу';
        }
        return null;
      },
    );
  }
}
