import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/project_provider.dart';
import '../../models/project.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProjectProvider>();

    // Исправлено: используем prov.view (текущий список проектов)
    final events = _groupProjectsByDate(prov.view);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь проектов')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            eventLoader: (day) => events[DateUtils.dateOnly(day)] ?? [],
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Выберите дату'))
                : _buildEventList(events[DateUtils.dateOnly(_selectedDay!)] ?? []),
          ),
        ],
      ),
    );
  }

  /// Группировка проектов по дате дедлайна
  Map<DateTime, List<Project>> _groupProjectsByDate(List<Project> projects) {
    final Map<DateTime, List<Project>> data = {};
    for (final project in projects) {
      final date = DateUtils.dateOnly(project.deadline);
      data.putIfAbsent(date, () => []);
      data[date]!.add(project);
    }
    return data;
  }

  /// Список проектов для выбранного дня
  Widget _buildEventList(List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(child: Text('На этот день нет проектов'));
    }

    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = projects[index];
        return ListTile(
          leading: const Icon(Icons.assignment, color: Colors.blue),
          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            'Дедлайн: ${DateFormat('dd.MM.yyyy').format(p.deadline)}\nСтатус: ${p.status.name}',
          ),
          onTap: () => _showProjectDetails(context, p),
        );
      },
    );
  }

  /// Диалог с подробностями проекта
  void _showProjectDetails(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(project.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Описание: ${project.description ?? "Нет"}'),
            const SizedBox(height: 8),
            Text('Статус: ${project.status.name}'),
            Text('Дедлайн: ${DateFormat('dd.MM.yyyy').format(project.deadline)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
