import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/training_program_provider.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/repositories/training_program_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import 'create_workout_screen.dart';

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();
  List<WorkoutPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _repository.getAllPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _deletePlan(String id) async {
    final programRepo = getIt<TrainingProgramRepository>();
    final linked = await programRepo.getActiveProgramReferencingWorkoutPlan(id);
    await programRepo.clearWorkoutPlanReferences(id);
    await _repository.deletePlan(id);
    if (linked != null) {
      await ref.read(activeTrainingProgramProvider.notifier).refresh();
    }
    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Planları'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz plan yok',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Yeni bir etkinlik planı oluştur!',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _plans.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.orange,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${plan.stepCount} adım',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (plan.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                plan.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(plan),
                        ),
                        onTap: () => _showPlanActions(plan),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateWorkoutScreen()),
          );
          if (result == true) {
            _loadPlans();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPlanActions(WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.directions_run, color: Colors.blue),
              title: const Text('Koşuya Başla'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(pendingRunWorkoutProvider.notifier).state = plan;
                ref.read(mainTabIndexProvider.notifier).state = 0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${plan.name} — Koş sekmesine geçildi')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Düzenle'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateWorkoutScreen(initialPlan: plan),
                  ),
                );
                if (result == true) _loadPlans();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog(plan);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(WorkoutPlan plan) async {
    final programRepo = getIt<TrainingProgramRepository>();
    final linkedProgram =
        await programRepo.getActiveProgramReferencingWorkoutPlan(plan.id);

    if (!mounted) return;

    final message = linkedProgram != null
        ? '«${plan.name}» aktif hedef planına («${linkedProgram.goal.name}») bağlı.\n\n'
            'Silersen plandaki ilgili günler etkinliksiz kalır. Yine de silinsin mi?'
        : '${plan.name} etkinliğini silmek istediğinize emin misiniz?';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(linkedProgram != null ? 'Bağlı etkinlik' : 'Etkinliği sil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _deletePlan(plan.id);
    }
  }
}
