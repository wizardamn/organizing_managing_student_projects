import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  late Project _edited;

  @override
  void initState() {
    super.initState();
    _edited = Project(
      id: widget.project.id,
      title: widget.project.title,
      description: widget.project.description,
      deadline: widget.project.deadline,
      status: widget.project.status,
      ownerId: widget.project.ownerId,
      attachments: List<String>.from(widget.project.attachments),
      grade: widget.project.grade,
      participants: List<String>.from(widget.project.participants),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ProjectProvider>();
    final isReadOnly = _edited.status == ProjectStatus.completed;

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
                initialValue: _edited.title,
                enabled: !isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                onSaved: (v) => _edited.title = v!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _edited.description,
                enabled: !isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (v) => _edited.description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                initial: _edited.deadline,
                onPicked: (d) => _edited.deadline = d,
                enabled: !isReadOnly,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProjectStatus>(
                value: _edited.status,
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
                onChanged: isReadOnly
                    ? null
                    : (v) => setState(() => _edited.status = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _edited.grade?.toString() ?? '',
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
                onSaved: (v) => _edited.grade =
                (v == null || v.isEmpty) ? null : double.parse(v),
              ),
              const SizedBox(height: 16),
              Text('Вложения:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._edited.attachments.map(
                        (path) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        _Thumb(path: path),
                        if (!isReadOnly)
                          Positioned(
                            right: -10,
                            top: -10,
                            child: IconButton(
                              icon:
                              const Icon(Icons.close, size: 18, color: Colors.red),
                              onPressed: () => setState(() {
                                _edited.attachments.remove(path);
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Добавить фото',
                      onPressed: _pickMedia,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isReadOnly
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (widget.isNew) {
                      await prov.addProject(_edited);
                    } else {
                      await prov.updateProject(_edited);
                    }
                    if (mounted) Navigator.pop(context, true);
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

  Future<void> _pickMedia() async {
    try {
      final picker = ImagePicker();
      final List<XFile>? imgs = await picker.pickMultiImage();
      if (imgs != null && imgs.isNotEmpty) {
        setState(() {
          _edited.attachments.addAll(imgs.map((x) => x.path));
        });
      }
    } catch (e) {
      debugPrint('Ошибка при выборе изображений: $e');
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : const Icon(Icons.broken_image),
    );
  }
}
