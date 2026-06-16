import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/training_program_provider.dart';
import '../../domain/entities/training_goal.dart';

class ImportPlanScreen extends ConsumerStatefulWidget {
  final TrainingGoal? goalHint;

  const ImportPlanScreen({super.key, this.goalHint});

  @override
  ConsumerState<ImportPlanScreen> createState() => _ImportPlanScreenState();
}

class _ImportPlanScreenState extends ConsumerState<ImportPlanScreen> {
  final _jsonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _jsonCtrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (_jsonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON yapıştırın')),
      );
      return;
    }
    setState(() => _loading = true);
    final err = await ref
        .read(activeTrainingProgramProvider.notifier)
        .importFromJson(_jsonCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), duration: const Duration(seconds: 5)),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan içe aktarıldı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.goalHint;
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Import')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hint != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${hint.name} · ${hint.distanceLabel} · ${hint.targetTime}\n'
                    '${hint.raceDate.day}.${hint.raceDate.month}.${hint.raceDate.year}',
                  ),
                ),
              ),
            if (hint != null) const SizedBox(height: 12),
            const Text(
              'LLM çıktısını buraya yapıştırın (yalnızca JSON).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _jsonCtrl,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{ "version": 1, "goal": { ... }, "weeks": [ ... ] }',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _loading ? null : _import,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('İçe Aktar'),
        ),
      ),
    );
  }
}
