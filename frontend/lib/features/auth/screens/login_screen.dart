import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../../../navigation/auth_notifier.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/password_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/auth_header.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _rememberMe = false;

  static const _rememberEmailKey = 'remember_email';
  static const _rememberPasswordKey = 'remember_password';
  static const _rememberMeKey = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_rememberMeKey) ?? false;
    if (saved) {
      final email = prefs.getString(_rememberEmailKey) ?? '';
      final password = prefs.getString(_rememberPasswordKey) ?? '';
      _emailController.text = email;
      _passwordController.text = password;
      if (mounted) setState(() => _rememberMe = true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_rememberEmailKey, _emailController.text.trim());
        await prefs.setString(_rememberPasswordKey, _passwordController.text);
        await prefs.setBool(_rememberMeKey, true);
      } else {
        await prefs.remove(_rememberEmailKey);
        await prefs.remove(_rememberPasswordKey);
        await prefs.remove(_rememberMeKey);
      }

      if (!mounted) return;
      AuthNotifier.instance.refresh();
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
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final hp = isWide ? 48.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Bon retour',
                      subtitle: 'Connectez-vous à votre compte',
                    ),
                    const SizedBox(height: 40),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email requis';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (v.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Text('Se souvenir de moi',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              'Mot de passe oublié?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LoadingButton(
                      label: 'Se connecter',
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte?',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text("S'inscrire"),
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
