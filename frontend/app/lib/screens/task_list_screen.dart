import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
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
              builder: (context, mode, w) => Tooltip(
                message: 'Refrescar tareas',
                child: w,
              ),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Actualizar'),
                onPressed: () {
                  taskProvider.fetchTasks();
                },
              ),
            ),
            CommandBarBuilderItem(
              builder: (context, mode, w) => Tooltip(
                message: 'Nueva Tarea',
                child: w,
              ),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: const Text('Crear Tarea'),
                onPressed: () {
                  Navigator.of(context).push(FluentPageRoute(
                    builder: (context) => const TaskCreateScreen(),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
      content: taskProvider.isLoading
          ? const Center(child: ProgressRing())
          : taskProvider.errorMessage.isNotEmpty
              ? Center(child: Text('Error: ${taskProvider.errorMessage}', style: TextStyle(color: Colors.red)))
              : taskProvider.tasks.isEmpty
                  ? const Center(child: Text('No hay tareas registradas.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisExtent: 180,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: taskProvider.tasks.length,
                      itemBuilder: (context, index) {
                        final task = taskProvider.tasks[index];
                        return _buildTaskCard(task);
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                Text(task.description ?? 'Sin descripción', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                if (task.assignee != null) ...[
                  Row(
                    children: [
                      const Icon(FluentIcons.contact, size: 12),
                      const SizedBox(width: 4),
                      Text('Asignado a: ${task.assignee!.firstName}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (task.endDate != null) ...[
                  Row(
                    children: [
                      const Icon(FluentIcons.calendar, size: 12),
                      const SizedBox(width: 4),
                      Text('Vence: ${DateTime.parse(task.endDate!).toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
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
                  Navigator.of(context).push(FluentPageRoute(
                    builder: (context) => TaskDetailScreen(task: task),
                  ));
                },
              )
            ],
          )
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
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
