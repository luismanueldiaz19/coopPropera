import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../utils/pdf_generator.dart';
import 'task_detail_screen.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  String _getTotalTime(TaskModel task) {
    if (task.reports == null || task.reports!.isEmpty) return '0h 0m';
    double totalHours = task.reports!.fold(
      0.0,
      (sum, r) => sum + (r.hoursWorked ?? 0.0),
    );
    final d = Duration(seconds: (totalHours * 3600).round());
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes.remainder(60)}m';
  }

  int _getCollaboratorsCount(TaskModel task) {
    return task.participants?.length ?? 0;
  }

  List<TaskModel> _getFilteredTasks(List<TaskModel> allTasks) {
    return allTasks.where((t) {
      final s = t.status.toLowerCase();
      if (s != 'completed' && s != 'terminada') return false;

      // Filtrar por fecha si están definidas
      DateTime? taskDate;
      if (t.completedAt != null) {
        taskDate = DateTime.tryParse(t.completedAt!);
      } else if (t.createdAt.isNotEmpty) {
        taskDate = DateTime.tryParse(t.createdAt);
      }

      if (taskDate != null) {
        if (_startDate != null) {
          final tDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
          final sDate = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          if (tDate.isBefore(sDate)) return false;
        }
        if (_endDate != null) {
          final tDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
          final eDate = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          if (tDate.isAfter(eDate)) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Historial de Tareas'),
        commandBar: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text('Desde: '),
            DatePicker(
              selected: _startDate,
              onChanged: (v) => setState(() => _startDate = v),
            ),
            const Text('Hasta: '),
            DatePicker(
              selected: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
            if (_startDate != null || _endDate != null)
              Button(
                child: const Text('Limpiar'),
                onPressed: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              ),
            Tooltip(
              message: 'Refrescar historial',
              child: Button(
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.refresh),
                    SizedBox(width: 8),
                    Text('Actualizar'),
                  ],
                ),
                onPressed: () {
                  taskProvider.fetchTasks();
                },
              ),
            ),
            Tooltip(
              message: 'Exportar a PDF',
              child: Button(
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.pdf),
                    SizedBox(width: 8),
                    Text('Exportar PDF'),
                  ],
                ),
                onPressed: () {
                  final filteredTasks = _getFilteredTasks(taskProvider.tasks);
                  PdfGenerator.generateAndOpenTasksPdf(
                    title: 'Historial de Tareas',
                    tasks: filteredTasks,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      content: taskProvider.isLoading
          ? const Center(child: ProgressRing())
          : taskProvider.errorMessage.isNotEmpty
          ? Center(
              child: Text(
                'Error: ${taskProvider.errorMessage}',
                style: TextStyle(color: Colors.red),
              ),
            )
          : Builder(
              builder: (context) {
                final historyTasks = _getFilteredTasks(taskProvider.tasks);

                if (historyTasks.isEmpty) {
                  return const Center(
                    child: Text('No hay tareas en el historial.'),
                  );
                }

                final isDark =
                    FluentTheme.of(context).brightness == Brightness.dark;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                      4: FlexColumnWidth(2),
                      5: IntrinsicColumnWidth(),
                    },
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: isDark ? Colors.grey[140] : Colors.grey[120],
                      ),
                      bottom: BorderSide(
                        color: isDark ? Colors.grey[140] : Colors.grey[120],
                      ),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[160] : Colors.grey[20],
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Título',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Responsable',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Completada',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Tiempo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Colab.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...historyTasks.map((task) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(task.assignee?.firstName ?? 'N/A'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                DateTime.parse(
                                  task.completedAt ?? task.createdAt,
                                ).toLocal().toString().split(' ')[0],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_getTotalTime(task)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text('${_getCollaboratorsCount(task)}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: FilledButton(
                                child: const Text('Ver más'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    FluentPageRoute(
                                      builder: (c) =>
                                          TaskDetailScreen(task: task),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
