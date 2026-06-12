import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _priority = 'medium';
  int? _assignedTo;
  DateTime? _dueDate;
  List<int> _selectedParticipants = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final data = {
        'title': _title,
        'description': _description,
        'priority': _priority,
        if (_assignedTo != null) 'assigned_to': _assignedTo,
        if (_dueDate != null) 'end_date': _dueDate!.toIso8601String(),
        if (_selectedParticipants.isNotEmpty) 'participants': _selectedParticipants,
      };

      final provider = Provider.of<TaskProvider>(context, listen: false);
      final success = await provider.createTask(data);

      setState(() => _isSaving = false);

      if (success) {
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (c) => ContentDialog(
            title: const Text('Error'),
            content: Text(provider.errorMessage),
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Nueva Tarea')),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                label: 'Título de la tarea',
                child: TextFormBox(
                  placeholder: 'Escribe un título breve',
                  validator: (text) {
                    if (text == null || text.isEmpty)
                      return 'El título es obligatorio';
                    return null;
                  },
                  onSaved: (text) => _title = text!,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Descripción',
                child: TextFormBox(
                  placeholder: 'Detalla lo que hay que hacer',
                  maxLines: 4,
                  onSaved: (text) => _description = text ?? '',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Prioridad'),
              const SizedBox(height: 8),
              ComboBox<String>(
                value: _priority,
                items: const [
                  ComboBoxItem(value: 'low', child: Text('Baja')),
                  ComboBoxItem(value: 'medium', child: Text('Media')),
                  ComboBoxItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              if (!userProvider.isLoading && userProvider.users.isNotEmpty) ...[
                const Text('Asignar a'),
                const SizedBox(height: 8),
                ComboBox<int?>(
                  value: _assignedTo,
                  placeholder: const Text('Seleccionar usuario'),
                  items: [
                    const ComboBoxItem(value: null, child: Text('Sin asignar (Para mí)')),
                    ...userProvider.users.map((u) => ComboBoxItem(value: u.id, child: Text(u.fullName))),
                  ],
                  onChanged: (value) {
                    setState(() => _assignedTo = value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Participantes (Colaboradores)'),
                const SizedBox(height: 8),
                Button(
                  onPressed: _showParticipantsDialog,
                  child: Text('Seleccionar Participantes (${_selectedParticipants.length})'),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Fecha límite (Opcional)'),
              const SizedBox(height: 8),
              DatePicker(
                selected: _dueDate,
                onChanged: (time) => setState(() => _dueDate = time),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const ProgressRing(strokeWidth: 2)
                        : const Text('Crear Tarea'),
                  ),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParticipantsDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<int> tempSelected = List.from(_selectedParticipants);
    
    await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Seleccionar Participantes'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                height: 300,
                child: ListView(
                  children: userProvider.users.map((u) {
                    // Evitamos que el asignado principal se seleccione doble, aunque el backend lo soportaría.
                    if (u.id == _assignedTo) return const SizedBox.shrink();
                    
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
            }
          ),
          actions: [
            Button(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text('Aceptar'),
              onPressed: () {
                setState(() => _selectedParticipants = tempSelected);
                Navigator.pop(context);
              },
            ),
          ]
        );
      }
    );
  }
}
