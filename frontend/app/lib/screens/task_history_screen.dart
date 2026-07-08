import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../utils/pdf_generator.dart';
import '../components/date_range_filter.dart';
import 'task_detail_screen.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAssignee;

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

      // Filtro por responsable
      if (_selectedAssignee != null && _selectedAssignee != 'Todos') {
        if (t.assignee?.firstName != _selectedAssignee) {
          return false;
        }
      }

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

  Widget _buildBarChart(Map<String, double> data, String title, bool isDark) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('No hay datos para $title'),
      );
    }

    final keys = data.keys.toList();
    double maxY = 0;
    for (var v in data.values) {
      if (v > maxY) maxY = v;
    }
    if (maxY == 0) maxY = 1;

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toString(),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < keys.length) {
                          String text = keys[value.toInt()];
                          if (text.length > 5) {
                            text = '${text.substring(0, 5)}.';
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[140]! : Colors.grey[40]!,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.entries.map((e) {
                  int index = keys.indexOf(e.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: Colors.blue,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<TaskModel> historyTasks, bool isDark) {
    Map<String, double> tasksPerUser = {};
    Map<String, double> hoursPerUser = {};
    Map<String, double> tasksPerDate = {};

    for (var task in historyTasks) {
      // 1. Tareas por usuario (asignados y participantes)
      final users = <String>{};
      if (task.assignee != null) users.add(task.assignee!.firstName);
      if (task.participants != null) {
        for (var p in task.participants!) {
          if (p is Map && p['first_name'] != null) users.add(p['first_name']);
        }
      }
      for (var u in users) {
        tasksPerUser[u] = (tasksPerUser[u] ?? 0) + 1;
      }

      // 2. Horas por usuario
      if (task.reports != null) {
        for (var r in task.reports!) {
          if (r.user != null) {
            final userName = r.user!.firstName;
            hoursPerUser[userName] =
                (hoursPerUser[userName] ?? 0) + (r.hoursWorked ?? 0.0);
          }
        }
      }

      // 3. Tareas por fecha
      String? dateStr;
      if (task.completedAt != null) {
        dateStr = task.completedAt!.split('T')[0];
      } else if (task.createdAt.isNotEmpty) {
        dateStr = task.createdAt.split('T')[0];
      }
      if (dateStr != null) {
        tasksPerDate[dateStr] = (tasksPerDate[dateStr] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[160] : Colors.grey[20],
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey[140]! : Colors.grey[40]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas (Sobre la tabla)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildBarChart(tasksPerUser, 'Tareas (Asignado/Colab)', isDark),
                _buildBarChart(hoursPerUser, 'Horas Totales', isDark),
                _buildBarChart(tasksPerDate, 'Tareas por Fecha', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    // Obtener lista única de responsables para el ComboBox
    final Set<String> assigneesSet = {'Todos'};
    for (var t in taskProvider.tasks) {
      if (t.assignee != null) {
        assigneesSet.add(t.assignee!.firstName);
      }
    }
    final assigneesList = assigneesSet.toList();
    if (_selectedAssignee != null &&
        !assigneesList.contains(_selectedAssignee)) {
      _selectedAssignee = null;
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Historial de Tareas'),
        commandBar: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text('Resp:'),
            ComboBox<String>(
              value: _selectedAssignee ?? 'Todos',
              items: assigneesList.map((a) {
                return ComboBoxItem(value: a, child: Text(a));
              }).toList(),
              onChanged: (v) => setState(() => _selectedAssignee = v),
            ),
            const SizedBox(width: 8),
            DateRangeFilter(
              onRangeSelected: (start, end) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                });
              },
            ),
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
            if (_startDate != null ||
                _endDate != null ||
                (_selectedAssignee != null && _selectedAssignee != 'Todos'))
              Button(
                child: const Text('Limpiar'),
                onPressed: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedAssignee = null;
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
                final isDark =
                    FluentTheme.of(context).brightness == Brightness.dark;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: historyTasks.isEmpty
                          ? const Center(
                              child: Text('No hay tareas en el historial.'),
                            )
                          : SingleChildScrollView(
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
                                    color: isDark
                                        ? Colors.grey[140]!
                                        : Colors.grey[120]!,
                                  ),
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.grey[140]!
                                        : Colors.grey[120]!,
                                  ),
                                ),
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[160]
                                          : Colors.grey[20],
                                    ),
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Título',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Responsable',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Completada',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Tiempo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Colab.',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                          child: Text(
                                            task.assignee?.firstName ?? 'N/A',
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            DateTime.parse(
                                              task.completedAt ??
                                                  task.createdAt,
                                            ).toLocal().toString().split(
                                              ' ',
                                            )[0],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(_getTotalTime(task)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            '${_getCollaboratorsCount(task)}',
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: FilledButton(
                                            child: const Text('Ver más'),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                FluentPageRoute(
                                                  builder: (c) =>
                                                      TaskDetailScreen(
                                                        task: task,
                                                      ),
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
                            ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildSidebar(historyTasks, isDark),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
