import 'package:flutter/material.dart';
import 'package:rotina_comercial/auth/auth_provider.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/utils/toast.dart';
import 'package:provider/provider.dart';

class LoginTokenScreen extends StatefulWidget {
  const LoginTokenScreen({super.key});

  @override
  State<LoginTokenScreen> createState() => _LoginTokenScreenState();
}

class _LoginTokenScreenState extends State<LoginTokenScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  String _extractToken(String raw) {
    var text = raw.trim();
    // Se for uma URL com ?token=..., extrai o valor
    final qi = text.indexOf('token=');
    if (qi >= 0) {
      var value = text.substring(qi + 'token='.length);
      final amp = value.indexOf('&');
      if (amp >= 0) value = value.substring(0, amp);
      return value.trim();
    }
    return text;
  }

  Future<void> _handleEnter() async {
    final token = _extractToken(_controller.text);
    if (token.isEmpty) {
      showToast('Cole a URL ou o token');
      return;
    }
    setState(() => _saving = true);
    showToast('Entrando...');
    await context.read<AuthProvider>().setAuthenticated(token);
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Entrar com token',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_rotina.png', width: 80, height: 80),
            const SizedBox(height: 16),
            const Text(
              'Cole a URL retornada ou o token de acesso',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'https://...?token=xxx  ou  cole o token direto',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: _saving ? null : _handleEnter,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENTRAR',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
