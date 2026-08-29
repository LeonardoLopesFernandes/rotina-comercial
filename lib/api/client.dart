import 'package:dio/dio.dart';
import 'package:rotina_comercial/storage/session.dart';

const String baseUrl = 'https://rotina-comercial-bff.americanas.io/';
const String appOrigin = 'https://rotina-comercial.americanas.io';

String? _authToken;
bool _autoLoginTriggered = false;
void Function()? _onSessionExpired;

void setAuthToken(String token) {
  _authToken = token;
  if (token.isNotEmpty) {
    _autoLoginTriggered = false;
  }
}

String? getAuthToken() => _authToken;

void clearToken() {
  _authToken = null;
}

void setOnSessionExpired(void Function() handler) {
  _onSessionExpired = handler;
}

Future<void> _handleSessionExpired() async {
  if (_autoLoginTriggered) return;
  _autoLoginTriggered = true;
  clearToken();
  await Session.clearToken();
  _onSessionExpired?.call();
}

final Dio apiClient = Dio(BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: const Duration(seconds: 60),
  receiveTimeout: const Duration(seconds: 60),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'x-requested-with': 'com.unixshells.devbrowser',
    'Origin': appOrigin,
    'Referer': '$appOrigin/',
  },
));

void setupApiInterceptors() {
  apiClient.interceptors.clear();
  apiClient.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (_authToken != null && _authToken!.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $_authToken';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401 && _authToken != null) {
        await _handleSessionExpired();
      }
      return handler.next(error);
    },
  ));
}

String mapErrorMessage(Object error) {
  final message = error is DioException
      ? error.message ?? 'Erro'
      : error.toString();
  if (message.contains('401')) return '❌ Token expirado! Faça login novamente.';
  if (message.contains('403')) return '❌ Acesso negado!';
  if (message.contains('500')) return '❌ Erro no servidor (500). Tente novamente.';
  if (message.contains('conexão') || message.contains('Connection')) {
    return '❌ Sem conexão com a internet.';
  }
  return '❌ $message';
}

String mapGenericError(Object error) {
  final message = error is DioException
      ? error.message ?? 'Erro'
      : error.toString();
  if (message.contains('400') || message.contains('409')) {
    return '⚠️ Este item já foi respondido. Recarregue a lista.';
  }
  return '❌ $message';
}

String errorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status != 401) {
      return 'Erro $status';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Erro de conexão: timeout';
    }
  }
  final message = error is DioException ? error.message ?? '' : error.toString();
  if (message.contains('Network Error') || message.contains('conexão')) {
    return 'Erro de conexão: sem internet';
  }
  return message;
}
