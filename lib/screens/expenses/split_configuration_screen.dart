import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart' as isar_models;
import '../../providers/db_provider.dart';
import '../../services/split_service.dart';
import '../../utils/monetary_math.dart';

class SplitConfigurationScreen extends ConsumerStatefulWidget {
  final String title;
  final double totalAmount;
  final String category;
  final String categoryIcon;
  final isar_models.Group group;
  final List<isar_models.Member> participants;
  final List<isar_models.Contribution> contributions;

  const SplitConfigurationScreen({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.categoryIcon,
    required this.group,
    required this.participants,
    required this.contributions,
  });

  @override
  ConsumerState<SplitConfigurationScreen> createState() =>
      _SplitConfigurationScreenState();
}

class _SplitConfigurationScreenState
    extends ConsumerState<SplitConfigurationScreen> {
  late String _splitMode;
  late List<isar_models.Split> _splits;
  final Map<int, TextEditingController> _controllers = {};
  final Set<int> _manualEdits = {};

  @override
  void initState() {
    super.initState();
    _splitMode = 'uniform';
    _recalculateSplits();
  }

  void _recalculateSplits() {
    if (_splitMode == 'uniform') {
      _splits = SplitService.calculateUniform(
        widget.totalAmount,
        widget.participants,
      );
      _manualEdits.clear();
    } else if (_splitMode == 'specific') {
      _splits = widget.participants.map((m) {
        return isar_models.Split()
          ..memberId = m.id
          ..memberName = m.name
          ..amount = 0.0;
      }).toList();
    } else if (_splitMode == 'ratio') {
      final ratio = 100.0 / widget.participants.length;
      Map<int, double> ratios = {
        for (var m in widget.participants) m.id: ratio,
      };
      _splits = SplitService.calculateFromRatios(
        widget.totalAmount,
        ratios,
        widget.participants,
      );
    }

    // Update controllers
    for (var s in _splits) {
      if (!_controllers.containsKey(s.memberId)) {
        _controllers[s.memberId!] = TextEditingController();
      }
      if (_splitMode == 'specific') {
        _controllers[s.memberId!]!.text = s.amount?.toStringAsFixed(0) ?? '0';
      } else if (_splitMode == 'ratio') {
        _controllers[s.memberId!]!.text = s.ratio?.toStringAsFixed(0) ?? '0';
      }
    }
  }

  void _onAmountChanged(int memberId, String val) {
    double? newAmount = double.tryParse(val);
    if (newAmount == null) return;

    setState(() {
      _manualEdits.add(memberId);
      final split = _splits.firstWhere((s) => s.memberId == memberId);
      split.amount = newAmount;

      _distributeRemaining();
    });
  }

  void _onRatioChanged(int memberId, String val) {
    double? newRatio = double.tryParse(val);
    if (newRatio == null) return;

    setState(() {
      _manualEdits.add(memberId);
      final split = _splits.firstWhere((s) => s.memberId == memberId);
      split.ratio = newRatio;

      _distributeRemainingRatios();
    });
  }

  void _distributeRemaining() {
    double manualTotal = 0;
    for (var id in _manualEdits) {
      manualTotal += _splits.firstWhere((s) => s.memberId == id).amount ?? 0;
    }

    double remaining = widget.totalAmount - manualTotal;
    var unedited = _splits
        .where((s) => !_manualEdits.contains(s.memberId))
        .toList();

    if (unedited.isNotEmpty) {
      double perPerson = remaining / unedited.length;
      for (var s in unedited) {
        s.amount = perPerson > 0 ? perPerson : 0;
        _controllers[s.memberId!]?.text = s.amount!.toStringAsFixed(0);
      }
    }
  }

  void _distributeRemainingRatios() {
    double manualTotal = 0;
    for (var id in _manualEdits) {
      manualTotal += _splits.firstWhere((s) => s.memberId == id).ratio ?? 0;
    }

    double remaining = 100.0 - manualTotal;
    var unedited = _splits
        .where((s) => !_manualEdits.contains(s.memberId))
        .toList();

    if (unedited.isNotEmpty) {
      double perPerson = remaining / unedited.length;
      for (var s in unedited) {
        s.ratio = perPerson > 0 ? perPerson : 0;
        _controllers[s.memberId!]?.text = s.ratio!.toStringAsFixed(0);
      }
    }
    _recalculateFromRatioInputs();
  }

  void _applyQuickPercentage(int memberId, double percentage) {
    if (_splitMode == 'specific') {
      double amount = widget.totalAmount * (percentage / 100);
      _controllers[memberId]?.text = amount.toStringAsFixed(0);
      _onAmountChanged(memberId, amount.toString());
    } else {
      _controllers[memberId]?.text = percentage.toStringAsFixed(0);
      _onRatioChanged(memberId, percentage.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSecondary =
        theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    double allocated = _splits.fold(0, (sum, s) => sum + (s.amount ?? 0));
    double remaining = MonetaryMath.round(widget.totalAmount - allocated);
    bool isValid = (remaining.abs() < 0.01);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Split Configuration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  Text(
                    '₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Split Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildMethodTile(
              'Equally',
              'Split the total amount evenly',
              Icons.groups_rounded,
              _splitMode == 'uniform',
              'uniform',
            ),
            _buildMethodTile(
              'Exactly',
              'Set specific amounts for each',
              Icons.edit_note_rounded,
              _splitMode == 'specific',
              'specific',
            ),
            _buildMethodTile(
              'By Ratio',
              'Split based on percentages',
              Icons.percent_rounded,
              _splitMode == 'ratio',
              'ratio',
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Allocation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${widget.participants.length} Selected',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildAllocationList(theme),
            const SizedBox(height: 24),
            _buildStatusBox(allocated, remaining, isValid),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isValid ? _saveExpense : null,
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    String mode,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _splitMode = mode;
          _recalculateSplits();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : AppColors.getBorder(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllocationList(ThemeData theme) {
    return _splits.map<Widget>((isar_models.Split s) {
      bool isEdited = _manualEdits.contains(s.memberId);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEdited
                ? theme.colorScheme.primary.withOpacity(0.5)
                : AppColors.getBorder(context),
            width: isEdited ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    s.memberName?[0] ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.memberName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_splitMode == 'uniform')
                        const Text(
                          'Equal share',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        )
                      else if (isEdited)
                        Text(
                          'Manually set',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          'Auto-calculated',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_splitMode == 'uniform')
                  Text(
                    '₹${s.amount?.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                else if (_splitMode == 'specific')
                  _buildSmallInput(
                    s.memberId!,
                    '₹',
                    (val) => _onAmountChanged(s.memberId!, val),
                  )
                else if (_splitMode == 'ratio')
                  _buildSmallInput(
                    s.memberId!,
                    '%',
                    (val) => _onRatioChanged(s.memberId!, val),
                  ),
              ],
            ),
            if (_splitMode != 'uniform') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _QuickPercentBtn(
                    label: '25%',
                    onTap: () => _applyQuickPercentage(s.memberId!, 25),
                  ),
                  const SizedBox(width: 8),
                  _QuickPercentBtn(
                    label: '50%',
                    onTap: () => _applyQuickPercentage(s.memberId!, 50),
                  ),
                  const SizedBox(width: 8),
                  _QuickPercentBtn(
                    label: '100%',
                    onTap: () => _applyQuickPercentage(s.memberId!, 100),
                  ),
                  const SizedBox(width: 8),
                  _QuickPercentBtn(
                    label: 'Reset',
                    onTap: () {
                      setState(() {
                        _manualEdits.remove(s.memberId);
                        if (_splitMode == 'specific')
                          _distributeRemaining();
                        else
                          _distributeRemainingRatios();
                      });
                    },
                    isReset: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  void _recalculateFromRatioInputs() {
    double totalRatio = _splits.fold(0, (sum, s) => sum + (s.ratio ?? 0));
    if (totalRatio == 0) return;

    double allocatedAmount = 0;
    for (int i = 0; i < _splits.length; i++) {
      final s = _splits[i];
      if (i == _splits.length - 1) {
        s.amount = MonetaryMath.round(widget.totalAmount - allocatedAmount);
      } else {
        s.amount = MonetaryMath.round(
          (s.ratio! / totalRatio) * widget.totalAmount,
        );
      }
      allocatedAmount = MonetaryMath.round(allocatedAmount + s.amount!);
    }
  }

  Widget _buildSmallInput(
    int memberId,
    String suffix,
    Function(String) onChanged,
  ) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: _controllers[memberId],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.end,
        decoration: InputDecoration(
          suffixText: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusBox(double allocated, double remaining, bool isValid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isValid ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  isValid ? 'Fully Allocated' : 'Allocation Mismatch',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isValid ? AppColors.success : AppColors.error,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${allocated.toStringAsFixed(0)} / ₹${widget.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isValid ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 8),
            Text(
              remaining > 0
                  ? 'Remaining: ₹${remaining.toStringAsFixed(2)}'
                  : 'Over-allocated: ₹${remaining.abs().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
    final db = ref.read(dbServiceProvider).isar;

    final expense = isar_models.Expense()
      ..title = widget.title
      ..totalAmount = widget.totalAmount
      ..category = widget.category
      ..categoryIcon = widget.categoryIcon
      ..date = DateTime.now()
      ..splitMode = _splitMode
      ..splits = _splits
      ..contributions = widget.contributions;

    expense.group.value = widget.group;

    await db.writeTxn(() async {
      await db.collection<isar_models.Expense>().put(expense);
      await expense.group.save();
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense saved!')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _QuickPercentBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isReset;

  const _QuickPercentBtn({
    required this.label,
    required this.onTap,
    this.isReset = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isReset
              ? theme.colorScheme.error.withValues(alpha: 0.1)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isReset
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
