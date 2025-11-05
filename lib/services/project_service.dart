import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';

class ProjectService {
  final SupabaseClient _db = Supabase.instance.client;
  String? _ownerId;

  void updateOwner(String? newOwnerId) {
    _ownerId = newOwnerId;
  }

  String? get _effectiveOwnerId => _ownerId;

  Future<List<Project>> getAll() async {
    final ownerId = _effectiveOwnerId;
    if (ownerId == null) return [];

    try {
      final data = await _db
          .from('projects')
          .select()
          .or('owner_id.eq.$ownerId,participants.cs.{$ownerId}')
          .order('deadline', ascending: true);

      return (data as List)
          .map((e) => Project.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      debugPrint("Ошибка при получении проектов: $e\n$st");
      return [];
    }
  }

  Future<void> add(Project p) async {
    try {
      await _db.from('projects').insert(p.toMap());
    } catch (e) {
      debugPrint("Ошибка при добавлении проекта: $e");
    }
  }

  Future<void> update(Project p) async {
    try {
      await _db.from('projects').update(p.toMap()).eq('id', p.id);
    } catch (e) {
      debugPrint("Ошибка при обновлении проекта: $e");
    }
  }

  Future<void> delete(String id) async {
    try {
      await _db.from('projects').delete().eq('id', id);
    } catch (e) {
      debugPrint("Ошибка при удалении проекта: $e");
    }
  }
}
