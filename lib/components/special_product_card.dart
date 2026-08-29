import 'package:flutter/material.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';

class SpecialProductCard extends StatelessWidget {
  final SpecialItem item;
  final bool blocked;
  final void Function(SpecialItem) onUntreatedClick;
  final void Function(SpecialItem) onTreatedClick;

  const SpecialProductCard({
    super.key,
    required this.item,
    required this.blocked,
    required this.onUntreatedClick,
    required this.onTreatedClick,
  });

  @override
  Widget build(BuildContext context) {
    final treated = item.isTreated;

    final extraParts = ['Estoque: ${item.stockQuantity}'];
    if (item.daysWithoutSelling != null) {
      extraParts.add('Sem venda há ${item.daysWithoutSelling} dias');
    }

    return GestureDetector(
      onTap: () {
        if (blocked) return;
        if (treated) {
          onTreatedClick(item);
        } else {
          onUntreatedClick(item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.ean} | ${item.sap}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    extraParts.join(' | '),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: treated
                  ? const Text(
                      '✓ Tratado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.end,
                    )
                  : blocked
                      ? Image.asset('assets/ic_block.png', width: 20, height: 20)
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
