import 'package:flutter/material.dart';
import 'package:smart_health_app/models/medication.dart';
import 'package:smart_health_app/database/database_helper.dart';
import 'package:smart_health_app/services/cloud_sync_service.dart';
import 'package:smart_health_app/services/profile_service.dart';
import 'package:smart_health_app/screens/medications_screen.dart';
import 'package:smart_health_app/screens/activity_screen.dart';
import 'package:smart_health_app/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<Medication> _medications = [];
  bool _isLoading = true;
  final String _today = DateTime.now().toIso8601String().substring(0, 10);

  // Hydration
  int _hydrationMl = 0;
  int _hydrationGoal = 2500;
  bool _hydrationLoading = true;

  @override
  void initState() {
    super.initState();
    _syncAndLoad();
  }

  Future<void> _syncAndLoad() async {
    await CloudSyncService.instance.pullFromCloud();
    await _loadMedications();
    await _loadHydration();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    final meds = await DatabaseHelper.instance.readMedicationsForDate(_today);
    setState(() {
      _medications = meds;
      _isLoading = false;
    });
  }

  Future<void> _loadHydration() async {
    final ml = await ProfileService.instance.getTodayHydration();
    final goal = await ProfileService.instance.getHydrationGoal();
    setState(() {
      _hydrationMl = ml;
      _hydrationGoal = goal;
      _hydrationLoading = false;
    });
  }

  Future<void> _addWater(int ml) async {
    final newVal = await ProfileService.instance.addHydration(ml);
    setState(() => _hydrationMl = newVal);
  }

  Future<void> _resetWater() async {
    await ProfileService.instance.resetHydration();
    setState(() => _hydrationMl = 0);
  }

  Future<void> _toggleMedication(Medication med) async {
    final id = med.id;
    if (id == null) return;
    await DatabaseHelper.instance.setMedicationDoneForDate(
      medicationId: id,
      date: _today,
      isDone: !med.isDone,
    );
    await CloudSyncService.instance.syncMedicationLog(
      medicationId: id,
      date: _today,
      isDone: !med.isDone,
    );
    _loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Sanctuary Health',
              style: theme.textTheme.titleLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: cs.surfaceContainerHigh,
              child: Icon(Icons.person, color: cs.primary),
            ),
          ),
        ],
        backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(theme, cs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() => _currentIndex = idx);
              if (idx == 0) _loadMedications();
            },
            backgroundColor: cs.surfaceContainerLowest,
            indicatorColor: cs.primaryContainer.withValues(alpha: 0.5),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication),
                label: 'Meds',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_run_outlined),
                selectedIcon: Icon(Icons.directions_run),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme cs) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(theme, cs);
      case 1:
        return const MedicationsScreen();
      case 2:
        return const ActivityScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent(theme, cs);
    }
  }

  Widget _buildHomeContent(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good morning! 👋', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Here is your daily health summary.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickActions(theme, cs),
          const SizedBox(height: 32),
          _buildHydrationCard(theme, cs),
          const SizedBox(height: 24),
          _buildMedicationsCard(theme, cs),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ai_assistant'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI Asistan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/maps'),
            icon: const Icon(Icons.map),
            label: const Text('Eczaneler'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hydration Card ────────────────────────────────────────────────────────

  Widget _buildHydrationCard(ThemeData theme, ColorScheme cs) {
    final progress = _hydrationLoading
        ? 0.0
        : (_hydrationMl / _hydrationGoal).clamp(0.0, 1.0);
    final liters = (_hydrationMl / 1000).toStringAsFixed(1);
    final goalL = (_hydrationGoal / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hydration', style: theme.textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.refresh, color: cs.onSurfaceVariant),
                onPressed: _resetWater,
                tooltip: 'Reset',
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: cs.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.water_drop, color: cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      '${liters}L',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('of ${goalL}L', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick-add buttons
          Row(
            children: [
              Expanded(child: _waterBtn(theme, cs, '+150 ml', 150)),
              const SizedBox(width: 8),
              Expanded(child: _waterBtn(theme, cs, '+250 ml', 250)),
              const SizedBox(width: 8),
              Expanded(child: _waterBtn(theme, cs, '+500 ml', 500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waterBtn(ThemeData theme, ColorScheme cs, String label, int ml) {
    return OutlinedButton(
      onPressed: () => _addWater(ml),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
      ),
    );
  }

  // ── Medications Card ──────────────────────────────────────────────────────

  Widget _buildMedicationsCard(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Medications', style: theme.textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.add_circle, color: cs.primary),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/add_medication',
                  );
                  if (result == true) _loadMedications();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_medications.isEmpty)
            Center(
              child: Text(
                'No medications added yet.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ..._medications.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildMedItem(theme, cs, med),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedItem(ThemeData theme, ColorScheme cs, Medication med) {
    final isDone = med.isDone;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medication, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: theme.textTheme.titleMedium),
                Text(med.dosage, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (med.notifyEnabled)
                    Icon(
                      Icons.notifications_active,
                      size: 14,
                      color: cs.primary,
                    ),
                  const SizedBox(width: 4),
                  Text(med.time, style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _toggleMedication(med),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? cs.secondary : cs.outlineVariant,
                      width: 2,
                    ),
                    color: isDone ? cs.secondary : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: isDone ? Colors.white : cs.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
