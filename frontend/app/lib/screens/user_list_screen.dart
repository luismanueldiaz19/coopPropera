import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'user_create_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Usuarios del Sistema'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarBuilderItem(
              builder: (context, mode, w) => Tooltip(
                message: 'Refrescar usuarios',
                child: w,
              ),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Actualizar'),
                onPressed: () {
                  userProvider.fetchUsers();
                },
              ),
            ),
            CommandBarBuilderItem(
              builder: (context, mode, w) => Tooltip(
                message: 'Nuevo Usuario',
                child: w,
              ),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.add_friend),
                label: const Text('Registrar Usuario'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const UserCreateScreen(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      content: userProvider.isLoading
          ? const Center(child: ProgressRing())
          : userProvider.errorMessage.isNotEmpty
              ? Center(child: Text('Error: ${userProvider.errorMessage}', style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: userProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = userProvider.users[index];
                    return _buildUserListItem(user);
                  },
                ),
    );
  }

  Widget _buildUserListItem(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(FluentIcons.contact, size: 32),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text('@${user.username}'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.status == 'active'
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: user.status == 'active'
                      ? Colors.green.darker
                      : Colors.red.darker,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('ADMIN', style: TextStyle(color: Colors.blue.darker, fontWeight: FontWeight.bold)),
              ),
            IconButton(
              icon: Icon(FluentIcons.edit, color: Colors.blue),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => UserCreateScreen(user: user),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
