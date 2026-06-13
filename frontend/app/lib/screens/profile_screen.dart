import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _newPassword = '';
  String _currentPassword = '';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _firstName = auth.user!.firstName;
      _lastName = auth.user!.lastName;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = {
        'first_name': _firstName,
        'last_name': _lastName,
        'current_password': _currentPassword,
        if (_newPassword.isNotEmpty) 'password': _newPassword,
      };

      final success = await auth.updateProfile(data);

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (success) {
        showDialog(
          context: context,
          builder: (c) => ContentDialog(
            title: const Text('Éxito'),
            content: const Text('Perfil actualizado correctamente.'),
            actions: [
              Button(
                child: const Text('Cerrar'),
                onPressed: () {
                  Navigator.pop(c);
                  // Limpiar contraseñas de los campos
                  setState(() {
                    _newPassword = '';
                    _currentPassword = '';
                  });
                  // Limpiamos los TextFormBox usando un reemplazo del form key
                },
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (c) => ContentDialog(
            title: const Text('Error'),
            content: Text(auth.errorMessage),
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
    return ScaffoldPage(
      header: const PageHeader(title: Text('Mi Perfil')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLabel(
                  label: 'Nombre',
                  child: TextFormBox(
                    initialValue: _firstName,
                    placeholder: 'Escribe tu nombre',
                    validator: (text) {
                      if (text == null || text.isEmpty) return 'Requerido';
                      return null;
                    },
                    onSaved: (text) => _firstName = text!,
                  ),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Apellido',
                  child: TextFormBox(
                    initialValue: _lastName,
                    placeholder: 'Escribe tu apellido',
                    validator: (text) {
                      if (text == null || text.isEmpty) return 'Requerido';
                      return null;
                    },
                    onSaved: (text) => _lastName = text!,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cambiar Contraseña (Opcional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Nueva Contraseña',
                  child: TextFormBox(
                    obscureText: true,
                    placeholder: 'Dejar en blanco para mantener la actual',
                    onChanged: (text) => _newPassword = text,
                    onSaved: (text) => _newPassword = text ?? '',
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Confirmar Cambios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  'Por razones de seguridad, ingresa tu contraseña actual para guardar cualquier cambio.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Contraseña Actual',
                  child: TextFormBox(
                    obscureText: true,
                    placeholder: 'Ingresa tu contraseña actual',
                    validator: (text) {
                      if (text == null || text.isEmpty) {
                        return 'Debes ingresar tu contraseña actual para confirmar los cambios.';
                      }
                      return null;
                    },
                    onSaved: (text) => _currentPassword = text!,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const ProgressRing(strokeWidth: 3)
                      : const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
