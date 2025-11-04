// lib/services/project_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';

class ProjectService {
  final SupabaseClient _db = Supabase.instance.client;
  String? _ownerId;

  /// Устанавливает текущего владельца (пользователя)
  void updateOwner(String? newOwnerId) {
    _ownerId = newOwnerId;
  }

  /// Возвращает текущий идентификатор владельца
  String? get _effectiveOwnerId => _ownerId;

  /// Получает все проекты, где пользователь является владельцем или участником
  Future<List<Project>> getAll() async {
    final ownerId = _effectiveOwnerId;
    if (ownerId == null) return [];

    try {
      final data = await _db
          .from('projects')
          .select('*, project_members(member_id)')
          .or('owner_id.eq.$ownerId,project_members.member_id.eq.$ownerId')
          .order('deadline', ascending: true);

      if (data == null || data is! List) return [];

      return data.map<Project>((item) {
        final map = Map<String, dynamic>.from(item as Map);

        // Извлекаем участников
        final List<dynamic>? members = map['project_members'];
        if (members != null) {
          final participants = members
              .map((m) => (m is Map && m['member_id'] != null)
              ? m['member_id'].toString()
              : '')
              .where((id) => id.isNotEmpty)
              .toList();
          map['participants'] = participants;
        }

        return Project.fromMap(map);
      }).toList();
    } catch (e, st) {
      debugPrint("❌ Ошибка при получении проектов: $e\n$st");
      return [];
    }
  }

  /// Создает пустой проект для нового пользователя
  Project createEmpty() {
    final ownerId = _effectiveOwnerId;
    if (ownerId == null) throw Exception("ownerId не задан");
    return Project.empty(ownerId);
  }

  /// Добавляет новый проект в базу
  Future<void> add(Project p) async {
    try {
      await _db.from('projects').insert(p.toMap());

      if (p.participants.isNotEmpty) {
        final members = p.participants
            .map((uid) => {'project_id': p.id, 'member_id': uid})
            .toList();
        await _db.from('project_members').insert(members);
      }
    } catch (e, st) {
      debugPrint("❌ Ошибка при добавлении проекта: $e\n$st");
      rethrow;
    }
  }

  /// Обновляет данные проекта
  Future<void> update(Project p) async {
    try {
      await _db.from('projects').update(p.toMap()).eq('id', p.id);

      // Обновляем участников
      await _db.from('project_members').delete().eq('project_id', p.id);

      if (p.participants.isNotEmpty) {
        final members = p.participants
            .map((uid) => {'project_id': p.id, 'member_id': uid})
            .toList();
        await _db.from('project_members').insert(members);
      }
    } catch (e, st) {
      debugPrint("❌ Ошибка при обновлении проекта: $e\n$st");
      rethrow;
    }
  }

  /// Удаляет проект и связанных участников
  Future<void> delete(String id) async {
    try {
      await _db.from('project_members').delete().eq('project_id', id);
      await _db.from('projects').delete().eq('id', id);
    } catch (e, st) {
      debugPrint("❌ Ошибка при удалении проекта: $e\n$st");
      rethrow;
    }
  }
}
