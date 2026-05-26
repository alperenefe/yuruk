import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/controllers/comparison_session_controller.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../core/di/service_locator.dart';
import '../widgets/comparison_map_widget.dart';
import '../widgets/comparison_config_panel.dart';
import '../widgets/run_picker_sheet.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  /// Geçmiş ekranından direkt koşu yüklemek için.
  final RunSession? initialSession;

  const ComparisonScreen({super.key, this.initialSession});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(comparisonSessionProvider.notifier)
            .loadRunSession(widget.initialSession!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comparisonSessionProvider);
    final controller = ref.read(comparisonSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GPS Lab'),
            if (state.runLabel != null)
              Text(state.runLabel!,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          if (state.isLoaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Temizle',
              onPressed: controller.reset,
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Geçmişten Seç',
            onPressed: () => _pickFromHistory(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                    onPressed: controller.reset,
                    child: const Text('Kapat')),
              ],
            ),
          Expanded(
            child: state.isLoaded
                ? _LoadedLayout(state: state, controller: controller)
                : _EmptyLayout(
                    state: state,
                    controller: controller,
                    onPick: () => _pickFromHistory(context, controller),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromHistory(
    BuildContext context,
    ComparisonSessionController controller,
  ) async {
    final sessions = await getIt<RunSessionRepository>().getAllSessions();
    if (!context.mounted) return;
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz kaydedilmiş koşu yok.')),
      );
      return;
    }
    final picked = await RunPickerSheet.show(context, sessions);
    if (picked != null) controller.loadRunSession(picked);
  }
}

// ─── Layouts ─────────────────────────────────────────────────────────────────

class _LoadedLayout extends StatelessWidget {
  final ComparisonState state;
  final ComparisonSessionController controller;

  const _LoadedLayout({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final visibleConfigs = state.visibleConfigs;
    return Column(
      children: [
        Expanded(
          flex: 11,
          child: ComparisonMapWidget(
            results: state.results,
            visibleConfigs: visibleConfigs,
            onToggleVisibility: controller.toggleVisibility,
          ),
        ),
        ComparisonConfigPanel(
          state: state,
          controller: controller,
          showResults: true,
        ),
      ],
    );
  }
}

class _EmptyLayout extends StatelessWidget {
  final ComparisonState state;
  final ComparisonSessionController controller;
  final VoidCallback onPick;

  const _EmptyLayout({
    required this.state,
    required this.controller,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text('GPS Algoritma Lab',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    'Geçmiş koşularından birini seç. Aynı rota tüm filtre '
                    'algoritmaları ile yeniden işlenip haritada karşılaştırılır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600, height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.history),
                    label: const Text('Geçmişten Koşu Seç'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ComparisonConfigPanel(
          state: state,
          controller: controller,
          showResults: false,
        ),
      ],
    );
  }
}
