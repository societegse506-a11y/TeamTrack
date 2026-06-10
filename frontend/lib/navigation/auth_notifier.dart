import 'dart:async';
import 'package:flutter/foundation.dart';
import '../shared/api/api_client.dart';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._();
  static AuthNotifier get instance => _instance;

  bool _isAuthenticated = false;
  bool _initialized = false;

  bool get isAuthenticated => _isAuthenticated;
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
    if (authed != _isAuthenticated || !_initialized) {
      _isAuthenticated = authed;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
