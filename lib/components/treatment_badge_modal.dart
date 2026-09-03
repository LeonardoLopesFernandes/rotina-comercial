import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';
import 'package:rotina_comercial/utils/time.dart';

class TreatmentBadgeModal extends StatelessWidget {
  final bool visible;
  final Item? item;
  final String userName;
  final VoidCallback onClose;

  const TreatmentBadgeModal({
    super.key,
    required this.visible,
    required this.item,
    required this.userName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || item == null) return const SizedBox.shrink();
    final it = item!;
    final treatedAt = formatBadgeDate(it.treatedAt);
    final treatedBy = it.treatedBy ?? userName;
    final answers = it.answers;

    final rowsHtml = answers != null
        ? shortQuestions.asMap().entries.map((e) {
            final answer = answers.firstWhere(
                (a) => a.number == e.key + 1,
                orElse: () => TreatedAnswer(
                    question: '', number: e.key + 1, items: 0, percentage: 0));
            final active = isTreatedAnswerActive(answer);
            final isNeutral = !active && (answer.items == 0 && answer.percentage == 0);
            final icon = isNeutral ? '⊘' : (active ? '✓' : '×');
            final cls = isNeutral ? 'neutral' : (active ? 'ok' : 'no');
            return '<div class="row"><span class="icon $cls">$icon</span><span>${e.key + 1} - ${shortQuestions[e.key]}</span></div>';
          }).join()
        : '<div class="row"><span class="text-muted">Detalhes indisponíveis</span></div>';

    final html = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Arial,Helvetica,sans-serif;background:transparent;color:#090909}
.label{font-size:16px;font-weight:700;line-height:1.25;margin:0 0 2px}
.value{font-size:15px;line-height:1.3;margin:0 0 15px}
.responses{margin-top:4px}
.row{display:flex;align-items:flex-start;gap:10px;margin:6px 0;font-size:14px;line-height:1.38}
.icon{flex:0 0 24px;font-size:18px;font-weight:700;line-height:1.1;text-align:center}
.ok{color:#43b75f}.no{color:#e6294f}.neutral{color:#b8b8b8}
.text-muted{color:#888}
</style>
</head>
<body>
  <p class="label">Tratado por:</p>
  <p class="value">$treatedBy</p>
  <p class="label">Data/hora:</p>
  <p class="value">$treatedAt</p>
  <p class="label">Respostas:</p>
  <div class="responses">$rowsHtml</div>
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
              constraints: BoxConstraints(
                maxWidth: 380,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E9),
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HtmlWidget(html),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Fechar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                      ),
                    ),
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
