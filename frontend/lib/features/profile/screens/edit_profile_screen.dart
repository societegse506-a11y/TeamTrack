import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../shared/api/api_client.dart';
import '../../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final body = await ApiClient.getSafe('/auth/me');
      if (body != null && mounted) {
        final data = body['data'] as Map<String, dynamic>? ?? body;
        _nomController.text = data['nom'] ?? '';
        _prenomController.text = data['prenom'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telephoneController.text = data['telephone'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
      };

      final newPw = _newPasswordController.text;
      if (newPw.isNotEmpty) {
        body['currentPassword'] = _currentPasswordController.text;
        body['newPassword'] = newPw;
      }

      final response = await ApiClient.put('/auth/me', body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final res = jsonDecode(response.body) as Map<String, dynamic>;
        _showError(res['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('Failed to update profile');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Text('Personal Information',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _prenomController,
                              decoration: _inputDecoration('First Name', Icons.person_outline),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _nomController,
                              decoration: _inputDecoration('Last Name', Icons.person_outline),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              readOnly: true,
                              decoration: _inputDecoration('Email', Icons.email_outlined).copyWith(
                                fillColor: Colors.grey.shade100,
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _telephoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration('Phone', Icons.phone_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.lock_outline, size: 20, color: AppColors.warning),
                                ),
                                const SizedBox(width: 10),
                                Text('Change Password',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leave blank to keep current password',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              decoration: _inputDecoration('Current Password', Icons.lock_outline),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: _inputDecoration('New Password', Icons.lock_outline),
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: _inputDecoration('Confirm New Password', Icons.lock_outline),
                              validator: (v) {
                                if (_newPasswordController.text.isNotEmpty && v != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
    );
  }
}
