import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/occupation_provider.dart';
import '../models/occupation.dart';

class OccupationCreateScreen extends StatefulWidget {
  final Occupation? occupation;

  const OccupationCreateScreen({super.key, this.occupation});

  @override
  State<OccupationCreateScreen> createState() => _OccupationCreateScreenState();
}

class _OccupationCreateScreenState extends State<OccupationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEditing => widget.occupation != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.occupation!.name;
      _descriptionController.text = widget.occupation!.description ?? '';
      _isActive = widget.occupation!.status == 'active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveOccupation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = Provider.of<OccupationProvider>(context, listen: false);
    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      'status': _isActive ? 'active' : 'inactive',
    };

    bool success;
    if (isEditing) {
      success = await provider.updateOccupation(widget.occupation!.id, data);
    } else {
      success = await provider.createOccupation(data);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Éxito'),
              content: Text(
                isEditing
                    ? 'Ocupación actualizada correctamente.'
                    : 'Ocupación creada correctamente.',
              ),
              severity: InfoBarSeverity.success,
            );
          },
        );
        Navigator.pop(context);
      } else {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Error'),
              content: Text(provider.errorMessage),
              severity: InfoBarSeverity.error,
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(isEditing ? 'Editar Ocupación' : 'Nueva Ocupación'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: 'Nombre de la Ocupación *',
              child: TextFormBox(
                controller: _nameController,
                placeholder: 'Ej: Analista de Sistemas',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Descripción',
              child: TextFormBox(
                controller: _descriptionController,
                placeholder: 'Descripción detallada de las funciones',
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 16),
            ToggleSwitch(
              checked: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              content: Text(_isActive ? 'Estado: Activo' : 'Estado: Inactivo'),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveOccupation,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(strokeWidth: 3),
                )
              : Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
