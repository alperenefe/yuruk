import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/training_goal.dart';
import '../../infrastructure/prompt/training_plan_prompt_builder.dart';
import 'import_plan_screen.dart';

/// Hedef parametreleri → LLM prompt kopyala → JSON import.
class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final _nameCtrl = TextEditingController(text: '2400m hedef');
  final _distanceCtrl = TextEditingController(text: '2400');
  final _timeCtrl = TextEditingController(text: '10:20');
  final _daysCtrl = TextEditingController(text: '4');
  final _fitnessCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _raceDate = DateTime(
    DateTime.now().year,
    8,
    15,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _distanceCtrl.dispose();
    _timeCtrl.dispose();
    _daysCtrl.dispose();
    _fitnessCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _raceDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _raceDate = picked);
  }

  TrainingGoal? _buildGoal() {
    final distance = double.tryParse(_distanceCtrl.text.trim());
    if (distance == null || distance <= 0) {
      _snack('Geçerli mesafe girin (metre).');
      return null;
    }
    if (_timeCtrl.text.trim().isEmpty) {
      _snack('Hedef süre girin (ör. 10:20).');
      return null;
    }
    return TrainingGoal(
      name: _nameCtrl.text.trim().isEmpty ? 'Hedef' : _nameCtrl.text.trim(),
      raceDate: _raceDate,
      distanceMeters: distance,
      targetTime: _timeCtrl.text.trim(),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showPromptAndContinue() {
    final goal = _buildGoal();
    if (goal == null) return;
    final days = int.tryParse(_daysCtrl.text.trim()) ?? 4;

    final prompt = TrainingPlanPromptBuilder.build(
      goal: goal,
      daysPerWeek: days,
      currentFitness: _fitnessCtrl.text.trim(),
      userNotes: _notesCtrl.text.trim(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Prompt — ChatGPT / Gemini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kopyala, LLM\'e yapıştır, dönen JSON\'u bir sonraki ekranda içe aktar.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: SelectableText(
                      prompt,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prompt));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Prompt kopyalandı')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Promptu Kopyala'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImportPlanScreen(goalHint: goal),
                      ),
                    );
                  },
                  child: const Text('JSON Yapıştır → Import'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hedef Oluştur')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Hedef adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Yarış / hedef tarihi'),
            subtitle: Text(
              '${_raceDate.day}.${_raceDate.month}.${_raceDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _distanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mesafe (m)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hedef süre (M:SS)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _daysCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Haftada koşu günü',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fitnessCtrl,
            decoration: const InputDecoration(
              labelText: 'Mevcut seviye (opsiyonel)',
              hintText: 'ör. 5K ~25 dk',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notlar (opsiyonel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _showPromptAndContinue,
            child: const Text('Prompt Oluştur ve Devam Et'),
          ),
        ],
        ),
      ),
    );
  }
}
