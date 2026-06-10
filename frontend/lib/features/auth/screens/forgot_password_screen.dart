import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/password_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/auth_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.forgotPassword(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification code sent to your email'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
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
            child: _codeSent
                ? _ResetPasswordForm(
                    email: _emailController.text.trim(),
                    apiService: _apiService,
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthHeader(
                          title: 'Mot de passe oublié?',
                          subtitle:
                              'Enter your email to receive a verification code',
                        ),
                        const SizedBox(height: 32),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        LoadingButton(
                          label: 'Send Code',
                          isLoading: _isLoading,
                          onPressed: _sendCode,
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

class _ResetPasswordForm extends StatefulWidget {
  final String email;
  final ApiService apiService;

  const _ResetPasswordForm({
    required this.email,
    required this.apiService,
  });

  @override
  State<_ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<_ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.apiService.resetPassword(
        email: widget.email,
        code: _codeController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset successful'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Reset Password',
            subtitle: 'Enter the code from your email and your new password',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.email,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            controller: _codeController,
            label: 'Verification Code',
            icon: Icons.vpn_key_outlined,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code required';
              if (v.trim().length != 6) return 'Code must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            label: 'New Password',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            validator: (v) {
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'Reset Password',
            isLoading: _isLoading,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }
}
