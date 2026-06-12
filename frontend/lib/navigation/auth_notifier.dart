import 'dart:async';
import 'package:flutter/foundation.dart';
import '../shared/api/api_client.dart';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._();
  static AuthNotifier get instance => _instance;

  bool _isAuthenticated = false;
  bool _isAdmin = false;
  bool _initialized = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  bool get initialized => _initialized;

  AuthNotifier._();

  Timer? _timer;

  Future<void> init() async {
    await _checkAuth();
    _initialized = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAuth());
  }

  Future<void> refresh() async {
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authed = await ApiClient.isLoggedIn();
    final admin = authed ? await ApiClient.isAdmin() : false;
    if (authed != _isAuthenticated || admin != _isAdmin || !_initialized) {
      _isAuthenticated = authed;
      _isAdmin = admin;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
