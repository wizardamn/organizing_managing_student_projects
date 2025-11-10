import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

// ----------------------------------------------------------------------
// ✅ ENUM'ы
// ----------------------------------------------------------------------
enum ProjectFilter { all, inProgressOnly }
enum SortBy { deadlineAsc, deadlineDesc, status }

// ----------------------------------------------------------------------
// ✅ PROJECT PROVIDER
// ----------------------------------------------------------------------
class ProjectProvider extends ChangeNotifier {
  final ProjectService _service;

  bool isGuest = true;
  bool isLoading = false;

  String? _userId;
  String _currentUserName = 'Гость'; // 💡 Для синхронизации с ProfileScreen

  final List<ProjectModel> _projects = [];

  SortBy _sortBy = SortBy.deadlineAsc;
  ProjectFilter _filter = ProjectFilter.all;

  // 💡 ИСПРАВЛЕНИЕ: Добавлен необязательный именованный параметр userId
  ProjectProvider(this._service, {String? userId}) {
    // Начальная установка владельца, если ID передан при запуске (например, при перезапуске сессии)
    if (userId != null) {
      _userId = userId;
      isGuest = false;
      _service.updateOwner(_userId);
      // Примечание: _currentUserName будет 'Гость', пока не будет вызван setUser/LoginWrapper.
    }
  }

  // ------------------------------------------------
  // ✅ ГЕТТЕРЫ
  // ------------------------------------------------
  String get currentUserName => _currentUserName;

  // ------------------------------------------------
  // ✅ ИНИЦИАЛИЗАЦИЯ
  // ------------------------------------------------
  /// Устанавливает пользователя, его имя и загружает проекты (вызывается после успешного входа)
  Future<void> setUser(String userId, String userName) async {
    _userId = userId;
    _currentUserName = userName; // ✅ Установка имени
    isGuest = false;

    _service.updateOwner(_userId);
    await fetchProjects();
  }

  /// Устанавливает имя пользователя (вызывается из ProfileScreen)
  void updateUserName(String newName) {
    if (_currentUserName != newName) {
      _currentUserName = newName;
      notifyListeners();
    }
  }

  /// Очищает состояние после выхода
  void clear({bool keepProjects = false}) {
    isGuest = true;
    _userId = null;
    _currentUserName = 'Гость';
    _service.updateOwner(null);

    if (!keepProjects) {
      _projects.clear();
    }

    notifyListeners();
  }

  // ------------------------------------------------
  // ✅ VIEW (сортировка + фильтрация)
  // ------------------------------------------------
  List<ProjectModel> get view {
    var result = [..._projects];

    // ✅ ФИЛЬТРАЦИЯ
    if (_filter == ProjectFilter.inProgressOnly) {
      result = result
          .where((p) => p.statusEnum == ProjectStatus.inProgress)
          .toList();
    }

    // ✅ СОРТИРОВКА
    switch (_sortBy) {
      case SortBy.deadlineAsc:
        result.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case SortBy.deadlineDesc:
        result.sort((a, b) => b.deadline.compareTo(a.deadline));
        break;
      case SortBy.status:
      // Сортировка по enum.index
        result.sort((a, b) => a.statusEnum.index.compareTo(b.statusEnum.index));
        break;
    }

    return result;
  }

  // ------------------------------------------------
  // ✅ ЗАГРУЗКА ПРОЕКТОВ
  // ------------------------------------------------
  Future<void> fetchProjects() async {
    if (isGuest || _userId == null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final loaded = await _service.getAll();

      _projects
        ..clear()
        ..addAll(loaded);
    } catch (e, st) {
      debugPrint("fetchProjects error: $e\n$st");
      _projects.clear();
    }

    isLoading = false;
    notifyListeners();
  }

  // ------------------------------------------------
  // ✅ СОРТИРОВКА И ФИЛЬТР
  // ------------------------------------------------
  void setSort(SortBy sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setFilter(ProjectFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  // ------------------------------------------------
  // ✅ CRUD ПРОЕКТОВ
  // ------------------------------------------------
  Future<void> addProject(ProjectModel p) async {
    if (isGuest) return;

    await _service.add(p);
    await fetchProjects();
  }

  Future<void> updateProject(ProjectModel p) async {
    if (isGuest) return;

    await _service.update(p);
    await fetchProjects();
  }

  Future<void> deleteProject(String id) async {
    if (isGuest) return;

    await _service.delete(id);
    await fetchProjects();
  }

  // ------------------------------------------------
  // ✅ УЧАСТНИКИ
  // ------------------------------------------------
  Future<List<Map<String, dynamic>>> getParticipants(String projectId) async {
    try {
      // 💡 Предполагаем, что сервис получает участников, а не ProjectProvider
      return await _service.getParticipants(projectId);
    } catch (e) {
      debugPrint("getParticipants error: $e");
      return [];
    }
  }

  Future<void> addParticipant(String projectId, String userId) async {
    if (isGuest) return;

    await _service.addParticipant(projectId, userId);
    await _refreshSingle(projectId);
  }

  Future<void> removeParticipant(String projectId, String userId) async {
    if (isGuest) return;

    await _service.removeParticipant(projectId, userId);
    await _refreshSingle(projectId);
  }

  // ------------------------------------------------
  // ✅ ОБНОВЛЕНИЕ ОДНОГО ПРОЕКТА
  // ------------------------------------------------
  Future<void> _refreshSingle(String projectId) async {
    try {
      final updated = await _service.getById(projectId);

      if (updated == null) return;

      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = updated;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("_refreshSingle error: $e");
    }
  }

  // ------------------------------------------------
  // ✅ СОЗДАНИЕ ПУСТОГО ПРОЕКТА
  // ------------------------------------------------
  ProjectModel createEmptyProject() {
    if (isGuest || _userId == null) {
      throw Exception("Гость не может создавать проекты");
    }

    return ProjectModel(
      id: "",
      ownerId: _userId!,
      title: "Новый проект",
      description: "",
      deadline: DateTime.now().add(const Duration(days: 7)),
      status: ProjectStatus.planned.index,
      grade: null,
      attachments: const [],
      participants: [_userId!], // Владелец всегда участник
      createdAt: DateTime.now(),
    );
  }
}