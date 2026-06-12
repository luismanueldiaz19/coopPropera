import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  DateTime? _startTime;

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _startTime = DateTime.now();
      _stopwatch.start();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _stopTimer() async {
    _timer?.cancel();
    _stopwatch.stop();

    final endTime = DateTime.now();
    final elapsedMinutes = _stopwatch.elapsed.inSeconds / 60.0;
    final elapsedHours = elapsedMinutes / 60.0;

    // Mostramos un dialog para capturar el reporte opcional
    String reportText = '';

    final provider = Provider.of<TaskProvider>(context, listen: false);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Registro de Tiempo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiempo registrado: ${_formatStopwatch(_stopwatch.elapsed)}',
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Comentario (Opcional)',
                child: TextBox(
                  placeholder: 'Ej: Avance de la pantalla de inicio...',
                  maxLines: 3,
                  onChanged: (text) => reportText = text,
                ),
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text('Descartar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            FilledButton(
              child: const Text('Guardar'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      // Guardar en backend
      await provider.addReport(widget.task.id, {
        'report_date': DateTime.now().toIso8601String().split('T')[0],
        'hours_worked': elapsedHours,
        'start_time': _startTime!.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        if (reportText.isNotEmpty) 'report': reportText,
      });
      // Reseteamos
      _stopwatch.reset();
      _startTime = null;
      setState(() {});
    } else {
      // Reanudar si descartó? No, por simplicidad si se descarta se resetea
      _stopwatch.reset();
      _startTime = null;
      setState(() {});
    }
  }

  String _formatStopwatch(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _manageParticipants(TaskModel currentTask) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // extraemos IDs de los participantes actuales
    List<int> tempSelected =
        currentTask.participants?.map<int>((p) => p['id'] as int).toList() ??
        [];

    await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Gestionar Participantes'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                height: 300,
                child: ListView(
                  children: userProvider.users.map((u) {
                    if (u.id == currentTask.assignedTo)
                      return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Checkbox(
                        checked: tempSelected.contains(u.id),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              tempSelected.add(u.id);
                            } else {
                              tempSelected.remove(u.id);
                            }
                          });
                        },
                        content: Text(u.fullName),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            Button(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final provider = Provider.of<TaskProvider>(
                  context,
                  listen: false,
                );
                await provider.syncParticipants(currentTask.id, tempSelected);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _pickAndUploadFile(TaskModel currentTask) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null && mounted) {
        final provider = Provider.of<TaskProvider>(context, listen: false);
        bool success = await provider.uploadAttachment(
          currentTask.id,
          filePath,
        );
        if (success && mounted) {
          showDialog(
            context: context,
            builder: (c) => ContentDialog(
              title: const Text('Éxito'),
              content: const Text('Archivo subido correctamente.'),
              actions: [
                Button(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
          );
        } else if (mounted) {
          showDialog(
            context: context,
            builder: (c) => ContentDialog(
              title: const Text('Error'),
              content: const Text('No se pudo subir el archivo.'),
              actions: [
                Button(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final currentTask = provider.tasks.firstWhere(
          (t) => t.id == widget.task.id,
          orElse: () => widget.task,
        );

        // PRIVACY RULES
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;
        final List<dynamic> roles = authProvider.user?.roles ?? [];
        final bool isAdmin = roles.any(
          (r) =>
              r['name'] == 'admin' ||
              r['name'] == 'Administrador de Tareas' ||
              r['name'] == 'Super Admin',
        );

        final bool isCreator = currentTask.createdBy == currentUserId;
        final bool isAssignee = currentTask.assignedTo == currentUserId;
        final bool isParticipant =
            currentTask.participants?.any((p) => p['id'] == currentUserId) ??
            false;

        final bool canUpdate =
            isAdmin || isCreator || isAssignee || isParticipant;
        final bool canDelete = isAdmin || isCreator;

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Detalle de Tarea'),
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            commandBar: canDelete
                ? CommandBar(
                    primaryItems: [
                      CommandBarButton(
                        icon: Icon(FluentIcons.delete, color: Colors.red),
                        label: Text(
                          'Eliminar Tarea',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => ContentDialog(
                              title: const Text('Confirmar Eliminación'),
                              content: const Text(
                                '¿Estás seguro de que deseas eliminar esta tarea permanentemente?',
                              ),
                              actions: [
                                Button(
                                  child: const Text('Cancelar'),
                                  onPressed: () => Navigator.pop(c, false),
                                ),
                                FilledButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                      Colors.red,
                                    ),
                                  ),
                                  child: const Text('Eliminar'),
                                  onPressed: () => Navigator.pop(c, true),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            // Call delete method
                            // For now, since TaskProvider.deleteTask isn't implemented, we'll just show a message.
                            showDialog(
                              context: context,
                              builder: (c) => ContentDialog(
                                title: const Text('Aviso'),
                                content: const Text(
                                  'Función de eliminación pendiente en Provider',
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
                      ),
                    ],
                  )
                : null,
          ),
          content: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTask.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Estado: ${currentTask.status.toUpperCase()}',
                        style: TextStyle(color: Colors.blue.darker),
                      ),
                      const SizedBox(height: 8),
                      Text('Prioridad: ${currentTask.priority.toUpperCase()}'),
                      const SizedBox(height: 24),
                      const Text(
                        'Descripción:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentTask.description ??
                            'Sin descripción proporcionada',
                      ),
                      const SizedBox(height: 32),

                      // PARTICIPANTES UI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Participantes (Colaboradores)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (canUpdate)
                            Button(
                              child: const Text('Gestionar'),
                              onPressed: () => _manageParticipants(currentTask),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (currentTask.participants == null ||
                          currentTask.participants!.isEmpty)
                        const Text('No hay participantes adicionales.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentTask.participants!.map((p) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                p['full_name'] ?? p['username'] ?? 'Usuario',
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 32),

                      // ATTACHMENTS UI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Archivos Adjuntos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (canUpdate)
                            Button(
                              child: const Row(
                                children: [
                                  Icon(FluentIcons.add),
                                  SizedBox(width: 8),
                                  Text('Subir (PDF/Imagen)'),
                                ],
                              ),
                              onPressed: () => _pickAndUploadFile(currentTask),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (currentTask.attachments == null ||
                          currentTask.attachments!.isEmpty)
                        const Text('No hay archivos adjuntos.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentTask.attachments!.map((att) {
                            return GestureDetector(
                              onTap: () async {
                                final path = att['file_path'];
                                if (path != null) {
                                  // Asumiendo que la API está en localhost:8000
                                  final url = Uri.parse(
                                    'http://localhost:8000/storage/$path',
                                  );
                                  try {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (c) => ContentDialog(
                                          title: const Text('Error'),
                                          content: const Text(
                                            'No se puede abrir el archivo.',
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
                                  }
                                }
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Card(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        att['file_type']?.contains('pdf') ==
                                                true
                                            ? FluentIcons.pdf
                                            : FluentIcons.photo2,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        att['file_name'] ?? 'Archivo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 32),

                      // CRONÓMETRO UI
                      if (canUpdate)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[120]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registro de Trabajo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    _formatStopwatch(_stopwatch.elapsed),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontFamily: 'Courier New',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  if (!_stopwatch.isRunning)
                                    FilledButton(
                                      onPressed: _startTimer,
                                      child: const Row(
                                        children: [
                                          Icon(FluentIcons.play),
                                          SizedBox(width: 8),
                                          Text('Iniciar Trabajo'),
                                        ],
                                      ),
                                    )
                                  else
                                    FilledButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(Colors.red),
                                      ),
                                      onPressed: _stopTimer,
                                      child: const Row(
                                        children: [
                                          Icon(FluentIcons.stop),
                                          SizedBox(width: 8),
                                          Text('Detener'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Tiempo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            currentTask.reports == null ||
                                currentTask.reports!.isEmpty
                            ? const Text('Aún no hay tiempo registrado.')
                            : ListView.builder(
                                itemCount: currentTask.reports!.length,
                                itemBuilder: (context, index) {
                                  final report = currentTask.reports![index];
                                  final hours = report.hoursWorked ?? 0.0;

                                  // Calcular duración visual aproximada
                                  final d = Duration(
                                    seconds: (hours * 3600).round(),
                                  );
                                  final timeString =
                                      '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              report.user?.firstName ??
                                                  'Usuario',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              timeString,
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          report.reportDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[100],
                                          ),
                                        ),
                                        if (report.report != null &&
                                            report.report!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(report.report!),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
