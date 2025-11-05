import 'package:flutter/material.dart';
import '../../models/faq_model.dart';

/// Экран помощи и FAQ
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<FAQModel> _faqs = [
    FAQModel(
      id: '1',
      category: 'general',
      order: 1,
      createdAt: DateTime.now(),
      question: 'Как создать группу?',
      answer: 'Для создания группы перейдите в раздел "Группы" и нажмите кнопку "Создать группу". Заполните необходимые поля и сохраните.',
    ),
    FAQModel(
      id: '2',
      category: 'general',
      order: 2,
      createdAt: DateTime.now(),
      question: 'Как создать занятие?',
      answer: 'Для создания занятия перейдите в раздел "Занятия" и нажмите кнопку "Новое занятие". Выберите группу, заполните детали занятия и сохраните.',
    ),
    FAQModel(
      id: '3',
      category: 'qrCode',
      order: 3,
      createdAt: DateTime.now(),
      question: 'Как сгенерировать QR-код?',
      answer: 'QR-код генерируется автоматически при создании занятия. Для отображения QR-кода перейдите в раздел "QR-код" и выберите активное занятие.',
    ),
    FAQModel(
      id: '4',
      category: 'reports',
      order: 4,
      createdAt: DateTime.now(),
      question: 'Как просмотреть отчеты?',
      answer: 'Для просмотра отчетов перейдите в раздел "Отчеты". Там вы можете выбрать группу и просмотреть статистику посещаемости.',
    ),
    FAQModel(
      id: '5',
      category: 'profile',
      order: 5,
      createdAt: DateTime.now(),
      question: 'Как изменить настройки уведомлений?',
      answer: 'Для изменения настроек уведомлений перейдите в профиль и выберите "Уведомления". Там вы можете настроить типы уведомлений и время напоминаний.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Часто задаваемые вопросы',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FAQ список
            ..._faqs.map((faq) => _buildFAQItem(context, faq)).toList(),
            
            const SizedBox(height: 32),
            
            // Контакты
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Нужна дополнительная помощь?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Если вы не нашли ответ на свой вопрос, обратитесь к администратору системы или отправьте сообщение в службу поддержки.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Открыть форму обратной связи
                            },
                            icon: const Icon(Icons.email),
                            label: const Text('Написать в поддержку'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Показать контакты
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Контакты'),
                          ),
                        ),
                      ],
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

  /// Элемент FAQ
  Widget _buildFAQItem(BuildContext context, FAQModel faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
