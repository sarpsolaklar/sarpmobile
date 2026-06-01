import 'package:flutter/material.dart';
import 'package:smart_health_app/models/activity.dart';
import 'package:smart_health_app/database/database_helper.dart';
import 'package:smart_health_app/services/cloud_sync_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Activity? _todayActivity;
  List<Activity> _recent = [];
  bool _isLoading = true;

  final String _today = DateTime.now().toIso8601String().substring(0, 10);
  static const int _stepGoal = 10000;
  static const int _calGoal = 600;
  static const int _minGoal = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final today = await DatabaseHelper.instance.getActivityByDate(_today);
    final recent = await DatabaseHelper.instance.getRecentActivities(days: 7);
    setState(() {
      _todayActivity = today;
      _recent = recent;
      _isLoading = false;
    });
  }

  Future<void> _showLogDialog({Activity? existing}) async {
    final formKey = GlobalKey<FormState>();
    final stepsCtrl = TextEditingController(
      text: existing?.steps.toString() ?? '',
    );
    final calCtrl = TextEditingController(
      text: existing?.caloriesBurned.toString() ?? '',
    );
    final minCtrl = TextEditingController(
      text: existing?.exerciseMinutes.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            existing == null ? 'Log Today\'s Activity' : 'Update Activity',
            style: theme.textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    stepsCtrl,
                    'Steps',
                    Icons.directions_walk,
                    theme,
                    cs,
                    max: 100000,
                  ),
                  const SizedBox(height: 16),
                  _dialogField(
                    calCtrl,
                    'Calories Burned',
                    Icons.local_fire_department,
                    theme,
                    cs,
                    max: 10000,
                  ),
                  const SizedBox(height: 16),
                  _dialogField(
                    minCtrl,
                    'Exercise Minutes',
                    Icons.timer,
                    theme,
                    cs,
                    max: 1440,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    maxLength: 240,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(
                        Icons.note_alt_outlined,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final act = Activity(
                  date: _today,
                  steps: int.tryParse(stepsCtrl.text) ?? 0,
                  caloriesBurned: int.tryParse(calCtrl.text) ?? 0,
                  exerciseMinutes: int.tryParse(minCtrl.text) ?? 0,
                  notes: notesCtrl.text,
                );
                await DatabaseHelper.instance.upsertActivity(act);
                await CloudSyncService.instance.syncActivity(act);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    ThemeData theme,
    ColorScheme cs, {
    required int max,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
      ),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null) return 'Enter a number.';
        if (number < 0) return 'Value cannot be negative.';
        if (number > max) return 'Value is too high.';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final act = _todayActivity;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogDialog(existing: _todayActivity),
        icon: const Icon(Icons.add),
        label: Text(act == null ? 'Log Today' : 'Update Today'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's summary
                  _buildTodayCard(theme, cs, act),
                  const SizedBox(height: 24),

                  // Ring stats row
                  if (act != null) ...[
                    _buildRingRow(theme, cs, act),
                    const SizedBox(height: 24),
                  ],

                  // 7-day history
                  Text(
                    'Last 7 Days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    Center(
                      child: Text(
                        'No activity logged yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._recent.map((a) => _buildHistoryItem(theme, cs, a)),
                ],
              ),
            ),
    );
  }

  Widget _buildTodayCard(ThemeData theme, ColorScheme cs, Activity? act) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onPrimary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            act == null ? 'No activity logged' : '${act.steps} steps',
            style: theme.textTheme.displaySmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (act != null) ...[
            const SizedBox(height: 4),
            Text(
              '${act.caloriesBurned} kcal  •  ${act.exerciseMinutes} min active',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRingRow(ThemeData theme, ColorScheme cs, Activity act) {
    return Row(
      children: [
        Expanded(
          child: _buildRingCard(
            theme,
            cs,
            'Steps',
            act.steps,
            _stepGoal,
            Icons.directions_walk,
            cs.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRingCard(
            theme,
            cs,
            'Calories',
            act.caloriesBurned,
            _calGoal,
            Icons.local_fire_department,
            cs.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRingCard(
            theme,
            cs,
            'Minutes',
            act.exerciseMinutes,
            _minGoal,
            Icons.timer,
            cs.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRingCard(
    ThemeData theme,
    ColorScheme cs,
    String label,
    int value,
    int goal,
    IconData icon,
    Color color,
  ) {
    final progress = (value / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, ColorScheme cs, Activity act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.directions_run, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.date,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${act.steps} steps  •  ${act.caloriesBurned} kcal',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '${act.exerciseMinutes}m',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
