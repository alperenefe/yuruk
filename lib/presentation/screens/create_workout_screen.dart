import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/interval_step.dart';
import '../../domain/repositories/workout_repository.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<IntervalStep> _steps = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan adı giriniz')),
      );
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir adım ekleyiniz')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final plan = WorkoutPlan(
      id: const Uuid().v4(),
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      steps: _steps,
      createdAt: DateTime.now(),
    );

    await _repository.savePlan(plan);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _addStep() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddStepSheet(
        onAdd: (step) {
          setState(() {
            _steps.add(step);
          });
        },
      ),
    );
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Etkinlik Planı'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _savePlan,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Adı',
                    hintText: 'Örn: 400m Intervallar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (opsiyonel)',
                    hintText: 'Örn: Hız çalışması için intervallar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Adımlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Adım Ekle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _steps.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz adım eklenmedi\n"Adım Ekle" butonuna basın',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _steps.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final step = _steps.removeAt(oldIndex);
                        _steps.insert(newIndex, step);
                      });
                    },
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return Card(
                        key: ValueKey(step.id),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: step.isRest ? Colors.blue.shade100 : Colors.orange.shade100,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: step.isRest ? Colors.blue : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(step.displayText),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeStep(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddStepSheet extends StatefulWidget {
  final Function(IntervalStep) onAdd;

  const _AddStepSheet({required this.onAdd});

  @override
  State<_AddStepSheet> createState() => _AddStepSheetState();
}

class _AddStepSheetState extends State<_AddStepSheet> {
  IntervalType _type = IntervalType.distance;
  bool _isRest = false;
  final _distanceController = TextEditingController(text: '400');
  final _minutesController = TextEditingController(text: '2');
  final _secondsController = TextEditingController(text: '0');
  final _paceMinController = TextEditingController(text: '5');
  final _paceSecController = TextEditingController(text: '0');
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _paceMinController.dispose();
    _paceSecController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addStep() {
    IntervalStep? step;

    if (_type == IntervalType.distance) {
      final distance = double.tryParse(_distanceController.text);
      if (distance == null || distance <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli mesafe giriniz')),
        );
        return;
      }

      final paceMin = int.tryParse(_paceMinController.text) ?? 0;
      final paceSec = int.tryParse(_paceSecController.text) ?? 0;
      final pace = !_isRest && (paceMin > 0 || paceSec > 0)
          ? '$paceMin:${paceSec.toString().padLeft(2, '0')}'
          : null;

      step = IntervalStep.distance(
        id: const Uuid().v4(),
        meters: distance,
        targetPace: pace,
        isRest: _isRest,
        name: _nameController.text.isEmpty ? null : _nameController.text,
      );
    } else {
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final seconds = int.tryParse(_secondsController.text) ?? 0;
      
      if (minutes <= 0 && seconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli süre giriniz')),
        );
        return;
      }

      step = IntervalStep.time(
        id: const Uuid().v4(),
        duration: Duration(minutes: minutes, seconds: seconds),
        isRest: _isRest,
        name: _nameController.text.isEmpty ? null : _nameController.text,
      );
    }

    widget.onAdd(step);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Yeni Adım Ekle',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Adım Adı (opsiyonel)',
              hintText: 'Örn: Isınma, Hızlı, Dinlenme',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<IntervalType>(
            segments: const [
              ButtonSegment(value: IntervalType.distance, label: Text('Mesafe')),
              ButtonSegment(value: IntervalType.time, label: Text('Süre')),
            ],
            selected: {_type},
            onSelectionChanged: (Set<IntervalType> newSelection) {
              setState(() {
                _type = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_type == IntervalType.distance) ...[
            TextField(
              controller: _distanceController,
              decoration: const InputDecoration(
                labelText: 'Mesafe (metre)',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            if (!_isRest) ...[
              const Text('Hedef Tempo (opsiyonel)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _paceMinController,
                      decoration: const InputDecoration(
                        labelText: 'Dakika',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _paceSecController,
                      decoration: const InputDecoration(
                        labelText: 'Saniye',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('/km'),
                  ),
                ],
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: 'Dakika',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':'),
                ),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    decoration: const InputDecoration(
                      labelText: 'Saniye',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Dinlenme Adımı'),
            value: _isRest,
            onChanged: (value) {
              setState(() {
                _isRest = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ekle'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
