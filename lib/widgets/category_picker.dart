import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_models/category.dart';
import '../providers/category_provider.dart';

Future<String?> showCategoryPicker(
  BuildContext context,
  String? currentCategoryId,
) {
  return showModalBottomSheet<String?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CategoryPickerSheet(currentCategoryId: currentCategoryId),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  final String? currentCategoryId;
  const _CategoryPickerSheet({this.currentCategoryId});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String? _selectedId;
  bool _manageMode = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentCategoryId;
  }

  void _onSelect(String id) {
    Navigator.pop(context, id);
  }

  void _onClear() {
    Navigator.pop(context, '');
  }

  Future<void> _addCustom() async {
    final existingNames = Provider.of<CategoryProvider>(context, listen: false)
        .categories
        .map((c) => c.name)
        .toList();
    final cat = await showDialog<ExpenseCategory>(
      context: context,
      builder: (_) => _AddCategoryDialog(existingNames: existingNames),
    );
    if (cat != null && mounted) {
      Provider.of<CategoryProvider>(context, listen: false).addCategory(cat);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<CategoryProvider>(context).categories;

    return GestureDetector(
      onTap: () {
        if (_manageMode) setState(() => _manageMode = false);
      },
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '选择分类',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _manageMode = !_manageMode),
                  child: Text(_manageMode ? '完成' : '管理',
                      style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            if (_manageMode)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('默认标签不可删除',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!_manageMode) _buildClearChip(),
                for (final cat in categories) _buildCategoryChip(cat),
                if (!_manageMode) _buildAddChip(),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildClearChip() {
    final isSelected = _selectedId == null || _selectedId!.isEmpty;
    return GestureDetector(
      onTap: _onClear,
      child: Chip(
        avatar: Icon(Icons.close,
            size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
        label: Text(
          '无分类',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
          ),
        ),
        backgroundColor: isSelected
            ? Colors.grey[600]
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildCategoryChip(ExpenseCategory cat) {
    final isSelected = _selectedId == cat.id;
    final showDelete = _manageMode && !cat.isDefault;
    final showLock = _manageMode && cat.isDefault;

    return GestureDetector(
      onTap: _manageMode ? null : () => _onSelect(cat.id),
      child: Chip(
        avatar: Icon(cat.icon,
            size: 18, color: isSelected ? Colors.white : cat.color),
        label: Text(
          cat.name,
          style: TextStyle(
            color: isSelected ? Colors.white : cat.color,
            fontSize: 14,
          ),
        ),
        deleteIcon: showDelete
            ? const Icon(Icons.close, size: 14, color: Colors.red)
            : showLock
                ? const Icon(Icons.lock_outline, size: 14, color: Colors.grey)
                : null,
        onDeleted: showDelete
            ? () {
                Provider.of<CategoryProvider>(context, listen: false)
                    .removeCategory(cat.id);
                setState(() {});
              }
            : null,
        backgroundColor:
            isSelected ? cat.color : cat.color.withValues(alpha: 0.12),
        side: isSelected
            ? BorderSide(color: cat.color, width: 1.5)
            : BorderSide.none,
      ),
    );
  }

  Widget _buildAddChip() {
    return GestureDetector(
      onTap: _addCustom,
      child: const Chip(
        avatar: Icon(Icons.add, size: 18, color: Colors.blue),
        label:
            Text('自定义', style: TextStyle(color: Colors.blue, fontSize: 14)),
        backgroundColor: Color(0xFFE3F2FD),
        side: BorderSide.none,
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final List<String> existingNames;
  const _AddCategoryDialog({required this.existingNames});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  int _selectedColor = ExpenseCategory.availableColors[0];
  String _selectedIcon = ExpenseCategory.availableIconNames[0];
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = '请输入名称');
      return;
    }
    if (widget.existingNames.contains(name)) {
      setState(() => _errorText = '该分类已存在');
      return;
    }
    final cat = ExpenseCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorValue: _selectedColor,
      iconName: _selectedIcon,
    );
    Navigator.pop(context, cat);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自定义分类', style: TextStyle(fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '分类名称',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择颜色',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.availableColors.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('选择图标',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: ExpenseCategory.availableIconNames.map((name) {
                final isSelected = _selectedIcon == name;
                final icon = ExpenseCategory.iconForName(name);
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = name),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.15)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).primaryColor, width: 2)
                          : null,
                    ),
                    child:
                        Icon(icon, size: 22, color: Color(_selectedColor)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('确定', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
