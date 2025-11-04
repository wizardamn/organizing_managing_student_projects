class ProjectModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final DateTime deadline;
  final int status; // можно позже заменить на enum ProjectStatus
  final double? grade;
  final List<String> attachments;
  final List<String> participants;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    this.grade,
    this.attachments = const [],
    this.participants = const [],
    required this.createdAt,
  });

  /// Фабричный конструктор для создания модели из JSON (например, Supabase)
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'].toString(),
      ownerId: json['owner_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now(),
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 0,
      grade: json['grade'] != null
          ? double.tryParse(json['grade'].toString())
          : null,
      attachments: (json['attachments'] is List)
          ? List<String>.from(json['attachments'])
          : [],
      participants: (json['participants'] is List)
          ? List<String>.from(json['participants'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Преобразование модели обратно в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'grade': grade,
      'attachments': attachments,
      'participants': participants,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Метод для создания копии с изменёнными полями
  ProjectModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    DateTime? deadline,
    int? status,
    double? grade,
    List<String>? attachments,
    List<String>? participants,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      attachments: attachments ?? this.attachments,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
