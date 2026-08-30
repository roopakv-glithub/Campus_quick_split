import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/db_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = '👥';
  final List<Member> _allMembers = [];
  final List<Member> _selectedMembers = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = ref.read(dbServiceProvider).isar;
    final members = await db.collection<Member>().where().findAll();
    setState(() {
      _allMembers.addAll(members);
      // Auto select current user
      final currentUser = members.firstWhere((m) => m.isCurrentUser);
      _selectedMembers.add(currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Group',
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
              child: GestureDetector(
                onTap: _showIconPicker,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _selectedIcon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Group Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. Daily Auto'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Add Members',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._allMembers.map((m) {
                  final isSelected = _selectedMembers.any(
                    (sm) => sm.id == m.id,
                  );
                  return FilterChip(
                    label: Text(m.name),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedMembers.add(m);
                        } else {
                          // Allow removing any member except current user
                          if (!m.isCurrentUser) {
                            _selectedMembers.removeWhere((sm) => sm.id == m.id);
                          }
                        }
                      });
                    },
                  );
                }),
                ActionChip(
                  label: const Text('Add Member'),
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  onPressed: _showAddMemberDialog,
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveGroup,
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Member'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Member Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = ref.read(dbServiceProvider).isar;
                final newMember = Member(
                  name: nameController.text,
                  initials: nameController.text[0].toUpperCase(),
                  colorValue: AppColors.primaryBlue.value,
                );
                await db.writeTxn(() async {
                  await db.collection<Member>().put(newMember);
                });
                setState(() {
                  _allMembers.add(newMember);
                  _selectedMembers.add(newMember);
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

  void _showIconPicker() {
    final icons = ['👥', '🏠', '🚗', '🍴', '📚', '🎒', '🍿', '✈️'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemCount: icons.length,
          itemBuilder: (context, i) => IconButton(
            onPressed: () {
              setState(() => _selectedIcon = icons[i]);
              Navigator.pop(context);
            },
            icon: Text(icons[i], style: const TextStyle(fontSize: 32)),
          ),
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one more member')),
      );
      return;
    }

    final db = ref.read(dbServiceProvider).isar;
    final group = Group()
      ..name = _nameController.text.trim()
      ..icon = _selectedIcon
      ..createdAt = DateTime.now();

    await db.writeTxn(() async {
      await db.collection<Group>().put(group);
      group.members.addAll(_selectedMembers);
      await group.members.save();
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Group "${group.name}" created!')));
      Navigator.pop(context);
    }
  }
}
