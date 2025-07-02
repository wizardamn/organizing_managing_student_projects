import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../screens/project_form_screen.dart';
import '../widgets/user_profile_drawer.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    await Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProjectProvider>();
    final projects = prov.view;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои проекты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Нет новых уведомлений')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_alt),
            onSelected: (value) => _onSortFilter(value, prov),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'dAsc', child: Text('По дедлайну ↑')),
              PopupMenuItem(value: 'dDesc', child: Text('По дедлайну ↓')),
              PopupMenuItem(value: 'status', child: Text('По статусу')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'all', child: Text('Все статусы')),
              PopupMenuItem(value: 'inProgress', child: Text('Только "В работе"')),
            ],
          ),
        ],
      ),
      drawer: const UserProfileDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProjects,
        child: projects.isEmpty
            ? const Center(
          child: Text('Нет проектов, удовлетворяющих условиям фильтра.',
              style: TextStyle(fontSize: 16)),
        )
            : ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final p = projects[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Срок: ${DateFormat('dd.MM.yyyy').format(p.deadline)}'),
                    Text('Статус: ${_statusRu(p.status)}'),
                    if (p.participants.isNotEmpty)
                      Text('Участники: ${p.participants.join(', ')}'),
                    if (p.grade != null)
                      Text('Оценка: ${p.grade!.toStringAsFixed(1)}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectFormScreen(project: p, isNew: false),
                    ),
                  );
                  if (updated == true) await _loadProjects();
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: prov.isGuest
          ? null
          : FloatingActionButton(
        onPressed: () async {
          final newProject = prov.createEmptyProject();
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectFormScreen(project: newProject, isNew: true),
            ),
          );
          if (created == true) {
            await _loadProjects();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Проект успешно добавлен')),
              );
            }
          }
        },
        tooltip: 'Создать проект',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _statusRu(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planned:
        return 'Запланирован';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.completed:
        return 'Завершён';
    }
  }

  void _onSortFilter(String value, ProjectProvider prov) {
    switch (value) {
      case 'dAsc':
        prov.setSort(SortBy.deadlineAsc);
        break;
      case 'dDesc':
        prov.setSort(SortBy.deadlineDesc);
        break;
      case 'status':
        prov.setSort(SortBy.status);
        break;
      case 'all':
        prov.setFilter(ProjectFilter.all);
        break;
      case 'inProgress':
        prov.setFilter(ProjectFilter.inProgressOnly);
        break;
    }
  }
}
