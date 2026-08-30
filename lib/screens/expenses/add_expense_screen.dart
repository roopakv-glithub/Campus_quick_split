import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/data_provider.dart';
import 'split_configuration_screen.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String selectedCategory = 'Food';
  String selectedCategoryIcon = '🍔';

  Group? selectedGroup;
  List<Member> selectedParticipants = [];
  List<Contribution> contributions = [];

  final List<Map<String, String>> categories = [
    {'name': 'Food', 'icon': '🍔'},
    {'name': 'Auto', 'icon': '🚕'},
    {'name': 'Print', 'icon': '🖨'},
    {'name': 'Shop', 'icon': '🛍'},
    {'name': 'College', 'icon': '🎓'},
    {'name': 'Other', 'icon': '📝'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateContributions);
  }

  void _updateContributions() {
    if (contributions.isNotEmpty && contributions.length == 1) {
      setState(() {
        contributions[0].amount =
            double.tryParse(_amountController.text) ?? 0.0;
      });
    }
  }

  void _addCustomCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  selectedCategory = controller.text;
                  selectedCategoryIcon = '✨';
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildAmountInput(theme),
            const SizedBox(height: 32),
            _buildInputSection(
              'What was this for?',
              'e.g. Pizza after class',
              Icons.notes_rounded,
              _titleController,
            ),
            const SizedBox(height: 24),
            _buildCategorySection(theme),
            const SizedBox(height: 24),
            _buildGroupSelector(groupsAsync, theme),
            if (selectedGroup != null) ...[
              const SizedBox(height: 24),
              _buildParticipantsSection(theme),
              const SizedBox(height: 24),
              _buildPaidBySection(theme),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _onContinue,
              child: const Text('Continue to Split'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixText: '₹',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Total Amount',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: hint),
        ),
      ],
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 85,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...categories.map((cat) {
                final isSelected = selectedCategory == cat['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selectedCategory = cat['name']!;
                      selectedCategoryIcon = cat['icon']!;
                    }),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : AppColors.getBorder(context),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat['icon']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: _addCustomCategory,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.getBorder(context),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Custom', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSelector(
    AsyncValue<List<Group>> groupsAsync,
    ThemeData theme,
  ) {
    return groupsAsync.when(
      data: (groups) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Group',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Group>(
            value: selectedGroup,
            isExpanded: true,
            dropdownColor: theme.cardTheme.color,
            items: groups
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(
                      g.name,
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (g) async {
              if (g != null) {
                final members = await g.members.filter().findAll();
                setState(() {
                  selectedGroup = g;
                  selectedParticipants = List.from(members);
                  _initializeDefaultContribution(members);
                });
              }
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.group_rounded),
            ),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error loading groups: $e'),
    );
  }

  void _initializeDefaultContribution(List<Member> members) {
    final currentUser = members.firstWhere(
      (m) => m.isCurrentUser,
      orElse: () => members.first,
    );
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    contributions = [
      Contribution()
        ..memberId = currentUser.id
        ..memberName = currentUser.name
        ..amount = amount,
    ];
  }

  Widget _buildParticipantsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Split with',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedParticipants = List.from(
                    selectedGroup!.members.toList(),
                  );
                });
              },
              child: const Text(
                'Select All',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: selectedGroup!.members.map((m) {
            final isSelected = selectedParticipants.any((p) => p.id == m.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedParticipants.removeWhere((p) => p.id == m.id);
                  } else {
                    selectedParticipants.add(m);
                  }
                });
              },
              child: _UserChip(name: m.name, isSelected: isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaidBySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paid by',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Why "Paid By"?'),
                    content: const Text(
                      'This identifies who initially spent the money. The app uses this to calculate who is owed money by other participants.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            TextButton(
              onPressed: _showMultiplePayersDialog,
              child: const Text(
                'Multiple Payers?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...contributions.map((c) {
          if ((c.amount ?? 0) <= 0) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    c.memberName?[0] ?? '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.memberName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Paid ₹${c.amount?.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showMultiplePayersDialog() {
    if (selectedGroup == null) return;

    final members = selectedGroup!.members.toList();
    final Map<int, TextEditingController> dialogControllers = {
      for (var m in members)
        m.id: TextEditingController(
          text:
              contributions
                  .firstWhere(
                    (c) => c.memberId == m.id,
                    orElse: () => Contribution()..amount = 0,
                  )
                  .amount
                  ?.toStringAsFixed(0) ??
              '0',
        ),
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double dialogTotal = dialogControllers.values.fold(
              0,
              (sum, controller) =>
                  sum + (double.tryParse(controller.text) ?? 0),
            );
            double expectedTotal = double.tryParse(_amountController.text) ?? 0;
            bool isMatched = (dialogTotal - expectedTotal).abs() < 0.01;

            return AlertDialog(
              title: const Text('Multiple Payers'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(m.name)),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: dialogControllers[m.id],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                prefixText: '₹',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Paid:'),
                          Text(
                            '₹${dialogTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMatched
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: isMatched
                              ? () {
                                  setState(() {
                                    contributions = dialogControllers.entries
                                        .map((e) {
                                          final m = members.firstWhere(
                                            (m) => m.id == e.key,
                                          );
                                          return Contribution()
                                            ..memberId = m.id
                                            ..memberName = m.name
                                            ..amount =
                                                double.tryParse(e.value.text) ??
                                                0;
                                        })
                                        .where((c) => (c.amount ?? 0) > 0)
                                        .toList();
                                  });
                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onContinue() {
    double total = double.tryParse(_amountController.text) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (selectedGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }
    if (selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select participants')),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SplitConfigurationScreen(
              title: _titleController.text,
              totalAmount: total,
              category: selectedCategory,
              categoryIcon: selectedCategoryIcon,
              group: selectedGroup!,
              participants: selectedParticipants,
              contributions: contributions,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String name;
  final bool isSelected;

  const _UserChip({required this.name, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : AppColors.getBorder(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: isSelected
                ? Colors.white
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
