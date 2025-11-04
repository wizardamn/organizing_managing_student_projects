import 'package:uuid/uuid.dart';

enum ProjectStatus { planned, inProgress, completed }

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

  factory Project.fromMap(Map<String, dynamic> map) {
    // Supabase returns nested fields as maps or lists, handle carefully
    final deadlineRaw = map['deadline'];
    DateTime parsedDeadline;
    if (deadlineRaw is String) {
      parsedDeadline = DateTime.tryParse(deadlineRaw) ?? DateTime.now();
    } else if (deadlineRaw is DateTime) {
      parsedDeadline = deadlineRaw;
    } else {
      parsedDeadline = DateTime.now();
    }

    return Project(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      deadline: parsedDeadline,
      status: ProjectStatus.values[(map['status'] ?? 0) as int],
      ownerId: (map['owner_id'] ?? '') as String,
      attachments: List<String>.from(map['attachments'] ?? []),
      grade: map['grade'] != null ? (map['grade'] as num).toDouble() : null,
      participants: List<String>.from(map['participants'] ?? []),
    );
  }

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
}
