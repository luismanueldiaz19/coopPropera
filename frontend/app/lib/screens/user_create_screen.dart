import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../services/user_api_service.dart';
import '../providers/user_provider.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
        'password': _password,
        'password_confirmation': _password,
        if (_occupationId != null) 'occupation_id': _occupationId,
        if (_selectedRoles.isNotEmpty) 'roles': _selectedRoles,
        'status': 'active',
      };

      try {
        await UserApiService().createUser(data);
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
                Button(child: const Text('Cerrar'), onPressed: () => Navigator.pop(c))
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
    return ScaffoldPage(
      header: const PageHeader(title: Text('Registrar Nuevo Usuario')),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLabel(
                  label: 'Nombre(s)',
                  child: TextFormBox(
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _firstName = v!,
                  ),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Apellido(s)',
                  child: TextFormBox(
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _lastName = v!,
                  ),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Nombre de usuario',
                  child: TextFormBox(
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _username = v!,
                  ),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Contraseña',
                  child: TextFormBox(
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving ? const ProgressRing() : const Text('Crear Usuario'),
                    ),
                    const SizedBox(width: 16),
                    Button(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
