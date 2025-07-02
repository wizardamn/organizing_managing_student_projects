import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/supabase_project_repository.dart';

/// Перечисления для фильтрации и сортировки
enum ProjectFilter { all, inProgressOnly }
enum SortBy { deadlineAsc, deadlineDesc, status }

class ProjectProvider extends ChangeNotifier {
  final SupabaseProjectRepository _repo;

  bool isGuest = false;
  bool isLoading = false;

  String? _userId;
  List<Project> _projects = [];

  SortBy _sortBy = SortBy.deadlineAsc;
  ProjectFilter _filter = ProjectFilter.all;

  /// Callback, вызывается при выходе пользователя
  VoidCallback? onLogout;

  ProjectProvider(this._repo, String? userId) {
    initialize(userId: userId);
  }

  /// Инициализация после логина/логаута
  void initialize({required String? userId, VoidCallback? onLogout}) {
    _userId = userId;
    isGuest = userId == null || userId.isEmpty;
    this.onLogout = onLogout;
    _repo.updateOwner(_userId);

    if (isGuest) {
      // При входе в гостевой режим вызываем onLogout
      _projects = [];
      notifyListeners();
      onLogout?.call();
    } else {
      fetchProjects();
    }
  }

  List<Project> get view {
    List<Project> result = [..._projects];

    if (_filter == ProjectFilter.inProgressOnly) {
      result = result.where((p) => p.status == ProjectStatus.inProgress).toList();
    }

    switch (_sortBy) {
      case SortBy.deadlineAsc:
        result.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case SortBy.deadlineDesc:
        result.sort((a, b) => b.deadline.compareTo(a.deadline));
        break;
      case SortBy.status:
        result.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
    }

    return result;
  }

  Future<void> fetchProjects() async {
    if (isGuest) {
      _projects = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      _projects = await _repo.getAll();
    } catch (e) {
      _projects = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchProjects();
  }

  void setSort(SortBy sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setFilter(ProjectFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void resetFilters() {
    _filter = ProjectFilter.all;
    _sortBy = SortBy.deadlineAsc;
    notifyListeners();
  }

  Future<void> addProject(Project p) async {
    if (isGuest) return;
    await _repo.add(p);
    await fetchProjects();
  }

  Future<void> updateProject(Project p) async {
    if (isGuest) return;
    await _repo.update(p);
    await fetchProjects();
  }

  Future<void> deleteProject(String id) async {
    if (isGuest) return;
    await _repo.delete(id);
    await fetchProjects();
  }

  Project createEmptyProject() {
    if (isGuest) throw Exception("Гость не может создавать проекты");
    return _repo.createEmpty();
  }
}
