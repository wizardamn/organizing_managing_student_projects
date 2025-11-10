import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import 'project_form_screen.dart';
import '../../widgets/user_profile_drawer.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<ProjectProvider>();
      // ✅ Загружаем/обновляем проекты при инициализации
      await prov.fetchProjects();
    });
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

          // Фильтр и Сортировка
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_alt),
            onSelected: (value) => _onSortFilter(value, prov),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'dAsc', child: Text('По дедлайну ↑')),
              PopupMenuItem(value: 'dDesc', child: Text('По дедлайну ↓')),
              PopupMenuItem(value: 'status', child: Text('По статусу')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'all', child: Text('Все проекты')),
              PopupMenuItem(value: 'inProgress', child: Text('Только "В работе"')),
            ],
          ),
        ],
      ),

      drawer: const UserProfileDrawer(),

      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: prov.fetchProjects,
        child: projects.isEmpty
            ? Center(
          child: Text(
            prov.isGuest
                ? "Войдите в аккаунт, чтобы увидеть проекты"
                : "Нет проектов",
            style: const TextStyle(fontSize: 16),
          ),
        )
            : _buildProjectList(projects),
      ),

      // Кнопка «добавить» показывается ТОЛЬКО когда пользователь авторизован
      floatingActionButton: prov.isGuest
          ? null
          : FloatingActionButton(
        onPressed: () async {
          if (!context.mounted) return;

          final newProject = prov.createEmptyProject();

          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProjectFormScreen(project: newProject, isNew: true),
            ),
          );

          if (context.mounted && created != null) {
            // Если ProjectFormScreen закрывается (Navigator.pop), то он возвращает null.
            // Проект добавляется в provider.addProject() внутри формы.
            // Достаточно просто обновить список
            await prov.fetchProjects();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Проект создан')),
              );
            }
          }
        },
        tooltip: 'Создать проект',
        child: const Icon(Icons.add),
      ),
    );
  }

  // =====================================================
  //                СПИСОК ПРОЕКТОВ
  // =====================================================
  Widget _buildProjectList(List<ProjectModel> projects) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

            title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Срок: ${DateFormat('dd.MM.yyyy').format(p.deadline)}'),
                // ✅ ИСПРАВЛЕНО: Используем statusEnum и геттер .text из ProjectModel
                Text('Статус: ${p.statusEnum.text}'),

                if (p.participants.isNotEmpty)
                // 💡 ПРИМЕЧАНИЕ: Здесь отображаются ID участников.
                  Text('Участники: ${p.participants.join(', ')}'),

                if (p.attachments.isNotEmpty)
                  Wrap(
                    children: p.attachments.map((a) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6, top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(a,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (p.grade != null)
                  Text('Оценка: ${p.grade!.toStringAsFixed(1)}'),
              ],
            ),

            // Меню: редактировать/удалить
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (!context.mounted) return;

                if (value == 'edit') {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectFormScreen(project: p, isNew: false),
                    ),
                  );
                  // Проверка mounted после async gap
                  if (context.mounted && updated != null) {
                    await context.read<ProjectProvider>().fetchProjects();
                  }
                } else if (value == 'delete') {
                  _confirmDelete(context, context.read<ProjectProvider>(), p.id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                PopupMenuItem(value: 'delete', child: Text('Удалить')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ),
        );
      },
    );
  }

  // ❌ УДАЛЕНА ИЗБЫТОЧНАЯ ФУНКЦИЯ _statusRu,
  // так как используется p.statusEnum.text

  // Фильтрация и сортировка (корректно)
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

  // Подтверждение удаления
  Future<void> _confirmDelete(
      BuildContext context, ProjectProvider prov, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    // ✅ ИСПРАВЛЕНИЕ: Проверка mounted после async gap
    if (context.mounted && confirmed == true) {
      await prov.deleteProject(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Проект удалён')),
        );
      }
    }
  }
}