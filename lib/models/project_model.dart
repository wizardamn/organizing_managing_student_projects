import 'package:flutter/material.dart';

// ----------------------------------------------------------------------
// ✅ ENUM: СТАТУС ПРОЕКТА
// ----------------------------------------------------------------------
enum ProjectStatus {
  planned, // 0
  inProgress, // 1
  completed, // 2
  archived, // 3
}

// ----------------------------------------------------------------------
// ✅ РАСШИРЕНИЕ ДЛЯ ОТОБРАЖЕНИЯ СТАТУСА И ЦВЕТА
// ----------------------------------------------------------------------
extension ProjectStatusExtension on ProjectStatus {
  String get text {
    switch (this) {
      case ProjectStatus.planned:
        return 'Запланирован';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.archived:
        return 'Архив';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planned:
        return Colors.blueGrey;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.archived:
        return Colors.brown;
    }
  }
}

// ----------------------------------------------------------------------
// ✅ МОДЕЛЬ ПРОЕКТА
// ----------------------------------------------------------------------
class ProjectModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final DateTime deadline;
  final int status; // Хранится как индекс enum для Supabase
  final double? grade;
  final List<String> participants;
  final List<String> attachments;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    this.grade,
    required this.participants,
    required this.attachments,
    required this.createdAt,
  });

  // Геттер для удобного доступа к статусу как к enum
  ProjectStatus get statusEnum => ProjectStatus.values[status];

  // ------------------------------------------------
  // ✅ FROM JSON (Десериализация из Supabase)
  // ------------------------------------------------
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Безопасное получение списка участников/вложений
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ProjectModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      // Преобразование строки ISO в DateTime
      deadline: DateTime.parse(json['deadline'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      // Статус должен быть int
      status: json['status'] as int? ?? ProjectStatus.planned.index,
      grade: json['grade'] as double?,
      participants: parseStringList(json['participants']),
      attachments: parseStringList(json['attachments']),
    );
  }

  // ------------------------------------------------
  // ✅ TO JSON (Сериализация для Supabase)
  // ------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      // ID не включается при добавлении, но нужен при обновлении
      if (id.isNotEmpty) 'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      // Сохраняем в UTC для базы данных
      'deadline': deadline.toUtc().toIso8601String(),
      'status': status,
      'grade': grade,
      'participants': participants,
      'attachments': attachments,
      // 'created_at' обычно устанавливается БД, но может быть полезен при создании
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}