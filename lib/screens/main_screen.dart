import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rotina_comercial/api/endpoints.dart';
import 'package:rotina_comercial/auth/auth_provider.dart';
import 'package:rotina_comercial/components/checklist_modal.dart';
import 'package:rotina_comercial/components/department_card.dart';
import 'package:rotina_comercial/components/success_toast.dart';
import 'package:rotina_comercial/components/treatment_badge_modal.dart';
import 'package:rotina_comercial/hooks/departments_controller.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';
import 'package:rotina_comercial/utils/time.dart';
import 'package:rotina_comercial/utils/toast.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late bool _blocked;
  final _queryController = TextEditingController();
  bool _showMenu = false;
  bool _showLogout = false;
  bool _showExit = false;
  bool _showDatePicker = false;
  late DateTime _calendarMonth;
  Item? _checklistItem;
  Item? _badgeItem;
  bool _showSuccessToast = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _blocked = isBlocked();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<DepartmentsController>();
    if (!_loaded) {
      _loaded = true;
      controller.loadData();
    }
    final success = controller.successMessage;
    if (success != null) {
      _showSuccessToast = true;
      controller.clearSuccessMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DepartmentsController>();

    return WillPopScope(
      onWillPop: () async {
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null && focus.hasFocus) {
          focus.unfocus();
          return false;
        }
        if (_showMenu) {
          setState(() => _showMenu = false);
          return false;
        }
        if (_showLogout) {
          setState(() => _showLogout = false);
          return false;
        }
        if (_showExit) return false;
        if (_showDatePicker) {
          setState(() => _showDatePicker = false);
          return false;
        }
        if (_checklistItem != null) {
          setState(() => _checklistItem = null);
          return false;
        }
        if (_badgeItem != null) {
          setState(() => _badgeItem = null);
          return false;
        }
        setState(() => _showExit = true);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                _toolbar(context, controller),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Column(
                      children: [
                        _mainCard(controller),
                        const SizedBox(height: 4),
                        Expanded(
                          child: _content(controller),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showMenu) _menuOverlay(context),
            if (_showExit) _exitDialog(),
            if (_showLogout) _logoutDialog(context),
            if (_showDatePicker)
              _datePickerSheet(context, controller),
            ChecklistModal(
              visible: _checklistItem != null,
              item: _checklistItem,
              onClose: () => setState(() => _checklistItem = null),
              onSave: (item, problems) {
                controller.markItemProblems(
                    item.id, problems, controller.selectedDate);
                setState(() => _checklistItem = null);
              },
            ),
            TreatmentBadgeModal(
              visible: _badgeItem != null,
              item: _badgeItem,
              userName: context.read<AuthProvider>().userName,
              onClose: () => setState(() => _badgeItem = null),
            ),
            if (_showSuccessToast)
              SuccessToast(
                onHide: () => setState(() => _showSuccessToast = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context, DepartmentsController controller) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top, left: 8, right: 8),
      child: SizedBox(
        height: 60,
        child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showMenu = true),
            child: Image.asset('assets/home.png', width: 24, height: 24),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo_rotina.png', width: 20, height: 20),
                const SizedBox(width: 6),
                const Text('Rotina Comercial',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showLogout = true),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Image.asset('assets/ic_user.png', width: 24, height: 24),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _mainCard(DepartmentsController controller) {
    final dayOfWeek = getDayOfWeekPt(controller.selectedDate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
                  _showDatePicker = true;
                  _calendarMonth =
                      DateTime(controller.selectedDate.year, controller.selectedDate.month, 1);
                }),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dia da Semana:',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                      Text(dayOfWeek,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                Image.asset('assets/agenda.png', width: 100, height: 40),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
                  _showDatePicker = true;
                  _calendarMonth =
                      DateTime(controller.selectedDate.year, controller.selectedDate.month, 1);
                }),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data:',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                      Text(formatDisplayDate(controller.selectedDate),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    showToast('Gerando PDF...');
                    final result = await downloadDaySchedulePdf(
                        formatApiDate(controller.selectedDate));
                    showToast(result.message, true);
                  },
                  child: Image.asset('assets/imprimir.png', width: 100, height: 40),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: AppColors.divider),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar por departamento',
                            hintStyle: TextStyle(color: AppColors.textHint),
                            border: InputBorder.none,
                          ),
                          onChanged: (text) => controller.searchDepartment(text),
                        ),
                      ),
                      Image.asset('assets/loopa.png', width: 20, height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(DepartmentsController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (controller.error != null) {
      return Center(
        child: Text(controller.error!,
            style: const TextStyle(color: AppColors.danger, fontSize: 14),
            textAlign: TextAlign.center),
      );
    }
    if (controller.departments.isEmpty) {
      return const Center(
        child: Text('📭 Nenhum item encontrado para esta data',
            style: TextStyle(color: AppColors.textHint, fontSize: 14),
            textAlign: TextAlign.center),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => controller.refresh(),
      child: ListView.builder(
        itemCount: controller.departments.length,
        itemBuilder: (context, index) {
          final dept = controller.departments[index];
          return DepartmentCard(
            department: dept,
            blocked: _blocked,
            onViewAll: (d) {
              Navigator.of(context).pushNamed(
                'DepartmentDetail',
                arguments: {
                  'deptCode': d.department.code,
                  'deptName': d.department.name,
                  'selectedDate': controller.selectedDate.millisecondsSinceEpoch,
                  'items': d.items,
                },
              );
            },
            onEditItem: (item) => setState(() => _checklistItem = item),
            onShowBadge: (item) => setState(() => _badgeItem = item),
          );
        },
      ),
    );
  }

  Widget _menuOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showMenu = false),
      child: Container(
        color: const Color(0x33000000),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 56, left: 8),
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _menuItem('Painel de indicadores', () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).pushNamed('Dashboard');
                }),
                _menuItem('Rotina do dia', () => setState(() => _showMenu = false)),
                _menuItem('Itens sem venda', () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).pushNamed('SpecialItems',
                      arguments: {'itemType': 'unsold'});
                }),
                _menuItem('Itens sem histórico de venda', () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).pushNamed('SpecialItems',
                      arguments: {'itemType': 'no_sales_history'});
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Text(label,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _exitDialog() {
    return _centerDialog(
      'Sair do app',
      'Deseja realmente sair do aplicativo?',
      'Cancelar',
      'Sair',
      () => setState(() => _showExit = false),
      () {
        setState(() => _showExit = false);
        SystemNavigator.pop();
      },
    );
  }

  Widget _logoutDialog(BuildContext context) {
    return _centerDialog(
      'Sair da conta',
      'Deseja realmente sair da sua conta?',
      'Cancelar',
      'Sair',
      () => setState(() => _showLogout = false),
      () async {
        setState(() => _showLogout = false);
        showToast('👋 Deslogado com sucesso!');
        await context.read<AuthProvider>().logout();
      },
    );
  }

  Widget _centerDialog(String title, String message, String cancelLabel,
      String confirmLabel, VoidCallback onCancel, VoidCallback onConfirm) {
    return Container(
      color: const Color(0x66000000),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(cancelLabel,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePickerSheet(BuildContext context, DepartmentsController controller) {
    const weekShort = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final first = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = <DateTime?>[];
    for (var i = 0; i < leading; i++) cells.add(null);
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_calendarMonth.year, _calendarMonth.month, d));
    }
    while (cells.length % 7 != 0) cells.add(null);

    return Container(
      color: const Color(0x66000000),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                    onPressed: () => setState(() {
                      _calendarMonth = DateTime(
                          _calendarMonth.year, _calendarMonth.month - 1, 1);
                    }),
                  ),
                  Text('${months[_calendarMonth.month - 1]} ${_calendarMonth.year}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                    onPressed: () => setState(() {
                      _calendarMonth = DateTime(
                          _calendarMonth.year, _calendarMonth.month + 1, 1);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: weekShort
                    .map((w) => Expanded(
                          child: Center(
                            child: Text(w,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1,
                children: cells.map((day) {
                  if (day == null) return const SizedBox.shrink();
                  final weekend = day.weekday == 6 || day.weekday == 7;
                  final selected = sameDay(day, controller.selectedDate);
                  final isToday = sameDay(day, DateTime.now());
                  return GestureDetector(
                    onTap: weekend && !selected
                        ? null
                        : () {
                            controller.selectedDate = day;
                            setState(() => _showDatePicker = false);
                            controller.loadDataForDate(day);
                          },
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: selected
                            ? const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle)
                            : (isToday
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary),
                                  )
                                : null),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : (weekend
                                      ? AppColors.textHint
                                      : (isToday
                                          ? AppColors.primary
                                          : AppColors.textPrimary)),
                              fontWeight: selected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _showDatePicker = false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Center(
                    child: Text('Fechar',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
