import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/password_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/auth_header.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../../dashboard/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentLocation();

      final result = await _apiService.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        password: _passwordController.text,
        lat: position.latitude,
        lng: position.longitude,
      );

      final userData = result['data'] ?? result;
      final userInfo = UserInfo(
        id: userData['_id'] ?? userData['id'] ?? '',
        nom: userData['nom'] ?? '',
        prenom: userData['prenom'] ?? '',
        email: userData['email'] ?? '',
        telephone: userData['telephone'] ?? '',
        lat: position.latitude,
        lng: position.longitude,
      );
      await UserService.saveUser(userInfo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie')),
      );
      Navigator.pop(context);
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion au serveur')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTermsInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.gps_fixed, size: 20, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('GPS & Location'),
          ],
        ),
        content: const Text(
          'This application requires access to your GPS location to function properly.\n\n'
          '• Your GPS coordinates are captured once during registration\n'
          '• This location becomes your fixed workplace location\n'
          '• Attendance check-ins are validated against this location\n'
          '• You must be within the allowed zone to check in\n'
          '• This location cannot be changed after registration',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _showTermsInfo,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    children: [
                      TextSpan(text: 'I accept the '),
                      TextSpan(
                        text: 'GPS location terms',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
              tooltip: 'Learn more',
              onPressed: _showTermsInfo,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final hp = isWide ? 48.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Créer un compte',
                    subtitle: 'Rejoignez-nous dès maintenant',
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _nomController,
                          label: 'Nom',
                          icon: Icons.person_outline,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requis';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthTextField(
                          controller: _prenomController,
                          label: 'Prénom',
                          icon: Icons.person_outline,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requis';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _telephoneController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Téléphone requis';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (v.length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 16),
                  LoadingButton(
                    label: "S'inscrire",
                    isLoading: _isLoading,
                    onPressed: _termsAccepted ? _register : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte?',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          );
          }),
        ),
      ),
    );
  }
}
