import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';

class ProfileDialog extends StatelessWidget {
  final bool visible;
  final String userName;
  final String email;
  final String store;
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const ProfileDialog({
    super.key,
    required this.visible,
    required this.userName,
    required this.email,
    required this.store,
    required this.onClose,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final displayName = userName.isNotEmpty ? userName : 'Usuário';
    final displayEmail = email.isNotEmpty ? email : '—';
    final displayStore = store.isNotEmpty ? store : '—';

    final html = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Arial,Helvetica,sans-serif;background:transparent;color:#666;text-align:center}
.name{font-size:24px;line-height:1.17;font-weight:500;color:#686868;margin:0 0 16px}
.email{font-size:15px;line-height:1.2;color:#777;margin-bottom:28px;white-space:nowrap}
.store{font-size:18px;font-weight:700;color:#666;margin-bottom:0}
</style>
</head>
<body>
  <h1 class="name">$displayName</h1>
  <div class="email">$displayEmail</div>
  <div class="store">Loja $displayStore</div>
</body>
</html>
''';

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: const Color(0x66000000)),
        ),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x52000000),
                    blurRadius: 22,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(36, 40, 36, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Html(data: html),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: onLogout,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0037),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x47000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('Sair',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('v1.1.1',
                        style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
