// lib/screens/project_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/project.dart';
import '../../providers/project_provider.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({
    super.key,
    required this.project,
    required this.isNew,
  });

  final Project project;
  final bool isNew;

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

  List<Map<String, dynamic>> _allUsers = [];
  bool _loadingUsers = false;

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  static const String storageBucket = 'project-attachments';

  @override
  void initState() {
    super.initState();
    _title = widget.project.title;
    _description = widget.project.description;
    _deadline = widget.project.deadline;
    _status = widget.project.status;
    _grade = widget.project.grade;
    _attachments = List<String>.from(widget.project.attachments);
    _participants = List<String>.from(widget.project.participants);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name');

      if (res is List) {
        _allUsers = res
            .map((e) => {
          'id': e['id'] as String,
          'full_name': e['full_name'] ?? '',
        })
            .toList();
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке пользователей: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ProjectProvider>();
    final isReadOnly = _status == ProjectStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Новый проект' : 'Редактирование проекта'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                enabled: !isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                onSaved: (v) => _title = v!.trim(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _description,
                enabled: !isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              _DatePickerField(
                initial: _deadline,
                onPicked: (d) => _deadline = d,
                enabled: !isReadOnly,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ProjectStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: ProjectStatus.values
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(_statusLabel(s)),
                ))
                    .toList(),
                onChanged:
                isReadOnly ? null : (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _grade?.toString() ?? '',
                enabled: !isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Оценка (0–10)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final val = double.tryParse(v);
                  if (val == null || val < 0 || val > 10) {
                    return 'Введите число от 0 до 10';
                  }
                  return null;
                },
                onSaved: (v) =>
                _grade = (v == null || v.isEmpty) ? null : double.parse(v),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Участники',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Добавить'),
                    onPressed: _loadingUsers ? null : _showParticipantsPicker,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _participants.isEmpty
                  ? const Text('Нет участников')
                  : Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _participants.map((id) {
                  final user = _allUsers.firstWhere(
                        (el) => el['id'] == id,
                    orElse: () => {'id': id, 'full_name': id},
                  );
                  return Chip(
                    label: Text(user['full_name'] ?? id),
                    onDeleted: isReadOnly
                        ? null
                        : () => setState(() {
                      _participants.remove(id);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text('Вложения:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._attachments.map((url) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      _AttachmentThumb(url: url),
                      if (!isReadOnly)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() => _attachments.remove(url));
                            },
                          ),
                        ),
                    ],
                  )),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Добавить файлы',
                      onPressed: _pickAndUploadAttachments, // ✅ исправлено
                    ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isReadOnly
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  final idToUse = widget.project.id.isNotEmpty
                      ? widget.project.id
                      : _uuid.v4();

                  final projectToSave = Project(
                    id: idToUse,
                    ownerId: widget.project.ownerId,
                    title: _title,
                    description: _description,
                    deadline: _deadline,
                    status: _status,
                    grade: _grade,
                    attachments: List<String>.from(_attachments),
                    participants: List<String>.from(_participants),
                    createdAt: widget.isNew
                        ? DateTime.now()
                        : widget.project.createdAt,
                  );

                  try {
                    if (widget.isNew) {
                      await prov.addProject(projectToSave);
                    } else {
                      await prov.updateProject(projectToSave);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка сохранения: $e')),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showParticipantsPicker() async {
    final selected = Set<String>.from(_participants);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text('Выберите участников',
                    style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                if (_loadingUsers)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allUsers.length,
                      itemBuilder: (context, i) {
                        final u = _allUsers[i];
                        final id = u['id'] as String;
                        return CheckboxListTile(
                          value: selected.contains(id),
                          title: Text(u['full_name'] ?? id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _participants = selected.toList());
                      Navigator.pop(ctx);
                    },
                    child: const Text('Применить'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Исправленный метод: без `dotenv`, берёт URL прямо из Supabase config
  Future<void> _pickAndUploadAttachments() async {
    try {
      final List<XFile>? picked = await _picker.pickMultiImage();
      if (picked == null || picked.isEmpty) return;

      final projectId = widget.project.id.isNotEmpty ? widget.project.id : _uuid.v4();
      final client = Supabase.instance.client;

      for (final xfile in picked) {
        final file = File(xfile.path);
        final ext = xfile.path.split('.').last;
        final path = 'projects/$projectId/${_uuid.v4()}.$ext';
        final storage = client.storage.from(storageBucket);

        try {
          // Загружаем файл
          await storage.upload(path, file);

          // Получаем публичный URL правильно через getPublicUrl()
          final publicUrl = storage.getPublicUrl(path);

          setState(() {
            _attachments.add(publicUrl);
          });
        } catch (e) {
          debugPrint('Ошибка загрузки файла: $e');
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файлы загружены')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки файлов: $e')),
      );
    }
  }


  String _statusLabel(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.planned:
        return 'Запланирован';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.completed:
        return 'Завершён';
    }
  }
}

class _DatePickerField extends StatefulWidget {
  const _DatePickerField({
    required this.initial,
    required this.onPicked,
    this.enabled = true,
  });

  final DateTime initial;
  final void Function(DateTime) onPicked;
  final bool enabled;

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd.MM.yyyy').format(_selected);
    return InkWell(
      onTap: widget.enabled ? _pickDate : null,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Срок выполнения',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatted),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selected = picked);
      widget.onPicked(picked);
    }
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final isImage = url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.webp');

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: isImage
          ? Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, color: Colors.grey),
      )
          : const Center(child: Icon(Icons.attach_file)),
    );
  }
}
