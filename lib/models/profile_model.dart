import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileModel {
  final String id;
  final String fullName;
  final String role;
  final DateTime createdAt;
  final String email;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.createdAt,
    required this.email,
  });

  /// Фабричный конструктор для создания модели из данных 'profiles'.
  /// Требует объект User для получения email.
  factory ProfileModel.fromJson(Map<String, dynamic> json, User user) {
    return ProfileModel(
      id: json['id'].toString(),
      // Берем имя из БД, fallback на email
      fullName: json['full_name'] as String? ?? user.email?.split('@').first ?? 'Неизвестно',
      role: json['role'] as String? ?? 'student',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      // Email берется из объекта User
      email: user.email ?? 'email-not-found@example.com',
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
}