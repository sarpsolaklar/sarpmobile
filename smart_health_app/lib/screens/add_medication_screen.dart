import 'package:flutter/material.dart';
import 'package:smart_health_app/models/medication.dart';
import 'package:smart_health_app/database/database_helper.dart';
import 'package:smart_health_app/services/cloud_sync_service.dart';
import 'package:smart_health_app/services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _notifyEnabled = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final String timeString = _selectedTime.format(context);
      final med = Medication(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: timeString,
        isDone: false,
        notifyEnabled: _notifyEnabled,
      );

      final saved = await DatabaseHelper.instance.createMedication(med);
      await CloudSyncService.instance.syncMedication(saved);

      if (_notifyEnabled && saved.id != null) {
        final scheduled = await NotificationService.instance.scheduleDailyReminder(
          id: saved.id!,
          medicationName: saved.name,
          dosage: saved.dosage,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        );
        if (mounted && !scheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Medication saved. Note: Notifications may not be supported on this platform.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Add Medication',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Medication Name',
                        prefixIcon: const Icon(Icons.medication_liquid),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(context, '/scanner');
                            if (result != null && result is String) {
                              setState(() {
                                _nameController.text = result;
                              });
                            }
                          },
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage (e.g., 10mg, 1 pill)',
                        prefixIcon: Icon(Icons.line_weight),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Please enter a dosage' : null,
                    ),
                    const SizedBox(height: 24),

                    // Time picker
                    InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 16),
                            Text(
                              'Time: ${_selectedTime.format(context)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            Icon(Icons.edit,
                                color: colorScheme.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notification toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _notifyEnabled
                            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Daily Reminder',
                            style: theme.textTheme.bodyLarge),
                        subtitle: Text(
                          _notifyEnabled
                              ? 'You\'ll be notified at ${_selectedTime.format(context)}'
                              : 'Enable to get a daily notification',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        secondary: Icon(
                          _notifyEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: _notifyEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        value: _notifyEnabled,
                        onChanged: (v) => setState(() => _notifyEnabled = v),
                        activeTrackColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMedication,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
