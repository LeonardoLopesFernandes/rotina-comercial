import 'package:flutter/material.dart';
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
                maxWidth: 340,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tratamento',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 12),
                  _row('Tratado por:', treatedBy),
                  _row('Data/hora:', treatedAt),
                  const Text('Respostas:',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Flexible(
                    child: SingleChildScrollView(
                      child: answers != null
                          ? Column(
                              children: shortQuestions.asMap().entries.map((e) {
                                final answer = answers.firstWhere(
                                    (a) => a.number == e.key + 1,
                                    orElse: () => TreatedAnswer(
                                        question: '',
                                        number: e.key + 1,
                                        items: 0,
                                        percentage: 0));
                                final active = isTreatedAnswerActive(answer);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        active ? '✓' : '×',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: active
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFD32F2F),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${e.key + 1} - ${shortQuestions[e.key]}',
                                          style: const TextStyle(
                                            fontSize: 12, color: Color(0xFF333333)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          : const Text('Detalhes indisponíveis',
                              style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Center(
                        child: Text('Fechar',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
