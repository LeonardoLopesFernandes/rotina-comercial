import 'package:flutter/material.dart';
import 'package:rotina_comercial/api/endpoints.dart';
import 'package:rotina_comercial/components/checklist_modal.dart';
import 'package:rotina_comercial/components/success_toast.dart';
import 'package:rotina_comercial/components/product_card.dart';
import 'package:rotina_comercial/components/treatment_badge_modal.dart';
import 'package:rotina_comercial/storage/session.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';
import 'package:rotina_comercial/utils/time.dart';
import 'package:rotina_comercial/utils/toast.dart';

class DepartmentDetailScreen extends StatefulWidget {
  const DepartmentDetailScreen({super.key});

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  late String _deptCode;
  late String _deptName;
  late DateTime _selectedDate;
  List<Item> _list = [];
  bool _loaded = false;
  Item? _checklistItem;
  Item? _badgeItem;
  bool _saving = false;
  bool _showSuccessToast = false;
  late bool _blocked;

  @override
  void initState() {
    super.initState();
    _blocked = isBlocked();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && !_loaded) {
      _deptCode = args['deptCode'] as String;
      _deptName = args['deptName'] as String;
      _selectedDate =
          DateTime.fromMillisecondsSinceEpoch(args['selectedDate'] as int);
      final items = (args['items'] as List<Item>)
          .map((e) => e.copyWith(departmentCode: _deptCode))
          .toList();
      _list = items;
      _loaded = true;
    }
  }

  Future<void> _saveItemProblems(Item item, List<int> problemNumbers) async {
    setState(() => _saving = true);
    try {
      final answers = questions
          .asMap()
          .entries
          .map((e) => {
                'question': e.value,
                'answer': problemNumbers.contains(e.key + 1),
              })
          .toList();
      final response = await saveTreatedItem(TreatedItemRequest(
        store: store,
        date: formatStorageDate(_selectedDate),
        ean: item.ean,
        answers: answers,
      ));
      if (!response.success) {
        showToast(response.message ?? 'Erro ao salvar', true);
        return;
      }
      final userName = await Session.getUserName();
      final nowStr = formatIso(DateTime.now());
      final selectedAnswers = problemNumbers
          .map((n) => TreatedAnswer(
                question: questions[n - 1],
                shortQuestion: shortQuestions[n - 1],
                answer: true,
                number: n,
                items: 1,
                percentage: 100.0,
              ))
          .toList();
      final updatedItem = item.copyWith(
        treated: true,
        treatedAt: nowStr,
        treatedBy: userName,
        answers: selectedAnswers,
      );
      setState(() {
        _list = _list
            .map((i) => i.id == item.id ? updatedItem : i)
            .toList();
      });
      await Session.saveTreatment(formatStorageDate(_selectedDate), item.ean,
          StoredTreatment(treated: true, treatedAt: nowStr, treatedBy: userName, answers: selectedAnswers));
      setState(() => _showSuccessToast = true);
    } catch (e) {
      showToast('Erro: $e', true);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked;
    final treatedCount = _list.where((i) => i.treated).length;
    final allTreated = _list.isNotEmpty && treatedCount == _list.length;

    String? statusIcon;
    if (blocked) {
      statusIcon = 'assets/ic_block.png';
    } else if (allTreated) {
      statusIcon = 'assets/ic_check.png';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _toolbar(statusIcon),
              Expanded(
                child: _saving
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _list.length,
                        itemBuilder: (context, index) {
                          final item = _list[index];
                          return ProductCard(
                            item: item,
                            blocked: blocked,
                            onEdit: (i) => setState(() => _checklistItem = i),
                            onShowBadge: (i) => setState(() => _badgeItem = i),
                          );
                        },
                      ),
              ),
            ],
          ),
          ChecklistModal(
            visible: _checklistItem != null,
            item: _checklistItem,
            onClose: () => setState(() => _checklistItem = null),
            onSave: (item, problems) {
              _saveItemProblems(item, problems);
              setState(() => _checklistItem = null);
            },
          ),
          TreatmentBadgeModal(
            visible: _badgeItem != null,
            item: _badgeItem,
            userName: '',
            onClose: () => setState(() => _badgeItem = null),
          ),
          if (_showSuccessToast)
            SuccessToast(
              onHide: () => setState(() => _showSuccessToast = false),
            ),
        ],
      ),
    );
  }

  Widget _toolbar(String? statusIcon) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top, left: 8, right: 8),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Text('‹', style: TextStyle(fontSize: 32, color: AppColors.textPrimary)),
                ),
              ),
            ),
            Expanded(
              child: Text('$_deptCode - $_deptName',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (statusIcon != null)
              Image.asset(statusIcon, width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
