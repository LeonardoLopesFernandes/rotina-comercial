import 'package:flutter/material.dart';
import 'package:rotina_comercial/hooks/departments_controller.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/utils/time.dart';

class CalendarDialog extends StatefulWidget {
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
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late DateTime _weekStart;

  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  static const _weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOfWeek(widget.controller.selectedDate);
  }

  @override
  void didUpdateWidget(covariant CalendarDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _weekStart = _mondayOfWeek(widget.controller.selectedDate);
    }
  }

  DateTime _mondayOfWeek(DateTime date) {
    var d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  String _weekLabel() {
    final start = _weekStart;
    final end = _weekStart.add(const Duration(days: 4));
    if (start.month == end.month) {
      return '${_months[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) {
      return '${_months[start.month - 1]} - ${_months[end.month - 1]} ${start.year}';
    }
    return '${_months[start.month - 1]} ${start.year} - ${_months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final now = DateTime.now();
    final selected = widget.controller.selectedDate;
    final weekDays = List.generate(5, (i) => _weekStart.add(Duration(days: i)));

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC))),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
                          onPressed: _prevWeek,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(_weekLabel(),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF050505))),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.primary, size: 28),
                          onPressed: _nextWeek,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: _weekDays.map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
                        ),
                      )).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFCCCCCC)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: weekDays.map((day) {
                        final isToday = sameDay(day, now);
                        final isSel = sameDay(day, selected);
                        return Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                widget.controller.selectedDate = day;
                                widget.controller.loadDataForDate(day);
                                widget.onClose();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: isSel
                                    ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                                    : (isToday
                                        ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2))
                                        : null),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
                                      color: isSel
                                          ? Colors.white
                                          : (isToday ? AppColors.primary : const Color(0xFF050505)),
                                    ),
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
                      widget.controller.selectedDate = today;
                      widget.controller.loadDataForDate(today);
                      widget.onClose();
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
