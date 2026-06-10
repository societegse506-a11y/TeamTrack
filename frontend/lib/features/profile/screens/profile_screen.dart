import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../navigation/auth_notifier.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/notifiers/settings_notifier.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _phone = '';
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final body = await ApiClient.getSafe('/auth/me');
      if (body != null && body['success'] == true && mounted) {
        final data = body['data'] as Map<String, dynamic>;
        setState(() {
          final nom = data['nom'] ?? '';
          final prenom = data['prenom'] ?? '';
          _name = '$prenom $nom';
          _email = data['email'] ?? '';
          _phone = data['telephone'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _openEditProfile() async {
    final changed = await context.push('/profile/edit');
    if (changed == true) {
      _loadProfile();
      SettingsNotifier.instance.refresh();
    }
  }

  String _initials() {
    final parts = _name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name.isNotEmpty ? _name[0].toUpperCase() : '?';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiClient.clearToken();
    AuthNotifier.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      final hp = isWide ? 32.0 : 20.0;
      return Scaffold(
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(hp, 48, hp, isWide ? 40 : 32),
            decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  LargeAvatar(initials: _initials()),
                  const SizedBox(height: 16),
                  Text(
                    _name.isEmpty ? 'User' : _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email.isEmpty ? 'user@example.com' : _email,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    iconColor: AppColors.primary,
                    title: 'Personal Information',
                    onTap: _openEditProfile,
                  ),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade200),
                  _ProfileTile(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Email',
                    subtitle: _email,
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade200),
                  _ProfileTile(
                    icon: Icons.phone_outlined,
                    iconColor: AppColors.success,
                    title: 'Phone',
                    subtitle: _phone.isNotEmpty ? _phone : null,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp),
            child: FilledButton.tonalIcon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.error.withAlpha(15),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          SizedBox(height: isWide ? 48 : 32),
        ],
      ),
    );
    });
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: Colors.grey.shade600))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
