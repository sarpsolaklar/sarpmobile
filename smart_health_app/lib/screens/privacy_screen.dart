import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_health_app/database/database_helper.dart';
import 'package:smart_health_app/services/cloud_sync_service.dart';
import 'package:smart_health_app/services/profile_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isBusy = false;

  Future<void> _clearLocalData() async {
    setState(() => _isBusy = true);
    await DatabaseHelper.instance.clearHealthData();
    await ProfileService.instance.clearProfile();
    if (mounted) {
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local health data cleared.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This deletes cloud health data and your account. You may need to sign in again if your session is old.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await CloudSyncService.instance.deleteCloudData();
      await DatabaseHelper.instance.clearHealthData();
      await ProfileService.instance.clearProfile();
      await FirebaseAuth.instance.currentUser?.delete();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        final message = e.code == 'requires-recent-login'
            ? 'Please sign out and sign in again before deleting your account.'
            : e.message ?? 'Account deletion failed.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        backgroundColor: cs.surfaceContainerLowest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Stored data', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _infoTile(
            context,
            Icons.medication,
            'Medication and reminder data',
            'Stored locally and synced to your signed-in Firebase account.',
          ),
          _infoTile(
            context,
            Icons.directions_run,
            'Activity and hydration data',
            'Stored locally. Activity logs sync to Firebase when signed in.',
          ),
          _infoTile(
            context,
            Icons.person,
            'Profile data',
            'Stored locally and synced to Firebase when signed in.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _clearLocalData,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear Local Data'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isBusy ? null : _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
          ),
          if (_isBusy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
