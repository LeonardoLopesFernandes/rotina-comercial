import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rotina_comercial/api/client.dart';
import 'package:rotina_comercial/storage/session.dart';

enum AuthState { loading, authenticated, unauthenticated }

/// Decodifica o payload de um JWT (parte central) sem validar assinatura.
Map<String, dynamic>? _decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    // Base64url → Base64
    var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return jsonDecode(utf8.decode(base64Decode(normalized)))
        as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Extrai o nome do usuário de um token JWT.
/// Procura em user.nome, user.name, name, nome (qualquer nível).
String _extractUserNameFromToken(String token) {
  final payload = _decodeJwtPayload(token);
  if (payload == null) return '';
  // Estrutura preferida: { "user": { "nome": "..." } }
  final user = payload['user'];
  if (user is Map) {
    final n = user['nome'] ?? user['name'];
    if (n is String && n.isNotEmpty) return n;
  }
  // Fallbacks diretos no payload
  for (final key in ['nome', 'name']) {
    final v = payload[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return '';
}

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
      // Tenta extrair o nome do JWT; fallback para SharedPreferences
      _userName = _extractUserNameFromToken(savedToken);
      if (_userName.isEmpty) {
        _userName = await Session.getUserName();
      } else {
        await Session.saveUserName(_userName);
      }
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
    // Extrai o nome do usuário diretamente do JWT
    final jwtName = _extractUserNameFromToken(tokenToUse);
    if (jwtName.isNotEmpty) {
      _userName = jwtName;
      await Session.saveUserName(jwtName);
    }
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
