import 'package:flutter/material.dart';
import 'package:rotina_comercial/theme.dart';
import 'package:rotina_comercial/types.dart';
import 'package:rotina_comercial/utils/time.dart';
import 'package:rotina_comercial/utils/toast.dart';

class SpecialAnswersModal extends StatefulWidget {
  final bool visible;
  final SpecialItem? item;
  final List<SpecialAnswer> answers;
  final VoidCallback onClose;
  final void Function(SpecialItem, String, bool) onSave;

  const SpecialAnswersModal({
    super.key,
    required this.visible,
    required this.item,
    required this.answers,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<SpecialAnswersModal> createState() => _SpecialAnswersModalState();
}

class _SpecialAnswersModalState extends State<SpecialAnswersModal> {
  int? _selectedNumber;
  bool _showConfirmation = false;

  @override
  void didUpdateWidget(covariant SpecialAnswersModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _selectedNumber = null;
      _showConfirmation = false;
    }
  }

  List<SpecialAnswer> get _activeAnswers =>
      widget.answers.where((a) => a.active).toList()
        ..sort((a, b) => a.number.compareTo(b.number));

  bool get _blocked => isBlocked();
  bool get _treated =>
      widget.item?.treatedBy?.isNotEmpty ?? false;

  void _toggleOption(int number) {
    if (_blocked || _treated) return;
    setState(() {
      _selectedNumber = _selectedNumber == number ? null : number;
    });
  }

  void _handleFinalize() {
    if (_treated) {
      showToast('Este item já foi respondido!');
      widget.onClose();
      return;
    }
    setState(() => _showConfirmation = true);
  }

  void _handleConfirm() {
    if (_selectedNumber == null) return;
    final active = _activeAnswers.firstWhere((a) => a.number == _selectedNumber);
    widget.onSave(widget.item!, active.question, true);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.item == null) {
      return const SizedBox.shrink();
    }
    final active = _activeAnswers;

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: const Color(0x80000000)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar problema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_blocked)
                    _stateBox('🔒 ${getBlockedMessage()}', AppColors.danger,
                        const Color(0xFFFEE2E2))
                  else if (_treated)
                    _stateBox('Item já respondido!', AppColors.success,
                        const Color(0xFFE8F5E9))
                  else
                    const Text('Selecione um problema:',
                        style: TextStyle(fontSize: 14, color: Color(0xFF6C757D))),
                  if (!_blocked && !_showConfirmation)
                    ...active.map((a) => _optionCard(
                          _selectedNumber == a.number,
                          '${a.number} - ${a.question}',
                          () => _toggleOption(a.number),
                        )),
                  if (!_blocked && _showConfirmation) _confirmation(),
                  if (!_blocked) _actions(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stateBox(String text, Color textColor, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _optionCard(bool isSelected, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEE2E2) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : null,
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFC0C0C0), width: 2),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Text('✓',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmation() {
    if (_selectedNumber == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Deseja confirmar que este item está OK?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Nenhum problema selecionado',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        ],
      );
    }
    final q = _activeAnswers
        .firstWhere((a) => a.number == _selectedNumber)
        .question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deseja registrar o problema selecionado?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$_selectedNumber - $q',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _actions() {
    if (_showConfirmation) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _button('Voltar', const Color(0xFFF1F3F4), AppColors.textPrimary, false,
              () => setState(() => _showConfirmation = false)),
          _button('Sim, confirmar', const Color(0xFFF3010B), Colors.white, false,
              _handleConfirm),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _button('Cancelar', const Color(0xFFF1F3F4), AppColors.textPrimary, false,
            widget.onClose),
        _button(
          _treated ? 'Item já respondido' : 'Finalizar',
          _treated ? const Color(0xFF9E9E9E) : const Color(0xFFF3010B),
          Colors.white,
          _treated,
          _treated ? null : _handleFinalize,
        ),
      ],
    );
  }

  Widget _button(String label, Color bg, Color fg, bool disabled,
      VoidCallback? onPressed) {
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(label,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
