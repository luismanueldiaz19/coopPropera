import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../utils/pdf_generator.dart';
import '../providers/user_provider.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  int? _filterUserId;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
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

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Mis Tareas'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarBuilderItem(
              builder: (context, mode, w) =>
                  Tooltip(message: 'Refrescar tareas', child: w),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Actualizar'),
                onPressed: () {
                  taskProvider.fetchTasks();
                },
              ),
            ),
            CommandBarBuilderItem(
              builder: (context, mode, w) =>
                  Tooltip(message: 'Nueva Tarea', child: w),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: const Text('Crear Tarea'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const TaskCreateScreen(),
                  );
                },
              ),
            ),
            CommandBarBuilderItem(
              builder: (context, mode, w) =>
                  Tooltip(message: 'Exportar a PDF', child: w),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.pdf),
                label: const Text('Exportar PDF'),
                onPressed: () {
                  final pendingTasks = taskProvider.tasks.where((t) {
                    final estado = t.status.toLowerCase();
                    return estado != 'completed' && estado != 'terminada';
                  }).toList();
                  PdfGenerator.generateAndOpenTasksPdf(
                    title: 'Listado de Tareas Pendientes',
                    tasks: pendingTasks,
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
                final userProvider = Provider.of<UserProvider>(context);
                final pendingTasks = taskProvider.tasks.where((t) {
                  final s = t.status.toLowerCase();
                  if (s == 'completed' || s == 'terminada') return false;
                  
                  if (_filterUserId != null && t.assignedTo != _filterUserId) {
                    return false;
                  }
                  
                  if (_filterDate != null) {
                    if (t.endDate == null) return false;
                    final tDate = DateTime.tryParse(t.endDate!);
                    if (tDate == null) return false;
                    if (tDate.year != _filterDate!.year || 
                        tDate.month != _filterDate!.month || 
                        tDate.day != _filterDate!.day) {
                      return false;
                    }
                  }
                  
                  return true;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: Row(
                        children: [
                          const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 200,
                            child: ComboBox<int?>(
                              value: _filterUserId,
                              placeholder: const Text('Todos los usuarios'),
                              items: [
                                const ComboBoxItem(value: null, child: Text('Todos los usuarios')),
                                ...userProvider.users.map((u) => ComboBoxItem(value: u.id, child: Text(u.fullName))),
                              ],
                              onChanged: (val) => setState(() => _filterUserId = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 250,
                            child: DatePicker(
                              selected: _filterDate,
                              onChanged: (date) => setState(() => _filterDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_filterUserId != null || _filterDate != null)
                            Button(
                              child: const Text('Limpiar Filtros'),
                              onPressed: () => setState(() {
                                _filterUserId = null;
                                _filterDate = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: pendingTasks.isEmpty
                          ? const Center(child: Text('No hay tareas pendientes con estos filtros.'))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16.0),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 350,
                                mainAxisExtent: 220,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: pendingTasks.length,
                              itemBuilder: (context, index) {
                                final task = pendingTasks[index];
                                return _buildTaskCard(task);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(task.status),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (task.description != null && task.description!.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (c) => ContentDialog(
                          title: const Text('Descripción de la Tarea'),
                          content: SingleChildScrollView(child: Text(task.description!)),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(FluentIcons.contact, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      task.assignee != null ? 'Para: ${task.assignee!.firstName} ${task.assignee!.lastName}' : 'Para: Sin asignar',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (task.endDate != null) ...[
                  Row(
                    children: [
                      const Icon(FluentIcons.calendar, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Vence: ${DateTime.parse(task.endDate!).toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(FluentIcons.timer, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _getTotalTime(task),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(FluentIcons.group, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_getCollaboratorsCount(task)} colaboradores',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prioridad: ${task.priority}'),
              Button(
                child: const Text('Ver más'),
                onPressed: () {
                  Navigator.of(context).push(
                    FluentPageRoute(
                      builder: (context) => TaskDetailScreen(task: task),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
