/// Модель вопроса и ответа для FAQ
class FAQModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final bool isExpanded;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FAQModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
    this.isExpanded = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Создание модели из Map
  factory FAQModel.fromMap(Map<String, dynamic> map) {
    return FAQModel(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'Общие',
      order: map['order'] ?? 0,
      isExpanded: map['isExpanded'] ?? false,
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt'] 
          : null,
    );
  }

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'isExpanded': isExpanded,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Создание копии с изменениями
  FAQModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    int? order,
    bool? isExpanded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FAQModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FAQModel(id: $id, question: $question, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FAQModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Категории FAQ
enum FAQCategory {
  general('Общие вопросы'),
  attendance('Посещаемость'),
  qrCode('QR-коды'),
  groups('Группы'),
  lessons('Занятия'),
  reports('Отчёты'),
  profile('Профиль'),
  technical('Технические вопросы');

  const FAQCategory(this.displayName);
  final String displayName;

  static FAQCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'общие вопросы':
      case 'general':
        return FAQCategory.general;
      case 'посещаемость':
      case 'attendance':
        return FAQCategory.attendance;
      case 'qr-коды':
      case 'qr codes':
        return FAQCategory.qrCode;
      case 'группы':
      case 'groups':
        return FAQCategory.groups;
      case 'занятия':
      case 'lessons':
        return FAQCategory.lessons;
      case 'отчёты':
      case 'reports':
        return FAQCategory.reports;
      case 'профиль':
      case 'profile':
        return FAQCategory.profile;
      case 'технические вопросы':
      case 'technical':
        return FAQCategory.technical;
      default:
        return FAQCategory.general;
    }
  }
}
