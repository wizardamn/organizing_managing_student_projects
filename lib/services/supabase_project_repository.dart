import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';

class SupabaseProjectRepository {
  final SupabaseClient _db = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  String? _ownerId;

  void updateOwner(String? newOwnerId) {
    _ownerId = newOwnerId;
  }

  /// Получить все проекты, где пользователь - владелец или участник
  Future<List<Project>> getAll({String? ownerId}) async {
    final String? effectiveOwnerId = ownerId ?? _ownerId;
    if (effectiveOwnerId == null) return [];

    try {
      final response = await _db
          .from('projects')
          .select('*, project_members(member_id)')
          .or('owner_id.eq.$effectiveOwnerId,project_members.member_id.eq.$effectiveOwnerId')
          .order('deadline', ascending: true);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      return data.map((e) => Project.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Ошибка при получении проектов: $e');
      return [];
    }
  }

  /// Создать пустой проект
  Project createEmpty({String? ownerId}) {
    final String? effectiveOwnerId = ownerId ?? _ownerId;
    if (effectiveOwnerId == null) {
      throw Exception('ownerId не задан');
    }

    return Project(
      id: _uuid.v4(),
      title: '',
      description: '',
      deadline: DateTime.now().add(const Duration(days: 7)),
      ownerId: effectiveOwnerId,
      participants: [effectiveOwnerId],
    );
  }

  /// Добавить проект и участников
  Future<void> add(Project p) async {
    try {
      // 1. Добавляем сам проект
      await _db.from('projects').insert(p.toMap());

      // 2. Добавляем участников проекта
      final members = p.participants
          .map((uid) => {'project_id': p.id, 'member_id': uid})
          .toList();
      if (members.isNotEmpty) {
        await _db.from('project_members').insert(members);
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении проекта: $e');
      rethrow;
    }
  }

  /// Обновить проект и участников
  Future<void> update(Project p) async {
    try {
      // 1. Обновляем проект
      await _db.from('projects').update(p.toMap()).eq('id', p.id);

      // 2. Удаляем старых участников
      await _db.from('project_members').delete().eq('project_id', p.id);

      // 3. Добавляем новых участников
      final members = p.participants
          .map((uid) => {'project_id': p.id, 'member_id': uid})
          .toList();
      if (members.isNotEmpty) {
        await _db.from('project_members').insert(members);
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении проекта: $e');
      rethrow;
    }
  }

  /// Удалить проект и участников
  Future<void> delete(String id) async {
    try {
      // 1. Удалить проект
      await _db.from('projects').delete().eq('id', id);

      // 2. Удалить участников проекта
      await _db.from('project_members').delete().eq('project_id', id);
    } catch (e) {
      debugPrint('Ошибка при удалении проекта: $e');
      rethrow;
    }
  }
}
