import 'package:uuid/uuid.dart';

/// Статус проекта
enum ProjectStatus { planned, inProgress, completed }

/// Модель проекта
class Project {
  final String id;
  String title;
  String description;
  DateTime deadline;
  ProjectStatus status;
  final String ownerId;
  List<String> attachments;
  double? grade;
  List<String> participants;

  /// Конструктор проекта
  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.status = ProjectStatus.planned,
    required this.ownerId,
    this.attachments = const [],
    this.grade,
    this.participants = const [],
  });

  /// Создание объекта из Map (например, из Supabase)
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      deadline: DateTime.tryParse(map['deadline'] as String? ?? '') ?? DateTime.now(),
      status: ProjectStatus.values[
      (map['status'] is int) ? map['status'] as int : int.tryParse(map['status'].toString()) ?? 0],
      ownerId: map['owner_id'] as String? ?? '',
      attachments: _parseStringList(map['attachments']),
      grade: _parseGrade(map['grade']),
      participants: _parseStringList(map['participants']),
    );
  }

  /// Преобразование объекта в Map (для Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'status': status.index,
      'owner_id': ownerId,
      'attachments': attachments,
      'grade': grade,
      'participants': participants,
    };
  }

  /// Создание пустого проекта (по умолчанию: 7 дней на выполнение)
  static Project empty(String ownerId) {
    return Project(
      id: const Uuid().v4(),
      title: '',
      description: '',
      deadline: DateTime.now().add(const Duration(days: 7)),
      ownerId: ownerId,
      participants: [ownerId],
    );
  }

  /// Вспомогательный метод: парсинг списка строк
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List<dynamic>) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Вспомогательный метод: парсинг оценки
  static double? _parseGrade(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
