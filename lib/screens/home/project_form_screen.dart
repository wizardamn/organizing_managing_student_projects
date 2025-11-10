import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/project_model.dart';
import '../../providers/project_provider.dart';

// ❌ УДАЛЕНО ДУБЛИРУЮЩЕЕСЯ РАСШИРЕНИЕ:
// extension ProjectStatusExtension on ProjectStatus { ... }
// Оно должно быть определено только в project_model.dart

class ProjectFormScreen extends StatefulWidget {
  final ProjectModel project;
  final bool isNew;

  const ProjectFormScreen({
    super.key,
    required this.project,
    required this.isNew,
  });

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  late DateTime _deadline;
  late ProjectStatus _status;
  double? _grade;
  late List<String> _attachments;
  late List<String> _participants;

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  List<Map<String, dynamic>> _users = [];

  static const String bucket = 'project-attachments';

  @override
  void initState() {
    super.initState();

    _title = widget.project.title;
    _description = widget.project.description;
    _deadline = widget.project.deadline;
    // ✅ ИСПРАВЛЕНО: Используем геттер statusEnum
    _status = widget.project.statusEnum;
    _grade = widget.project.grade;
    _attachments = List.from(widget.project.attachments);
    _participants = List.from(widget.project.participants);

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name');

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint("Ошибка загрузки списка пользователей: $e");
    }
  }

  // ============================
  //   Выбор участника из списка
  // ============================
  Future<void> _selectParticipants() async {
    if (_users.isEmpty) return;

    final List<String> selected = List.from(_participants);

    await showDialog(
      context: context,
      builder: (ctx) {
        // Локальное состояние для диалога
        final List<String> tempSelected = List.from(selected);

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text("Выбрать участников"),
              content: SizedBox(
                width: 300,
                height: 400,
                child: ListView(
                  children: _users.map((u) {
                    final id = u['id'];
                    // 💡 ИСПРАВЛЕНИЕ: Предотвращаем добавление самого себя в участники.
                    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

                    // Участник не может выбрать себя (если это не новая запись)
                    if (id == currentUserId && !widget.isNew) {
                      return const SizedBox.shrink();
                    }

                    return CheckboxListTile(
                      title: Text(u['full_name'] ?? "Без имени"),
                      value: tempSelected.contains(id),
                      onChanged: (v) {
                        setInnerState(() {
                          if (v == true) {
                            tempSelected.add(id);
                          } else {
                            tempSelected.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Отмена"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Обновляем внешнее состояние и закрываем диалог
                    setState(() => _participants = tempSelected);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Готово"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================
  //       Загрузка вложений
  // ============================
  Future<void> _pickAttachment() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;

    final file = File(picked.path);
    final fileId = _uuid.v4();
    // 💡 ИСПРАВЛЕНИЕ: Корректное получение расширения
    final fileExt = picked.path.split('.').last.toLowerCase();

    final fileName = "${fileId}_${widget.project.id}.$fileExt"; // Используем ID проекта для уникальности

    try {
      final storage = Supabase.instance.client.storage.from(bucket);

      // 💡 ДОБАВЛЕНИЕ: Отображение прогресса или лоадера
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Загрузка файла...')),
      );

      // Загрузка файла
      final path = await storage.upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Получение публичного URL
      final publicUrl = storage.getPublicUrl(fileName);

      if (!mounted) return;

      // Удаляем сообщение о загрузке
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      setState(() => _attachments.add(publicUrl));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки файла: ${e.toString()}')),
        );
      }
      debugPrint("Ошибка загрузки файла: $e");
    }
  }

  // ============================
  //       Сохранение проекта
  // ============================
  Future<void> _saveProject() async {
    if (!mounted || !_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final user = Supabase.instance.client.auth.currentUser;

    final projectModel = ProjectModel(
      id: widget.project.id.isNotEmpty ? widget.project.id : const Uuid().v4(), // 💡 ИСПРАВЛЕНИЕ: Если ID пустой (новый проект), генерируем новый
      title: _title,
      description: _description,
      ownerId: widget.project.ownerId.isEmpty
          ? user?.id ?? ""
          : widget.project.ownerId,
      deadline: _deadline,
      status: _status.index,
      grade: _grade,
      attachments: _attachments,
      participants: _participants,
      createdAt: widget.project.createdAt,
    );

    final provider = context.read<ProjectProvider>();

    try {
      if (widget.isNew) {
        await provider.addProject(projectModel);
      } else {
        await provider.updateProject(projectModel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Проект успешно ${widget.isNew ? 'создан' : 'обновлен'}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения проекта: ${e.toString()}')),
        );
      }
      debugPrint("Ошибка сохранения проекта: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Оставляем лоадер, если список пользователей еще не загружен
    if (_users.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.isNew ? "Создать проект" : "Редактировать проект"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProject,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: "Название"),
                validator: (v) =>
                v == null || v.isEmpty ? "Введите название" : null,
                onSaved: (v) => _title = v!,
              ),

              TextFormField(
                initialValue: _description,
                maxLines: 4,
                decoration:
                const InputDecoration(labelText: "Описание"),
                onSaved: (v) => _description = v!,
              ),

              const SizedBox(height: 20),

              // Дата
              DatePickerField(
                initialDate: _deadline,
                onChanged: (d) => setState(() => _deadline = d),
              ),

              const SizedBox(height: 20),

              // Статус
              DropdownButtonFormField<ProjectStatus>(
                value: _status,
                items: ProjectStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                    value: s,
                    // ✅ ИСПРАВЛЕНО: Используем геттер .text из Extension
                    child: Text(s.text),
                  ),
                )
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
                decoration:
                const InputDecoration(labelText: "Статус проекта"),
              ),

              const SizedBox(height: 20),

              // Участники
              ListTile(
                title: const Text("Участники"),
                subtitle: Text(
                  _participants.isEmpty
                      ? "Нет участников"
                      : "Выбрано: ${_participants.length}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.group_add),
                  onPressed: _selectParticipants,
                ),
              ),

              const SizedBox(height: 20),

              // Вложения
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Вложения:",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in _attachments)
                    AttachmentThumb(
                      url: a,
                      onDelete: () async {
                        setState(() => _attachments.remove(a));
                        // 💡 ДОБАВЛЕНИЕ: Логика удаления файла из Storage
                        await _deleteAttachment(a);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    onPressed: _pickAttachment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================
  //   Удаление вложений
  // ============================
  Future<void> _deleteAttachment(String url) async {
    try {
      final fileName = url.split('/').last;
      await Supabase.instance.client.storage.from(bucket).remove([fileName]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вложение удалено из хранилища.')),
        );
      }
    } catch (e) {
      debugPrint("Ошибка удаления файла из Storage: $e");
    }
  }
}

// ================================
//   Виджет выбора даты
// ================================
class DatePickerField extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    super.key,
    required this.initialDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Дедлайн"),
      subtitle: Text(DateFormat('dd.MM.yyyy').format(initialDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }
}

// ================================
//   Превью вложения
// ================================
class AttachmentThumb extends StatelessWidget {
  final String url;
  final VoidCallback onDelete;

  const AttachmentThumb({
    super.key,
    required this.url,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}