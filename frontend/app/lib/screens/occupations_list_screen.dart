import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/occupation_provider.dart';
import '../models/occupation.dart';
import 'occupation_create_screen.dart';

class OccupationsListScreen extends StatefulWidget {
  const OccupationsListScreen({super.key});

  @override
  State<OccupationsListScreen> createState() => _OccupationsListScreenState();
}

class _OccupationsListScreenState extends State<OccupationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OccupationProvider>(
        context,
        listen: false,
      ).fetchOccupations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final occupationProvider = Provider.of<OccupationProvider>(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Ocupaciones y Cargos'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarBuilderItem(
              builder: (context, mode, w) =>
                  Tooltip(message: 'Refrescar ocupaciones', child: w),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Actualizar'),
                onPressed: () {
                  occupationProvider.fetchOccupations();
                },
              ),
            ),
            CommandBarBuilderItem(
              builder: (context, mode, w) =>
                  Tooltip(message: 'Nueva Ocupación', child: w),
              wrappedItem: CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: const Text('Crear Ocupación'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const OccupationCreateScreen(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      content: occupationProvider.isLoading
          ? const Center(child: ProgressRing())
          : occupationProvider.errorMessage.isNotEmpty
          ? Center(
              child: Text(
                'Error: ${occupationProvider.errorMessage}',
                style: TextStyle(color: Colors.red),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: occupationProvider.occupations.length,
              itemBuilder: (context, index) {
                final occupation = occupationProvider.occupations[index];
                return _buildOccupationListItem(occupation, occupationProvider);
              },
            ),
    );
  }

  Widget _buildOccupationListItem(
    Occupation occupation,
    OccupationProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(FluentIcons.suitcase, size: 32),
        title: Text(
          occupation.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(occupation.description ?? 'Sin descripción'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: occupation.status == 'active'
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                occupation.status.toUpperCase(),
                style: TextStyle(
                  color: occupation.status == 'active'
                      ? Colors.green.darker
                      : Colors.red.darker,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(FluentIcons.edit, color: Colors.blue),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      OccupationCreateScreen(occupation: occupation),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(FluentIcons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(occupation, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    Occupation occupation,
    OccupationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Eliminar ocupación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la ocupación "${occupation.name}"?',
        ),
        actions: [
          Button(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red),
            ),
            child: const Text('Eliminar'),
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteOccupation(occupation.id);
              if (mounted) {
                if (success) {
                  displayInfoBar(
                    context,
                    builder: (context, close) {
                      return const InfoBar(
                        title: Text('Éxito'),
                        content: Text('Ocupación eliminada correctamente.'),
                        severity: InfoBarSeverity.success,
                      );
                    },
                  );
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
            },
          ),
        ],
      ),
    );
  }
}
