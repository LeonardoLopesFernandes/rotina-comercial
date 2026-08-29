import 'package:flutter/material.dart';
import 'package:rotina_comercial/api/endpoints.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';
import 'package:rotina_comercial/utils/time.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  CardsPercentageResponse? _cards;
  String _unsoldValue = '';
  List<RoutineStatusItem> _routineStatus = [];
  List<ByAnswerItem> _treatedByAnswers = [];
  List<ByAnswerItem> _unsoldAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final today = formatStorageDate(DateTime.now());
    try {
      final results = await Future.wait([
        getCardsPercentage(today),
        getUnsoldTreatedCard(),
        getRoutineStatusList(),
        getTreatedByAnswers(today),
        getUnsoldTreatedAnswers(),
      ]);
      setState(() {
        _cards = results[0] as CardsPercentageResponse;
        final unsold = results[1] as UnsoldTreatedCardResponse;
        _unsoldValue =
            '${unsold.unsoldTreatedItemsQuantity} (${unsold.unsoldTreatedItemsPercentage}%)';
        _routineStatus = results[2] as List<RoutineStatusItem>;
        _treatedByAnswers = results[3] as List<ByAnswerItem>;
        _unsoldAnswers = results[4] as List<ByAnswerItem>;
      });
    } catch (e) {
      // dashboard silencioso
    } finally {
      setState(() => _loading = false);
    }
  }

  String _routineValue(RoutineStatusItem item) =>
      '${item.days} dias (${item.percentage}%)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _toolbar(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _card('Itens tratados',
                          _cards != null ? '${_cards!.treatedItemsQuantity} (${_cards!.treatedItemsPercentage}%)' : '—'),
                      _card('Departamentos tratados',
                          _cards != null ? '${_cards!.treatedDepartmentsQuantity} (${_cards!.treatedDepartmentsPercentage}%)' : '—'),
                      _card('Itens sem venda tratados', _unsoldValue.isNotEmpty ? _unsoldValue : '—'),
                      const Text('Rotina da semana',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _cardColumn(
                        _routineStatus.isEmpty
                            ? [const Text('Sem dados',
                                style: TextStyle(fontSize: 13, color: AppColors.textHint))]
                            : _routineStatus
                                .map((item) => _answerRow(
                                    item.status, _routineValue(item)))
                                .toList(),
                      ),
                      const Text('Tratamentos por resposta',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _cardColumn([
                        const Text('Hoje',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600)),
                        _answerList(_treatedByAnswers),
                      ]),
                      const SizedBox(height: 10),
                      _cardColumn([
                        const Text('Itens sem venda',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600)),
                        _answerList(_unsoldAnswers),
                      ]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
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
            const Expanded(
              child: Text('Painel de indicadores',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _answerRow(String question, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(question,
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _answerList(List<ByAnswerItem> items) {
    if (items.isEmpty) {
      return const Text('Sem respostas',
          style: TextStyle(fontSize: 13, color: AppColors.textHint));
    }
    return Column(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        return Column(
          children: [
            _answerRow(item.question, '${item.items} (${item.percentage}%)'),
            if (e.key < items.length - 1)
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
          ],
        );
      }).toList(),
    );
  }
}
