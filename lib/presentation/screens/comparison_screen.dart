import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/controllers/comparison_session_controller.dart';
import '../../core/config/gps_filter_params.dart';
import '../../core/filters/gps_filter_pipeline.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../core/di/service_locator.dart';
import '../widgets/comparison_map_widget.dart';
import '../widgets/config_edit_sheet.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comparisonSessionProvider);
    final controller = ref.read(comparisonSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GPS Lab'),
            if (state.runLabel != null)
              Text(
                state.runLabel!,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal),
              ),
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
                  child: const Text('Kapat'),
                ),
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
    final repo = getIt<RunSessionRepository>();
    final sessions = await repo.getAllSessions();

    if (!context.mounted) return;

    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz kaydedilmiş koşu yok.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<RunSession>(
      context: context,
      builder: (ctx) => _RunPickerSheet(sessions: sessions),
    );

    if (picked != null) {
      controller.loadRunSession(picked);
    }
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
                  Text(
                    'GPS Algoritma Lab',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Geçmiş koşularından birini seç. Aynı rota 5 farklı filtre algoritmasıyla yeniden işlenip haritada karşılaştırılır.',
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
        _ConfigListPanel(
          state: state,
          controller: controller,
          showResults: false,
        ),
      ],
    );
  }
}

class _RunPickerSheet extends StatelessWidget {
  final List<RunSession> sessions;

  const _RunPickerSheet({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Koşu Seç',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                final date =
                    '${s.startTime.day}.${s.startTime.month}.${s.startTime.year}';
                final dist =
                    '${(s.totalDistance / 1000).toStringAsFixed(2)} km';
                final pts = s.labInputPoints.length;
                return ListTile(
                  leading: const Icon(Icons.directions_run, color: Colors.blue),
                  title: Text('$date — $dist'),
                  subtitle: Text('$pts nokta'),
                  enabled: pts > 0,
                  onTap: pts > 0 ? () => Navigator.pop(context, s) : null,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoadedLayout extends StatelessWidget {
  final ComparisonState state;
  final ComparisonSessionController controller;

  const _LoadedLayout({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final visibleConfigs = List.generate(
      state.configs.length,
      (i) => i < state.results.length,
    );

    return Column(
      children: [
        Expanded(
          flex: 11,
          child: ComparisonMapWidget(
            results: state.results,
            visibleConfigs: visibleConfigs,
          ),
        ),
        _ConfigListPanel(
          state: state,
          controller: controller,
          showResults: true,
        ),
      ],
    );
  }
}

class _ConfigListPanel extends StatelessWidget {
  final ComparisonState state;
  final ComparisonSessionController controller;
  final bool showResults;

  const _ConfigListPanel({
    required this.state,
    required this.controller,
    required this.showResults,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Text(
                  'Algoritmalar  (${state.configs.length})',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (showResults) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${state.rawPoints.length} ham nokta',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddConfigDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ekle'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: showResults ? 136 : 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              itemCount: state.configs.length,
              itemBuilder: (context, i) {
                final config = state.configs[i];
                final result = (showResults && i < state.results.length)
                    ? state.results[i]
                    : null;
                return _ConfigCard(
                  config: config,
                  result: result,
                  index: i,
                  totalConfigs: state.configs.length,
                  onEdit: () => ConfigEditSheet.show(
                    context: context,
                    initial: config,
                    title: 'Düzenle: ${config.name}',
                    onSave: (updated) => controller.updateConfig(i, updated),
                  ),
                  onDelete: state.configs.length > 1
                      ? () => _confirmDelete(context, i, config.name)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Config Ekle'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Hangi preset\'ten başlamak istersin?',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              ...GpsFilterParams.allPresets.map(
                (preset) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: preset.color,
                    radius: 10,
                  ),
                  title: Text(preset.name,
                      style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.add, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    final newConfig = preset.copyWith(
                      name: '${preset.name} (yeni)',
                    );
                    controller.addConfig(newConfig);
                    ConfigEditSheet.show(
                      context: context,
                      initial: newConfig,
                      title: 'Yeni config',
                      onSave: (updated) => controller.updateConfig(
                        controller.state.configs.length - 1,
                        updated,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, int index, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"$name" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) controller.removeConfig(index);
  }
}

class _ConfigCard extends StatelessWidget {
  final GpsFilterParams config;
  final FilteredTrackResult? result;
  final int index;
  final int totalConfigs;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ConfigCard({
    required this.config,
    required this.result,
    required this.index,
    required this.totalConfigs,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = config.color;

    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    config.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.edit,
                        size: 14, color: Colors.grey.shade600),
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 14, color: Colors.grey.shade400),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: result != null
                ? _ResultStats(result: result!)
                : _ConfigSummary(config: config),
          ),
        ],
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  final FilteredTrackResult result;
  const _ResultStats({required this.result});

  @override
  Widget build(BuildContext context) {
    final smoothness = result.smoothnessScore;
    final smoothLabel = smoothness < 500
        ? 'Çok Düzgün'
        : smoothness < 1500
            ? 'Düzgün'
            : smoothness < 3000
                ? 'Orta'
                : 'Gürültülü';
    final smoothColor = smoothness < 1500
        ? Colors.green.shade700
        : smoothness < 3000
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(Icons.straighten, result.distanceFormatted),
        _Row(Icons.location_on, '${result.acceptedCount} nokta'),
        _Row(Icons.timeline, smoothLabel, color: smoothColor),
        _Row(
          Icons.filter_alt,
          '%${(result.retentionRate * 100).toStringAsFixed(0)} tutuldu',
          color: Colors.grey.shade600,
        ),
      ],
    );
  }
}

class _ConfigSummary extends StatelessWidget {
  final GpsFilterParams config;
  const _ConfigSummary({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(
          Icons.gps_fixed,
          config.accuracyThreshold >= 9000
              ? 'Doğruluk: ∞'
              : 'Doğruluk ≤${config.accuracyThreshold.round()}m',
        ),
        _Row(
          Icons.speed,
          config.maxSpeedKmh >= 9000
              ? 'Hız: ∞'
              : 'Hız ≤${config.maxSpeedKmh.round()} km/h',
        ),
        _Row(
          config.useKalman ? Icons.waves : Icons.block,
          config.useKalman ? 'Kalman açık' : 'Kalman kapalı',
          color: config.useKalman
              ? Colors.blue.shade700
              : Colors.grey.shade500,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Row(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color ?? Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color ?? Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
