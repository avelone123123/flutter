import 'package:flutter/material.dart';

/// Виджет пустого состояния
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customIcon;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка
            if (customIcon != null)
              customIcon!
            else
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            const SizedBox(height: 16),
            
            // Заголовок
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Сообщение
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Кнопка (если есть)
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет пустого состояния для списков
class EmptyListWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final IconData? icon;

  const EmptyListWidget({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon ?? Icons.list_alt,
      title: title,
      message: message,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}

/// Виджет пустого состояния для поиска
class EmptySearchWidget extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const EmptySearchWidget({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Ничего не найдено',
      message: 'По запросу "$query" ничего не найдено. Попробуйте изменить поисковый запрос.',
      buttonText: onClearSearch != null ? 'Очистить поиск' : null,
      onButtonPressed: onClearSearch,
    );
  }
}

/// Виджет пустого состояния для ошибок
class EmptyErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const EmptyErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon ?? Icons.error_outline,
      title: title,
      message: message,
      buttonText: onRetry != null ? 'Повторить' : null,
      onButtonPressed: onRetry,
      customIcon: Icon(
        icon ?? Icons.error_outline,
        size: 64,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Виджет пустого состояния для групп
class EmptyGroupsWidget extends StatelessWidget {
  final VoidCallback? onCreateGroup;

  const EmptyGroupsWidget({
    super.key,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.group_add,
      title: 'Нет групп',
      message: 'У вас пока нет созданных групп. Создайте первую группу, чтобы начать работу.',
      buttonText: onCreateGroup != null ? 'Создать группу' : null,
      onButtonPressed: onCreateGroup,
    );
  }
}

/// Виджет пустого состояния для занятий
class EmptyLessonsWidget extends StatelessWidget {
  final VoidCallback? onCreateLesson;

  const EmptyLessonsWidget({
    super.key,
    this.onCreateLesson,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
        icon: Icons.add,
      title: 'Нет занятий',
      message: 'У вас пока нет созданных занятий. Создайте первое занятие, чтобы начать отмечать посещаемость.',
      buttonText: onCreateLesson != null ? 'Создать занятие' : null,
      onButtonPressed: onCreateLesson,
    );
  }
}

/// Виджет пустого состояния для студентов
class EmptyStudentsWidget extends StatelessWidget {
  final VoidCallback? onAddStudents;

  const EmptyStudentsWidget({
    super.key,
    this.onAddStudents,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.person_add,
      title: 'Нет студентов',
      message: 'В этой группе пока нет студентов. Добавьте студентов, чтобы начать отмечать посещаемость.',
      buttonText: onAddStudents != null ? 'Добавить студентов' : null,
      onButtonPressed: onAddStudents,
    );
  }
}
