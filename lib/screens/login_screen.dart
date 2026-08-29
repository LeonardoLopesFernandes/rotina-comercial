import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rotina_comercial/storage/session.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/utils/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = true;
  bool _autoLoginDisparado = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final savedEmail = await Session.getSavedEmail();
    final savedPassword = await Session.getSavedPassword();
    _emailController.text = savedEmail;
    _passwordController.text = savedPassword;
    setState(() => _loading = false);

    final hasCreds = await Session.hasSavedCredentials();
    if (hasCreds && !_autoLoginDisparado) {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted && !_autoLoginDisparado) {
        _autoLoginDisparado = true;
        Navigator.of(context)
            .pushNamed('LoginWebView', arguments: {'autoLogin': true});
      }
    }
  }

  Future<void> _saveCredentials() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      await Session.saveCredentials(email, password);
    }
  }

  void _handleLogin() {
    _autoLoginDisparado = true;
    _saveCredentials();
    Navigator.of(context)
        .pushNamed('LoginWebView', arguments: {'autoLogin': false});
  }

  Future<void> _handleOpenBrowser() async {
    _saveCredentials();
    const url = 'https://sl-authorization.americanas.io/rotina-comercial';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      showToast('Não foi possível abrir o navegador: $e', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null && focus.hasFocus) {
          focus.unfocus();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo_rotina.png', width: 96, height: 96),
              const SizedBox(height: 8),
              const Text('Rotina Comercial',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('E-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('Senha').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _primaryButton('ENTRAR', _handleLogin),
              const SizedBox(height: 12),
              _secondaryButton('ENTRAR COM TOKEN', () {
                Navigator.of(context).pushNamed('LoginToken');
              }),
              const SizedBox(height: 12),
              _secondaryButton('ENTRAR VIA NAVEGADOR', _handleOpenBrowser),
            ],
          ),
        ),
      ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
