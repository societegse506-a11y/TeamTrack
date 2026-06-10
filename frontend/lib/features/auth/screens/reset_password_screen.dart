import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/password_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/auth_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Nouveau mot de passe',
                    subtitle: 'Entrez le token reçu et votre nouveau mot de passe',
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _codeController,
                    label: 'Code de vérification',
                    icon: Icons.vpn_key_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Code requis';
                      if (v.trim().length != 6) return 'Le code doit contenir 6 chiffres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _passwordController,
                    label: 'Nouveau mot de passe',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (v.length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le mot de passe',
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: 'Réinitialiser',
                    isLoading: _isLoading,
                    onPressed: _resetPassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
