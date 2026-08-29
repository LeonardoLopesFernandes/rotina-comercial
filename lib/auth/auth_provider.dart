import 'package:flutter/foundation.dart';
import 'package:rotina_comercial/api/client.dart';
import 'package:rotina_comercial/storage/session.dart';

enum AuthState { loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.loading;
  String? _token;
  String _userName = '';
  bool _autoLogin = false;

  AuthState get state => _state;
  String? get token => _token;
  String get userName => _userName;
  bool get autoLogin => _autoLogin;

  AuthProvider() {
    setOnSessionExpired(_requestReauth);
    initialize();
  }

  Future<void> initialize() async {
    final savedToken = await Session.getToken();
    if (savedToken != null) {
      setAuthToken(savedToken);
      _token = savedToken;
      _userName = await Session.getUserName();
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> setAuthenticated(String newToken) async {
    // Preserva um token já renovado pelo BFF via Set-Cookie (interceptor),
    // caso contrário usa o token recém-recebido.
    final current = getAuthToken();
    final tokenToUse =
        (current != null && current.isNotEmpty) ? current : newToken;
    await Session.saveToken(tokenToUse);
    setAuthToken(tokenToUse);
    _token = tokenToUse;
    _autoLogin = false;
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await Session.saveUserName(name);
    notifyListeners();
  }

  Future<void> logout() async {
    await Session.clearToken();
    clearToken();
    _token = null;
    _userName = '';
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> _requestReauth() async {
    final hasCreds = await Session.hasSavedCredentials();
    _autoLogin = hasCreds;
    _token = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
