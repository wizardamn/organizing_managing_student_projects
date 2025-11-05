import 'package:uuid/uuid.dart';

enum ProjectStatus { planned, inProgress, completed }

class Project {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final DateTime deadline;
  final ProjectStatus status;
  final double? grade;
  final List<String> attachments;
  final DateTime createdAt;
  final List<String> participants;

  Project({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    this.grade,
    required this.attachments,
    required this.createdAt,
    required this.participants,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id']?.toString() ?? const Uuid().v4(),
      ownerId: map['owner_id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'].toString())
          : DateTime.now(),
      status: ProjectStatus.values[
      (map['status'] ?? 0).clamp(0, ProjectStatus.values.length - 1)],
      grade: map['grade'] != null ? (map['grade'] as num).toDouble() : null,
      attachments: (map['attachments'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      participants: (map['participants'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'status': status.index,
      'grade': grade,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'participants': participants,
    };
  }

  factory Project.empty(String ownerId) {
    return Project(
      id: const Uuid().v4(),
      ownerId: ownerId,
      title: '',
      description: '',
      deadline: DateTime.now().add(const Duration(days: 7)),
      status: ProjectStatus.planned,
      grade: null,
      attachments: [],
      createdAt: DateTime.now(),
      participants: [],
    );
  }
}
