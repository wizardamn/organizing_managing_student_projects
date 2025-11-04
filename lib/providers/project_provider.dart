import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

enum ProjectFilter { all, inProgressOnly }
enum SortBy { deadlineAsc, deadlineDesc, status }

class ProjectProvider extends ChangeNotifier {
  final ProjectService _service;
  bool isGuest = false;
  bool isLoading = false;

  String? _userId;
  List<Project> _projects = [];

  SortBy _sortBy = SortBy.deadlineAsc;
  ProjectFilter _filter = ProjectFilter.all;

  ProjectProvider(this._service, String? userId) {
    initialize(userId: userId);
  }

  void initialize({required String? userId}) {
    _userId = userId;
    isGuest = userId == null || userId.isEmpty;
    _service.updateOwner(_userId);
    fetchProjects();
  }

  List<Project> get view {
    List<Project> result = [..._projects];

    if (_filter == ProjectFilter.inProgressOnly) {
      result =
          result.where((p) => p.status == ProjectStatus.inProgress).toList();
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
      _projects = await _service.getAll();
    } catch (e) {
      debugPrint('Ошибка при загрузке проектов: $e');
      _projects = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSort(SortBy sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setFilter(ProjectFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> addProject(Project p) async {
    if (isGuest) return;
    await _service.add(p);
    await fetchProjects();
  }

  Future<void> updateProject(Project p) async {
    if (isGuest) return;
    await _service.update(p);
    await fetchProjects();
  }

  Future<void> deleteProject(String id) async {
    if (isGuest) return;
    await _service.delete(id);
    await fetchProjects();
  }

  Project createEmptyProject() {
    if (isGuest) throw Exception("Гость не может создавать проекты");
    return _service.createEmpty();
  }
}
