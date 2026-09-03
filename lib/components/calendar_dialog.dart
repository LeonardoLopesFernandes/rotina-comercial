import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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

    final weekRange = getWeekRange(now);
    final weekStart = weekRange.monday;
    final weekEnd = weekRange.friday;

    final cells = <String>[];
    for (var i = 0; i < leading; i++) {
      final prevDay = DateTime(selected.year, selected.month, 1 - i);
      cells.add('muted:${prevDay.day}');
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(selected.year, selected.month, d);
      final weekend = day.weekday == 6 || day.weekday == 7;
      final isToday = sameDay(day, now);
      final isSel = sameDay(day, selected);
      final inWeek = !day.isBefore(weekStart) && !day.isAfter(weekEnd);
      final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
      final enabled = inWeek && !weekend && !isPast;

      if (isSel) {
        cells.add('selected:$d');
      } else if (!enabled) {
        cells.add('muted:$d');
      } else {
        cells.add('active:$d');
      }
    }
    final remaining = 7 - (cells.length % 7);
    if (remaining < 7) {
      for (var i = 1; i <= remaining; i++) {
        cells.add('muted:$i');
      }
    }

    final gridHtml = cells.map((cell) {
      final parts = cell.split(':');
      final type = parts[0];
      final day = parts[1];
      if (type == 'selected') {
        return '<div class="day"><span class="selected">$day</span></div>';
      } else if (type == 'muted') {
        return '<div class="day muted">$day</div>';
      } else {
        return '<div class="day">$day</div>';
      }
    }).join('');

    final weekHeader = weekDays.map((d) => '<div>$d</div>').join();

    final html = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Arial,Helvetica,sans-serif;background:transparent;color:#050505}
.calendar{width:100%;background:#fff;border-radius:18px;overflow:hidden;display:flex;flex-direction:column}
.head{display:flex;align-items:center;justify-content:center;padding:18px 16px;border-bottom:1px solid #bbb;position:relative}
.month{font-size:20px;font-weight:600}
.back{position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:28px;font-weight:300;color:#111;cursor:pointer;padding:8px}
.week{display:grid;grid-template-columns:repeat(7,1fr);height:40px;align-items:center;border-bottom:1px solid #bbb;font-size:13px;font-weight:600;text-align:center;color:#888}
.grid{display:grid;grid-template-columns:repeat(7,1fr);padding:6px 10px 10px;gap:2px}
.day{display:flex;align-items:center;justify-content:center;height:40px;font-size:15px;font-weight:400}
.muted{color:#c9c9c9}
.selected{width:38px;height:38px;background:#ff1010;color:#fff;border-radius:10px;font-weight:700;display:flex;align-items:center;justify-content:center}
</style>
</head>
<body>
<section class="calendar">
  <header class="head">
    <div class="back">‹</div>
    <div class="month">$monthName $year</div>
  </header>
  <div class="week">$weekHeader</div>
  <div class="grid">$gridHtml</div>
</section>
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
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Html(data: html),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFBBBBBB))),
                      ),
                      child: const Center(
                        child: Text('Fechar',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
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
