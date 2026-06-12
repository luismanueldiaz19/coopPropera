import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'task_list_screen.dart';
import 'user_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      FluentPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final userName = user != null ? user.firstName : 'Usuario';

    return NavigationView(
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: PaneDisplayMode.auto,
        header: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            'Hola, $userName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Inicio'),
            body: const Center(
              child: Text('Dashboard de Tareas (Próximamente)'),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.task_list),
            title: const Text('Mis Tareas'),
            body: const TaskListScreen(),
          ),
          if (user != null && user.isAdmin)
            PaneItem(
              icon: const Icon(FluentIcons.people),
              title: const Text('Usuarios'),
              body: const UserListScreen(),
            ),
        ],
        footerItems: [
          PaneItemAction(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? FluentIcons.sunny
                  : FluentIcons.clear_night,
            ),
            title: Text(
              themeProvider.themeMode == ThemeMode.dark
                  ? 'Modo Claro'
                  : 'Modo Oscuro',
            ),
            onTap: themeProvider.toggleTheme,
          ),
          PaneItemAction(
            icon: const Icon(FluentIcons.sign_out),
            title: const Text('Cerrar Sesión'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
