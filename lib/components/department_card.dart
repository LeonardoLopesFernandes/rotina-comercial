import 'package:flutter/material.dart';
import 'package:rotina_comercial/components/product_card.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';

class DepartmentCard extends StatelessWidget {
  final Department department;
  final bool blocked;
  final void Function(Department) onViewAll;
  final void Function(Item) onEditItem;
  final void Function(Item) onShowBadge;

  const DepartmentCard({
    super.key,
    required this.department,
    required this.blocked,
    required this.onViewAll,
    required this.onEditItem,
    required this.onShowBadge,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = department.items
        .map((e) => e.copyWith(departmentCode: department.department.code))
        .toList();
    final total = allItems.length;
    final treatedCount = allItems.where((i) => i.treated).length;
    final allTreated = total > 0 && treatedCount == total;

    String? statusIcon;
    if (blocked) {
      statusIcon = 'assets/ic_block.png';
    } else if (allTreated) {
      statusIcon = 'assets/ic_check.png';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${department.department.code} - ${department.department.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (statusIcon != null)
                      Image.asset(statusIcon, width: 20, height: 20),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => onViewAll(department),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'VER TUDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: allItems
                .map((item) => ProductCard(
                      key: ValueKey('${item.id}-${item.ean}'),
                      item: item,
                      blocked: blocked,
                      onEdit: onEditItem,
                      onShowBadge: onShowBadge,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
