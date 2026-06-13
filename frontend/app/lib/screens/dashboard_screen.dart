import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'task_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  List<TaskModel> _getEventsForDay(DateTime day, List<TaskModel> allTasks) {
    return allTasks.where((task) {
      // Excluir tareas completadas
      if (task.status.toLowerCase() == 'completed' ||
          task.status.toLowerCase() == 'terminada') {
        return false;
      }

      // Buscar si la tarea vence o está planificada para este día
      DateTime? taskDate;
      if (task.endDate != null) {
        taskDate = DateTime.tryParse(task.endDate!);
      }

      // Si no tiene fecha de fin, usamos la de creación para no dejarla fuera
      if (taskDate == null && task.createdAt.isNotEmpty) {
        taskDate = DateTime.tryParse(task.createdAt);
      }

      if (taskDate != null) {
        return isSameDay(taskDate, day);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final pendingTasks = taskProvider.tasks.where((t) {
      final s = t.status.toLowerCase();
      return s != 'completed' && s != 'terminada';
    }).toList();

    final selectedDayTasks = _getEventsForDay(
      _selectedDay ?? _focusedDay,
      pendingTasks,
    );
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;

    return ScaffoldPage(
      header: const PageHeader(title: Text('Calendario')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[160] : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[isDark ? 140 : 40]!),
              ),
              child: material.Material(
                type: material.MaterialType.transparency,
                child: TableCalendar<TaskModel>(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) => _getEventsForDay(day, pendingTasks),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    markerDecoration: BoxDecoration(
                      color: Colors.orange, // Indicador de tareas
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    weekendTextStyle: TextStyle(
                      color: isDark ? Colors.grey[60] : Colors.grey[120],
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    leftChevronIcon: Icon(
                      FluentIcons.chevron_left,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    rightChevronIcon: Icon(
                      FluentIcons.chevron_right,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    weekendStyle: TextStyle(
                      color: isDark ? Colors.grey[60] : Colors.grey[120],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tareas para el día seleccionado:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedDayTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No hay tareas planificadas para este día.'),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedDayTasks.length,
                itemBuilder: (context, index) {
                  final task = selectedDayTasks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (task.description != null &&
                                  task.description!.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (c) => ContentDialog(
                                    title: const Text(
                                      'Descripción de la Tarea',
                                    ),
                                    content: SingleChildScrollView(
                                      child: Text(task.description!),
                                    ),
                                    actions: [
                                      Button(
                                        child: const Text('Cerrar'),
                                        onPressed: () => Navigator.pop(c),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                task.description ?? 'Sin descripción',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.assignee != null
                                ? 'Para: ${task.assignee!.firstName} ${task.assignee!.lastName}'
                                : 'Para: Sin asignar',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                      trailing: FilledButton(
                        child: const Text('Ver Tarea'),
                        onPressed: () {
                          Navigator.of(context).push(
                            FluentPageRoute(
                              builder: (c) => TaskDetailScreen(task: task),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
