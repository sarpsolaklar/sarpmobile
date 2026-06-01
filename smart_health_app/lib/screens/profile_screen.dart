import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_health_app/services/cloud_sync_service.dart';
import 'package:smart_health_app/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> _profile = {};
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await ProfileService.instance.getProfile();
    setState(() {
      _profile = p;
      _nameCtrl.text = p['name'] ?? '';
      _emailCtrl.text = p['email'] ?? '';
      _ageCtrl.text = p['age'] ?? '';
      _weightCtrl.text = p['weight'] ?? '';
      _heightCtrl.text = p['height'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final validationMessage = _validateProfile();
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    await ProfileService.instance.saveProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      age: _ageCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      height: _heightCtrl.text.trim(),
    );
    await CloudSyncService.instance.syncProfile({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'age': _ageCtrl.text.trim(),
      'weight': _weightCtrl.text.trim(),
      'height': _heightCtrl.text.trim(),
    });
    await _loadProfile();
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
    }
  }

  String? _validateProfile() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());

    if (name.length < 2) return 'Please enter your full name.';
    if (!email.contains('@')) return 'Please enter a valid email address.';
    if (age == null || age < 1 || age > 120) {
      return 'Please enter a valid age.';
    }
    if (weight == null || weight < 2 || weight > 500) {
      return 'Please enter a valid weight.';
    }
    if (height == null || height < 30 || height > 260) {
      return 'Please enter a valid height.';
    }
    return null;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = !_isEditing),
              tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: cs.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: cs.primary,
                          ),
                        ),
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 3),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: cs.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_isEditing) ...[
                    Text(
                      _profile['name'] ?? '',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile['email'] ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCol(
                          theme,
                          cs,
                          'Age',
                          (_profile['age'] ?? '—').toString(),
                        ),
                        _buildStatCol(
                          theme,
                          cs,
                          'Weight',
                          '${_profile['weight'] ?? '—'} kg',
                        ),
                        _buildStatCol(
                          theme,
                          cs,
                          'Height',
                          '${_profile['height'] ?? '—'} cm',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Menu items
                    _buildMenuItem(
                      theme,
                      cs,
                      Icons.medical_information,
                      'Medical Records',
                      () {},
                    ),
                    _buildMenuItem(
                      theme,
                      cs,
                      Icons.settings,
                      'Settings',
                      () {},
                    ),
                    _buildMenuItem(
                      theme,
                      cs,
                      Icons.privacy_tip_outlined,
                      'Privacy & Data',
                      () => Navigator.pushNamed(context, '/privacy'),
                    ),
                    _buildMenuItem(
                      theme,
                      cs,
                      Icons.help_outline,
                      'Help & Support',
                      () {},
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Edit form
                    const SizedBox(height: 24),
                    _buildEditCard(theme, cs),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveProfile,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEditCard(ThemeData theme, ColorScheme cs) {
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
        children: [
          _editField(_nameCtrl, 'Full Name', Icons.person_outline),
          const SizedBox(height: 20),
          _editField(
            _emailCtrl,
            'Email',
            Icons.email_outlined,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _editField(
                  _ageCtrl,
                  'Age',
                  Icons.cake_outlined,
                  type: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _editField(
                  _weightCtrl,
                  'Weight (kg)',
                  Icons.monitor_weight_outlined,
                  type: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _editField(
                  _heightCtrl,
                  'Height (cm)',
                  Icons.height,
                  type: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _buildStatCol(
    ThemeData theme,
    ColorScheme cs,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelLarge),
      ],
    );
  }

  Widget _buildMenuItem(
    ThemeData theme,
    ColorScheme cs,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.outlineVariant),
        onTap: onTap,
      ),
    );
  }
}
