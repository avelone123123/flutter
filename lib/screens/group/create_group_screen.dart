import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_validator/form_validator.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../utils/auth_helper.dart';
import '../../utils/router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

/// Экран создания новой группы
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _selectedYear = 1;
  bool _isLoading = false;
  String? _errorMessage;

  final List<int> _years = [1, 2, 3, 4];
  final List<String> _courses = [
    'Информатика',
    'Математика',
    'Физика',
    'Химия',
    'Биология',
    'Экономика',
    'Право',
    'Психология',
    'Лингвистика',
    'История',
    'Философия',
    'Другое',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать группу'),
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
                      'Создание новой группы студентов',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Заполните информацию о группе',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Название группы
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Название группы *',
                      hintText: 'Например: ИТ-21-1',
                      validator: ValidationBuilder()
                          .required('Введите название группы')
                          .minLength(2, 'Название должно содержать минимум 2 символа')
                          .maxLength(50, 'Название не должно превышать 50 символов')
                          .build(),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Курс/факультет
                    DropdownButtonFormField<String>(
                      value: _courseController.text.isNotEmpty ? _courseController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Курс/факультет *',
                        hintText: 'Выберите курс',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _courseController.text = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите курс/факультет';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Год обучения
                    DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Год обучения *',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year курс'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Описание группы
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: 'Описание группы',
                      hintText: 'Дополнительная информация о группе (необязательно)',
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

                    // Кнопка создания группы
                    CustomButton(
                      text: 'Создать группу',
                      onPressed: _createGroup,
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

  /// Создание группы
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
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

      // Проверяем, существует ли группа с таким названием
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final nameExists = await groupProvider.isGroupNameExists(teacherId, _nameController.text.trim());
      
      if (nameExists) {
        setState(() {
          _errorMessage = 'Группа с таким названием уже существует';
        });
        return;
      }

      // Создаём группу
      final group = GroupModel(
        id: '', // Будет установлен в сервисе
        name: _nameController.text.trim(),
        course: _courseController.text.trim(),
        year: _selectedYear,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        studentIds: const [],
        teacherId: teacherId,
        createdAt: DateTime.now(),
      );

      final success = await groupProvider.createGroup(group);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Группа успешно создана'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'Не удалось создать группу';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка создания группы: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
