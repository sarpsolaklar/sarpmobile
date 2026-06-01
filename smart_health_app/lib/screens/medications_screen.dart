import 'package:flutter/material.dart';
import 'package:smart_health_app/models/medication.dart';
import 'package:smart_health_app/database/database_helper.dart';
import 'package:smart_health_app/services/cloud_sync_service.dart';
import 'package:smart_health_app/services/notification_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<Medication> _medications = [];
  bool _isLoading = true;
  final String _today = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    final meds = await DatabaseHelper.instance.readMedicationsForDate(_today);
    setState(() {
      _medications = meds;
      _isLoading = false;
    });
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

  Future<void> _deleteMedication(Medication med) async {
    if (med.notifyEnabled && med.id != null) {
      await NotificationService.instance.cancelReminder(med.id!);
    }
    await DatabaseHelper.instance.deleteMedication(med.id!);
    await CloudSyncService.instance.deleteMedication(med.id!);
    _loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Medications',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
              ? Center(
                  child: Text(
                    'No medications registered yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    return _buildMedItem(theme, colorScheme, med);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_medication');
          if (result == true) {
            _loadMedications();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Meds'),
      ),
    );
  }

  Widget _buildMedItem(ThemeData theme, ColorScheme colorScheme, Medication medication) {
    final bool isDone = medication.isDone;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDone ? colorScheme.secondaryContainer : colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.medication,
            color: isDone ? colorScheme.onSecondaryContainer : colorScheme.primary,
          ),
        ),
        title: Text(medication.name, style: theme.textTheme.titleLarge),
        subtitle: Text(
          '${medication.dosage} - ${medication.time}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _deleteMedication(medication),
            ),
            GestureDetector(
              onTap: () => _toggleMedication(medication),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? colorScheme.secondary : colorScheme.outlineVariant,
                    width: 2,
                  ),
                  color: isDone ? colorScheme.secondary : Colors.transparent,
                ),
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: isDone ? Colors.white : colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
