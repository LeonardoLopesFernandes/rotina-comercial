import 'package:flutter/material.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';

class ProductCard extends StatefulWidget {
  final Item item;
  final bool blocked;
  final void Function(Item) onEdit;
  final void Function(Item) onShowBadge;

  const ProductCard({
    super.key,
    required this.item,
    required this.blocked,
    required this.onEdit,
    required this.onShowBadge,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int? _activeStat;

  String _statusAsset() {
    if (widget.blocked) return 'assets/ic_block.png';
    if (widget.item.treated) return 'assets/ic_check.png';
    return 'assets/ic_lapis.png';
  }

  void _handleCardPress() {
    if (widget.blocked) return;
    if (widget.item.treated) {
      widget.onShowBadge(widget.item);
      return;
    }
    widget.onEdit(widget.item);
  }

  void _handleStatusPress() {
    if (widget.blocked) return;
    if (widget.item.treated) {
      widget.onShowBadge(widget.item);
    } else {
      widget.onEdit(widget.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    const stats = ['V.DIA', 'V.MÊS', 'ESTOQUE', 'GRADE'];
    final statsValues = [
      widget.item.saleQuantityDay.toString(),
      widget.item.saleQuantityMonth.toString(),
      widget.item.quantityStock.toString(),
      widget.item.grade,
    ];

    return GestureDetector(
      onTap: _handleCardPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Container(
              color: AppColors.metricsBg,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: List.generate(stats.length, (index) {
                  final active = _activeStat == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _activeStat = active ? null : index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: active ? AppColors.statActiveBg : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              stats[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? AppColors.statActiveText
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              statsValues[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? AppColors.statActiveText
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.item.ean} | ${widget.item.sap}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleStatusPress,
                    child: Image.asset(_statusAsset(), width: 20, height: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
