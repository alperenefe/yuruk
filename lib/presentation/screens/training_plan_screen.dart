import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/training_program_provider.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/scheduled_day.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/repositories/workout_repository.dart';
import 'goal_setup_screen.dart';
import 'import_plan_screen.dart';

class TrainingPlanScreen extends ConsumerStatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  ConsumerState<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends ConsumerState<TrainingPlanScreen> {
  DateTime _weekAnchor = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(activeTrainingProgramProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedef'),
        actions: [
          if (programAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'JSON import',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportPlanScreen()),
              ),
            ),
        ],
      ),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (program) {
          if (program == null) return _emptyState();
          return _activeProgram(program);
        },
      ),
      floatingActionButton: programAsync.valueOrNull == null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalSetupScreen()),
              ),
              icon: const Icon(Icons.flag),
              label: const Text('Hedef'),
            )
          : null,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Henüz antrenman planı yok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Hedefini gir, promptu LLM\'e ver, JSON\'u içe aktar.\n'
              'Örn. 15 Ağustos — 2400 m — 10:20',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeProgram(TrainingProgram program) {
    final nextDay = program.nextPendingDay;
    final weekDays = program.daysForWeekContaining(_weekAnchor);

    return RefreshIndicator(
      onRefresh: () => ref.read(activeTrainingProgramProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _countdownCard(program),
          const SizedBox(height: 12),
          if (nextDay != null) ...[
            _todayCard(program, nextDay),
            const SizedBox(height: 16),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Yakın zamanda planlı koşu yok — dinlenme günü.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _progressRow(program),
          const SizedBox(height: 16),
          _weekHeader(weekDays),
          ...weekDays.map((d) => _dayTile(program, d)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Planı Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _countdownCard(TrainingProgram program) {
    final g = program.goal;
    final days = g.daysUntilRace;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${g.distanceLabel} · hedef ${g.targetTime}'
              '${g.targetPacePerKm != null ? ' (~${g.targetPacePerKm}/km)' : ''}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  days > 0 ? '$days gün kaldı' : days == 0 ? 'Bugün!' : 'Geçti',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(g.raceDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(TrainingProgram program, ScheduledDay day) {
    final isRest = day.isRest;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final diff = day.date.difference(todayDate).inDays;
    final dayLabel = diff == 0
        ? 'Bugün'
        : diff == 1
            ? 'Yarın'
            : '$diff gün sonra · ${_formatDate(day.date)}';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: diff == 0 ? Colors.orange : Colors.blue),
                const SizedBox(width: 8),
                Text(
                  dayLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _statusChip(day.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(day.title, style: const TextStyle(fontSize: 16)),
            if (day.description != null && day.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(day.description!),
              ),
            if (day.targetDistanceMeters != null)
              Text(
                'Mesafe: ${_formatDist(day.targetDistanceMeters!)}'
                '${day.targetPacePerKm != null ? ' @ ${day.targetPacePerKm}/km' : ''}',
              ),
            const SizedBox(height: 12),
            if (!isRest && day.status == ScheduledDayStatus.pending) ...[
              if (day.workoutPlanId != null)
                FilledButton.icon(
                  onPressed: () => _startRun(day.workoutPlanId!),
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Koşuya Başla'),
                ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _mark(day.id, ScheduledDayStatus.completed),
                    child: const Text('Tamamladım'),
                  ),
                  TextButton(
                    onPressed: () => _mark(day.id, ScheduledDayStatus.skipped),
                    child: const Text('Atla'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressRow(TrainingProgram program) {
    final done = program.completedCount;
    final total = program.runnableDaysCount;
    final pct = total > 0 ? done / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İlerleme: $done / $total koşu günü'),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: pct),
      ],
    );
  }

  Widget _weekHeader(List<ScheduledDay> days) {
    if (days.isEmpty) return const SizedBox.shrink();
    final start = days.first.date;
    final end = days.last.date;
    return Row(
      children: [
        const Text('Hafta', style: TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() {
            _weekAnchor = _weekAnchor.subtract(const Duration(days: 7));
          }),
        ),
        Text('${start.day}.${start.month} – ${end.day}.${end.month}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() {
            _weekAnchor = _weekAnchor.add(const Duration(days: 7));
          }),
        ),
      ],
    );
  }

  Widget _dayTile(TrainingProgram program, ScheduledDay day) {
    final isToday = day.isToday;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isToday ? Colors.orange.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${day.date.day}'),
        ),
        title: Text(day.title),
        subtitle: Text(
          [
            _typeLabel(day.type),
            if (day.targetDistanceMeters != null)
              _formatDist(day.targetDistanceMeters!),
            if (day.targetPacePerKm != null) '@ ${day.targetPacePerKm}',
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: _statusChip(day.status),
        onTap: day.status == ScheduledDayStatus.pending && !day.isRest
            ? () => _dayActions(day)
            : null,
      ),
    );
  }

  void _dayActions(ScheduledDay day) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(day.title),
              subtitle: Text(_formatDate(day.date)),
            ),
            if (day.workoutPlanId != null)
              ListTile(
                leading: const Icon(Icons.directions_run),
                title: const Text('Koşuya başla'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startRun(day.workoutPlanId!);
                },
              ),
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Tamamladım'),
              onTap: () {
                Navigator.pop(ctx);
                _mark(day.id, ScheduledDayStatus.completed);
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('Atla'),
              onTap: () {
                Navigator.pop(ctx);
                _mark(day.id, ScheduledDayStatus.skipped);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRun(String workoutPlanId) async {
    final plan = await getIt<WorkoutRepository>().getPlanById(workoutPlanId);
    if (plan == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrenman planı bulunamadı')),
      );
      return;
    }
    ref.read(pendingRunWorkoutProvider.notifier).state = plan;
    ref.read(mainTabIndexProvider.notifier).state = 0;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} — Koş sekmesine geçildi')),
    );
  }

  Future<void> _mark(String dayId, ScheduledDayStatus status) async {
    await ref.read(activeTrainingProgramProvider.notifier).markDay(status, dayId);
  }

  Future<void> _confirmDelete() async {
    final program = ref.read(activeTrainingProgramProvider).valueOrNull;
    if (program == null || !mounted) return;

    final linkedWorkoutIds = program.days
        .map((d) => d.workoutPlanId)
        .whereType<String>()
        .toSet();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Planı sil?'),
        content: const Text('Aktif antrenman planı ve takvim silinir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    var deleteLinkedWorkouts = false;
    if (linkedWorkoutIds.isNotEmpty) {
      final choice = await showDialog<bool?>(
        context: context,
        builder: (ctx) {
          final n = linkedWorkoutIds.length;
          return AlertDialog(
            title: const Text('Bağlı etkinlikler'),
            content: Text(
              'Bu planda $n antrenman etkinliği var (Etkinlikler sekmesi).\n\n'
              'Bunları da silmek ister misin? Hayır dersen etkinlikler kalır; '
              'plana bağlı olmak zorunda değiller.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Yalnızca plan'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Plan + etkinlikler'),
              ),
            ],
          );
        },
      );
      if (choice == null || !mounted) return;
      deleteLinkedWorkouts = choice;
    }

    await ref
        .read(activeTrainingProgramProvider.notifier)
        .deleteActive(deleteLinkedWorkouts: deleteLinkedWorkouts);
  }

  Widget _statusChip(ScheduledDayStatus status) {
    switch (status) {
      case ScheduledDayStatus.completed:
        return const Chip(
          label: Text('✓', style: TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
        );
      case ScheduledDayStatus.skipped:
        return const Chip(
          label: Text('—', style: TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
        );
      case ScheduledDayStatus.pending:
        return const SizedBox.shrink();
    }
  }

  String _formatDist(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.toInt()} m';
  }

  String _typeLabel(ScheduledDayType type) {
    switch (type) {
      case ScheduledDayType.easy:
        return 'Kolay';
      case ScheduledDayType.interval:
        return 'Interval';
      case ScheduledDayType.tempo:
        return 'Tempo';
      case ScheduledDayType.longRun:
        return 'Uzun';
      case ScheduledDayType.rest:
        return 'Dinlenme';
      case ScheduledDayType.race:
        return 'Yarış';
      case ScheduledDayType.test:
        return 'Test';
      case ScheduledDayType.unknown:
        return '';
    }
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}
