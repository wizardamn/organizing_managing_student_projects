class ProfileModel {
  final String id;
  final String fullName;
  final String role;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  /// Фабричный конструктор для создания модели из JSON (например, из Supabase)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'student',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Преобразование модели обратно в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Создание копии с возможностью изменения отдельных полей
  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
