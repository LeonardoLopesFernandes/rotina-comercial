import 'package:flutter/material.dart';
import 'package:rotina_comercial/api/endpoints.dart';
import 'package:rotina_comercial/components/special_answers_modal.dart';
import 'package:rotina_comercial/components/special_product_card.dart';
import 'package:rotina_comercial/storage/session.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';
import 'package:rotina_comercial/utils/time.dart';
import 'package:rotina_comercial/utils/toast.dart';

class SpecialItemsScreen extends StatefulWidget {
  const SpecialItemsScreen({super.key});

  @override
  State<SpecialItemsScreen> createState() => _SpecialItemsScreenState();
}

class _SpecialItemsScreenState extends State<SpecialItemsScreen> {
  List<DepartmentGroup> _groups = [];
  bool _refreshing = false;
  late bool _blocked;
  bool _showMenu = false;
  final Map<String, List<SpecialAnswer>> _answersCache = {};
  SpecialItem? _answerItem;
  List<SpecialAnswer> _answerList = [];
  SpecialItem? _badgeItem;
  String _badgeUserName = '';

  String _itemType = 'unsold';

  @override
  void initState() {
    super.initState();
    _blocked = isBlocked();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _itemType != args['itemType']) {
      _itemType = args['itemType'] as String;
      _groups = [];
      _loadItems();
    } else if (_groups.isEmpty) {
      _loadItems();
    }
    Session.getUserName().then((name) => setState(() => _badgeUserName = name));
  }

  Future<void> _loadItems() async {
    setState(() => _refreshing = true);
    try {
      final items = _itemType == 'unsold'
          ? await getUnsoldItems()
          : await getNoSalesHistoryItems();
      final map = <String, DepartmentGroup>{};
      for (final item in items) {
        final key = '${item.department.code}::${item.department.name}';
        map.putIfAbsent(
            key,
            () => DepartmentGroup(
                department: item.department, items: [])).items.add(item);
      }
      setState(() => _groups = map.values.toList());
    } catch (e) {
      showToast('Erro ao carregar itens: $e', true);
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _showAnswersDialog(SpecialItem item) async {
    final deptCode = item.department.code;
    if (!_answersCache.containsKey(deptCode)) {
      try {
        final answers = _itemType == 'unsold'
            ? await getUnsoldItemAnswers(deptCode)
            : await getNoSalesHistoryItemAnswers(deptCode);
        _answersCache[deptCode] = answers;
      } catch (_) {
        _answersCache[deptCode] = [];
      }
    }
    setState(() {
      _answerList = _answersCache[deptCode] ?? [];
      _answerItem = item;
    });
  }

  Future<void> _saveAnswer(SpecialItem item, String question, bool answer) async {
    try {
      final request = SpecialAnswerRequest(
        store: store,
        ean: item.ean,
        question: question,
        answer: answer,
      );
      if (_itemType == 'unsold') {
        await saveUnsoldItemAnswer(request);
      } else {
        await saveNoSalesHistoryItemAnswer(request);
      }
      showToast('Resposta registrada!');
      await _loadItems();
    } catch (e) {
      showToast('Erro ao salvar: $e', true);
    }
  }

  void _handleMenuOption(String target) {
    setState(() => _showMenu = false);
    if (target == _itemType) return;
    Navigator.of(context).pushReplacementNamed('SpecialItems',
        arguments: {'itemType': target});
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _itemType == 'unsold' ? 'Itens sem venda' : 'Itens sem histórico de venda';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _toolbar(title),
              if (_blocked)
                Container(
                  color: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  child: Text('🔒 ${getBlockedMessage()}',  // ignore: use_full_hex_values_for_flutter_colors
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final total = group.items.length;
                      final treatedCount =
                          group.items.where((i) => i.isTreated).length;
                      final allTreated = total > 0 && treatedCount == total;
                      String? statusIcon;
                      if (_blocked) {
                        statusIcon = 'assets/ic_block.png';
                      } else if (allTreated) {
                        statusIcon = 'assets/ic_check.png';
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${group.department.code} - ${group.department.name}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (statusIcon != null)
                                      Image.asset(statusIcon, width: 20, height: 20),
                                  ],
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text('$total',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          ...group.items.map((special) => SpecialProductCard(
                                key: ValueKey('${special.id}-${special.ean}'),
                                item: special,
                                blocked: _blocked,
                                onUntreatedClick: _showAnswersDialog,
                                onTreatedClick: (i) =>
                                    setState(() => _badgeItem = i),
                              )),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SpecialAnswersModal(
            visible: _answerItem != null,
            item: _answerItem,
            answers: _answerList,
            onClose: () => setState(() => _answerItem = null),
            onSave: _saveAnswer,
          ),
          if (_badgeItem != null)
            Stack(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _badgeItem = null),
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
                          _badgeRow('Tratado por:',
                              _badgeItem!.treatedBy ?? _badgeUserName),
                          _badgeRow('Data/hora:',
                              formatBadgeDate(_badgeItem!.treatedDate)),
                          const Text('Respostas:',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                          Flexible(
                            child: SingleChildScrollView(
                              child: _badgeItem!.question != null
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('✓',
                                            style: TextStyle(
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_badgeItem!.question!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF333333))),
                                        ),
                                      ],
                                    )
                                  : const Text('Detalhes indisponíveis',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textHint)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => setState(() => _badgeItem = null),
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_showMenu) _menuOverlay(context),
        ],
      ),
    );
  }

  Widget _toolbar(String title) {
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
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () => setState(() => _showMenu = true),
              child: Image.asset('assets/home.png', width: 24, height: 24),
          ),
        ],
      ),
      ),
    );
  }

  Widget _menuOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showMenu = false),
      child: Container(
        color: const Color(0x33000000),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.only(top: 52, right: 8),
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
                _menuItem('Rotina do dia', () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      'Main', (route) => false);
                }),
                _menuItem('Itens sem venda', () => _handleMenuOption('unsold')),
                _menuItem('Itens sem histórico de venda',
                    () => _handleMenuOption('no_sales_history')),
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

  Widget _badgeRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
