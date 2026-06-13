import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../services/user_api_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

class UserCreateScreen extends StatefulWidget {
  final UserModel? user;
  const UserCreateScreen({super.key, this.user});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _firstName = '';
  String _lastName = '';
  String _password = '';
  int? _occupationId;
  List<int> _selectedRoles = [];
  bool _isActive = true;

  bool _isSaving = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _username = widget.user!.username;
      _firstName = widget.user!.firstName;
      _lastName = widget.user!.lastName;
      _occupationId = widget.user!.occupationId;
      _isActive = widget.user!.status == 'active';
      if (widget.user!.roles != null) {
        _selectedRoles = widget.user!.roles!.map<int>((r) {
          if (r is Map) return r['id'] as int;
          return -1;
        }).where((id) => id != -1).toList();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchMetaData();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final data = {
        'username': _username,
        'first_name': _firstName,
        'last_name': _lastName,
        if (_password.isNotEmpty) 'password': _password,
        if (_password.isNotEmpty) 'password_confirmation': _password,
        if (_occupationId != null) 'occupation_id': _occupationId,
        if (_selectedRoles.isNotEmpty) 'roles': _selectedRoles,
        'status': _isActive ? 'active' : 'inactive',
      };

      try {
        if (isEditing) {
          await UserApiService().updateUser(widget.user!.id, data);
        } else {
          await UserApiService().createUser(data);
        }
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).fetchUsers();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => ContentDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                Button(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(isEditing ? 'Editar Usuario' : 'Registrar Nuevo Usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                label: 'Nombre(s)',
                child: TextFormBox(
                  initialValue: _firstName,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _firstName = v!,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Apellido(s)',
                child: TextFormBox(
                  initialValue: _lastName,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _lastName = v!,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Nombre de usuario',
                child: TextFormBox(
                  initialValue: _username,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => _username = v!,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Contraseña',
                child: TextFormBox(
                  obscureText: true,
                  placeholder: isEditing ? 'Dejar en blanco para no cambiar' : '',
                  validator: (v) {
                    if (!isEditing && v!.isEmpty) return 'Requerido';
                    if (v!.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                  onSaved: (v) => _password = v!,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Ocupación',
                child: Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    if (provider.occupations.isEmpty) return const ProgressRing();
                    // Auto-select first occupation if none selected
                    if (_occupationId == null && provider.occupations.isNotEmpty) {
                      _occupationId = provider.occupations.first.id;
                    }
                    return ComboBox<int>(
                      value: _occupationId,
                      isExpanded: true,
                      items: provider.occupations.map((occ) {
                        return ComboBoxItem<int>(
                          value: occ.id,
                          child: Text(occ.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _occupationId = val);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Roles (Permisos)'),
              const SizedBox(height: 8),
              Consumer<UserProvider>(
                builder: (context, provider, child) {
                  if (provider.roles.isEmpty) return const ProgressRing();
                  return Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: provider.roles.map((role) {
                      return Checkbox(
                        checked: _selectedRoles.contains(role.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedRoles.add(role.id);
                            } else {
                              _selectedRoles.remove(role.id);
                            }
                          });
                        },
                        content: Text(role.name),
                      );
                    }).toList(),
                  );
                },
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
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(strokeWidth: 3),
                )
              : Text(isEditing ? 'Actualizar' : 'Crear Usuario'),
        ),
      ],
    );
  }
}
