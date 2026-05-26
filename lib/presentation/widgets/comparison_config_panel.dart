import 'package:flutter/material.dart';
import '../../application/controllers/comparison_session_controller.dart';
import '../../core/config/gps_filter_params.dart';
import '../../core/filters/gps_filter_pipeline.dart';
import 'comparison_config_stats.dart';
import 'config_edit_sheet.dart';

/// Karşılaştırma ekranının altındaki algoritma kartları + kontrol paneli.
class ComparisonConfigPanel extends StatelessWidget {
  final ComparisonState state;
  final ComparisonSessionController controller;
  final bool showResults;

  const ComparisonConfigPanel({
    super.key,
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
          _PanelHeader(
            state: state,
            showResults: showResults,
            onAddConfig: () => _showAddConfigDialog(context),
            onShowAll: controller.showAll,
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
                final visible = state.isVisible(i);
                return _ConfigCard(
                  config: config,
                  result: result,
                  isVisible: visible,
                  onEdit: () => ConfigEditSheet.show(
                    context: context,
                    initial: config,
                    title: 'Düzenle: ${config.name}',
                    onSave: (updated) => controller.updateConfig(i, updated),
                  ),
                  onDelete: state.configs.length > 1
                      ? () => _confirmDelete(context, i, config.name)
                      : null,
                  onToggleVisibility: () => controller.toggleVisibility(i),
                  onSolo: () => controller.soloVisibility(i),
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
              const Text('Hangi preset\'ten başlamak istersin?',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              ...GpsFilterParams.allPresets.map(
                (preset) => ListTile(
                  dense: true,
                  leading:
                      CircleAvatar(backgroundColor: preset.color, radius: 10),
                  title: Text(preset.name,
                      style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.add, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    final newConfig =
                        preset.copyWith(name: '${preset.name} (yeni)');
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

// ─────────────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final ComparisonState state;
  final bool showResults;
  final VoidCallback onAddConfig;
  final VoidCallback onShowAll;

  const _PanelHeader({
    required this.state,
    required this.showResults,
    required this.onAddConfig,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final anyHidden = state.hiddenIndices.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Text(
            'Algoritmalar  (${state.configs.length})',
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (showResults) ...[
            const SizedBox(width: 6),
            Text(
              '· ${state.rawPoints.length} ham nokta',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
          const Spacer(),
          if (anyHidden && showResults)
            TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Tümünü göster',
                  style: TextStyle(fontSize: 12)),
            ),
          TextButton.icon(
            onPressed: onAddConfig,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  final GpsFilterParams config;
  final FilteredTrackResult? result;
  final bool isVisible;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSolo;

  const _ConfigCard({
    required this.config,
    required this.result,
    required this.isVisible,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onSolo,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = config.color;
    return GestureDetector(
      onLongPress: onSolo,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.45,
        child: Container(
          width: 150,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isVisible ? color : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                config: config,
                isVisible: isVisible,
                onEdit: onEdit,
                onDelete: onDelete,
                onToggleVisibility: onToggleVisibility,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: result != null
                    ? ResultStatsView(result: result!)
                    : ConfigSummaryView(config: config),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final GpsFilterParams config;
  final bool isVisible;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onToggleVisibility;

  const _CardHeader({
    required this.config,
    required this.isVisible,
    required this.onEdit,
    required this.onToggleVisibility,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = config.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleVisibility,
            child: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              size: 14,
              color: isVisible ? color : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              config.name,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child:
                    Icon(Icons.close, size: 14, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }
}
