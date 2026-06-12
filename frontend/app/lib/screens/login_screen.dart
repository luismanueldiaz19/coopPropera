import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Por favor ingresa usuario y contraseña');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(username, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        FluentPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _showError(authProvider.errorMessage);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Error de Autenticación'),
        content: Text(message),
        actions: [
          Button(
            child: const Text('Aceptar'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 40),
              const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              InfoLabel(
                label: 'Usuario',
                child: TextBox(
                  controller: _usernameController,
                  placeholder: 'Ej: admin',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(FluentIcons.contact),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'Contraseña',
                child: PasswordBox(
                  controller: _passwordController,
                  placeholder: 'Tu contraseña secreta',
                  revealMode: PasswordRevealMode.peekAlways,
                ),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _isLoading ? null : _login,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _isLoading 
                    ? const ProgressRing(strokeWidth: 2.5) 
                    : const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
