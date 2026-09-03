import 'package:flutter/material.dart';
import 'package:rotina_comercial/hooks/departments_controller.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/utils/time.dart';

class CalendarDialog extends StatelessWidget {
  final bool visible;
  final DepartmentsController controller;
  final VoidCallback onClose;

  const CalendarDialog({
    super.key,
    required this.visible,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    const weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    final now = DateTime.now();
    final selected = controller.selectedDate;
    final monthName = months[selected.month - 1];
    final year = selected.year;

    final first = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final leading = first.weekday % 7;

    final cells = <DateTime?>[];
    for (var i = 0; i < leading; i++) cells.add(null);
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(selected.year, selected.month, d));
    }
    while (cells.length % 7 != 0) cells.add(null);

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
              constraints: const BoxConstraints(maxWidth: 360),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x38000000), blurRadius: 15, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC))),
                    ),
                    child: Center(
                      child: Text('$monthName $year',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF050505))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: weekDays.map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
                        ),
                      )).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFCCCCCC)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1,
                      children: cells.map((day) {
                        if (day == null) return const SizedBox.shrink();
                        final isToday = sameDay(day, now);
                        final isSel = sameDay(day, selected);
                        final weekday = day.weekday;
                        final isWeekday = weekday >= DateTime.monday && weekday <= DateTime.friday;
                        final enabled = isWeekday;

                        return Center(
                          child: GestureDetector(
                            onTap: enabled ? () {
                              controller.selectedDate = day;
                              controller.loadDataForDate(day);
                              onClose();
                            } : null,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: isSel
                                  ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                                  : (isToday
                                      ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2))
                                      : null),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
                                    color: isSel
                                        ? Colors.white
                                        : (enabled
                                            ? (isToday ? AppColors.primary : const Color(0xFF050505))
                                            : const Color(0xFFC9C9C9)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFCCCCCC)),
                  GestureDetector(
                    onTap: () {
                      final today = clampToWeekday(DateTime.now());
                      controller.selectedDate = today;
                      controller.loadDataForDate(today);
                      onClose();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Center(
                        child: Text('Ir para hoje',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15)),
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
}
