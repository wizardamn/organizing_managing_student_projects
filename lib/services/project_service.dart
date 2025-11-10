import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
//import '../models/profile_model.dart';

class ProjectService {
  final SupabaseClient client = Supabase.instance.client;
  String? _currentUserId;

  void updateOwner(String? userId) {
    _currentUserId = userId;
  }

  // ------------------------------------------------
  // ✅ ЗАГРУЗКА
  // ------------------------------------------------
  /// Получить ВСЕ проекты, связанные с текущим пользователем (владелец ИЛИ участник).
  Future<List<ProjectModel>> getAll() async {
    if (_currentUserId == null) return [];

    try {
      final String userId = _currentUserId!;

      // 1. Получаем проекты, где пользователь является владельцем
      final ownerProjects = await client
          .from('projects')
          .select()
          .eq('owner_id', userId);

      // 2. Находим ID проектов, где пользователь является участником
      final memberProjectIdsData = await client
          .from('project_members')
          .select('project_id')
          .eq('member_id', userId);

      // 💡 Supabase возвращает List<Map<String, dynamic>>, нам нужны List<String> ID
      final memberProjectIds = memberProjectIdsData
          .map((e) => e['project_id'].toString())
          .toList();

      // 3. Получаем сами проекты по найденным ID
      List<Map<String, dynamic>> memberProjects = [];

      // ✅ ИСПРАВЛЕНИЕ 1: Дополнительная проверка на пустой список перед вызовом .inFilter
      if (memberProjectIds.isNotEmpty) {
        memberProjects = await client
            .from('projects')
            .select()
        // ✅ ИСПРАВЛЕНО: используем inFilter() для фильтрации по списку ID
            .inFilter('id', memberProjectIds)
            .neq('owner_id', userId); // Исключаем, если уже владелец
      }

      // Объединяем результаты
      final allData = [...ownerProjects, ...memberProjects];

      // Конвертируем в модели и сортируем
      return allData
          .map((data) => ProjectModel.fromJson(data))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    } catch (e) {
      // 💡 Рекомендуется использовать пакет logging для production
      throw Exception('Ошибка при загрузке проектов: ${e.toString()}');
    }
  }

  /// Получить проект по ID
  Future<ProjectModel?> getById(String id) async {
    final data = await client
        .from('projects')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return ProjectModel.fromJson(data);
  }

  // ------------------------------------------------
  // ✅ CRUD
  // ------------------------------------------------
  /// Создать проект
  Future<void> add(ProjectModel project) async {
    // 💡 При создании проекта, также нужно создать записи в project_members
    await client.from('projects').insert(project.toJson());

    // Добавляем всех участников (включая владельца)
    final projectId = project.id;
    final ownerId = project.ownerId;

    // Вставляем владельца как первого участника (роль "owner")
    if (ownerId.isNotEmpty) {
      await addParticipant(projectId, ownerId, "owner");
    }

    // Добавляем остальных участников (роль "editor" по умолчанию)
    for (var memberId in project.participants) {
      if (memberId != ownerId) {
        await addParticipant(projectId, memberId, "editor");
      }
    }
  }

  /// Обновить проект
  Future<void> update(ProjectModel project) async {
    await client.from('projects').update(project.toJson()).eq('id', project.id);

    // 💡 ЛОГИКА УЧАСТНИКОВ:
    // Поскольку `update` вызывается из формы, где участники могут измениться,
    // мы должны синхронизировать таблицу `project_members`.
    final currentMembers = await getParticipantIds(project.id);
    final desiredMembers = project.participants;
    final ownerId = project.ownerId; // Владелец всегда должен быть в списке

    // 1. Удаляем тех, кого нет в желаемом списке (кроме владельца)
    final membersToRemove = currentMembers.where((id) => !desiredMembers.contains(id) && id != ownerId).toList();
    for (var memberId in membersToRemove) {
      await removeParticipant(project.id, memberId);
    }

    // 2. Добавляем тех, кого нет в текущем списке
    final membersToAdd = desiredMembers.where((id) => !currentMembers.contains(id)).toList();
    for (var memberId in membersToAdd) {
      // Роль по умолчанию - 'editor'
      await addParticipant(project.id, memberId, memberId == ownerId ? "owner" : "editor");
    }
  }

  /// Удалить проект
  Future<void> delete(String id) async {
    // 💡 Каскадное удаление в Supabase должно удалять связанные записи в project_members,
    // но на всякий случай явно удаляем участников и проект.
    await client.from('project_members').delete().eq('project_id', id);
    await client.from('projects').delete().eq('id', id);
  }

  // ------------------------------------------------
  // ✅ УЧАСТНИКИ
  // ------------------------------------------------

  /// Вспомогательная функция для получения списка ID участников
  Future<List<String>> getParticipantIds(String projectId) async {
    final data = await client
        .from('project_members')
        .select('member_id')
        .eq('project_id', projectId);

    return data.map<String>((e) => e['member_id'].toString()).toList();
  }

  /// Получить всех участников проекта
  /// Возвращает данные с джойном profiles (full_name, role)
  Future<List<Map<String, dynamic>>> getParticipants(String projectId) async {
    final data = await client
        .from('project_members')
    // 💡 Выборка с джойном, как и планировалось
        .select('member_id, role, profile:profiles(full_name, role, email)') // Добавляем email
        .eq('project_id', projectId);

    return data;
  }

  /// Добавить участника в project_members
  Future<void> addParticipant(String projectId, String memberId, [String role = "editor"]) async {
    await client.from('project_members').upsert({ // Используем upsert, чтобы избежать дубликатов
      'project_id': projectId,
      'member_id': memberId,
      'role': role,
    });
  }

  /// Удалить участника из project_members
  Future<void> removeParticipant(String projectId, String memberId) async {
    await client
        .from('project_members')
        .delete()
        .match({'project_id': projectId, 'member_id': memberId});
  }
}