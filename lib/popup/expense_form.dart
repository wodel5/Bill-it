import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_models/expense.dart';
import '../providers/category_provider.dart';
import '../widgets/category_picker.dart';

class ExpenseFormSheet extends StatefulWidget {
  final String title;
  final Expense? initialExpense;
  final String submitLabel;
  final bool showCancel;
  final void Function(Expense) onSubmit;

  const ExpenseFormSheet({
    super.key,
    required this.title,
    this.initialExpense,
    required this.submitLabel,
    this.showCancel = false,
    required this.onSubmit,
  });

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _purposeController;
  late final TextEditingController _fromPersonController;
  late DateTime _selectedDate;
  late bool _isBilled;
  late String? _selectedCategoryId;
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    _amountController = TextEditingController(
        text: e != null ? e.amount.toString() : '');
    _purposeController = TextEditingController(text: e?.purpose ?? '');
    _fromPersonController = TextEditingController(
        text: e != null && e.fromPerson != '-'
            ? e.fromPerson
            : '');
    _selectedDate = e?.date ?? DateTime.now();
    _dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    _isBilled = e?.isBilled ?? false;
    _selectedCategoryId = e?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _fromPersonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2004, 3, 10),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _openCategoryPicker() async {
    final id = await showCategoryPicker(context, _selectedCategoryId);
    if (id != null && mounted) {
      setState(() => _selectedCategoryId = id.isEmpty ? null : id);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final fromPerson =
        _fromPersonController.text.isEmpty ? '我' : _fromPersonController.text;
    widget.onSubmit(
      Expense(
        id: widget.initialExpense?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        purpose: _purposeController.text,
        date: _selectedDate,
        isBilled: _isBilled,
        fromPerson: fromPerson,
        categoryId: _selectedCategoryId,
      ),
    );
  }

  InputDecoration _decoration() => InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final selectedCat = catProvider.getById(_selectedCategoryId);

    return SingleChildScrollView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _decoration().copyWith(
                              hintText: '¥金额'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '请输入金额';
                            if (double.tryParse(v) == null) return '请输入数字';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _BilledPopupButton(
                          isBilled: _isBilled,
                          onChanged: (v) => setState(() => _isBilled = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _purposeController,
                          decoration:
                              _decoration().copyWith(hintText: '用途'),
                          validator: (v) =>
                              v == null || v.isEmpty ? '请输入用途' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: _decoration().copyWith(
                              hintText: '日期'),
                          onTap: _selectDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fromPersonController,
                    decoration:
                        _decoration().copyWith(hintText: '来源人（选填）'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _openCategoryPicker,
                    child: InputDecorator(
                      decoration: _decoration().copyWith(
                          hintText: '选择分类'),
                      child: selectedCat != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(selectedCat.icon,
                                    size: 18,
                                    color: selectedCat.color),
                                const SizedBox(width: 6),
                                Text(selectedCat.name,
                                    style: TextStyle(
                                        color: selectedCat.color,
                                        fontSize: 14)),
                                const Spacer(),
                                Icon(Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('选择分类',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withValues(
                                                alpha: 0.6),
                                        fontSize: 14)),
                                const Spacer(),
                                Icon(Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.showCancel)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.12),
                              minimumSize:
                                  const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide.none,
                            ),
                            child: const Text('取消',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColor,
                              minimumSize:
                                  const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(widget.submitLabel,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(widget.submitLabel,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BilledPopupButton extends StatelessWidget {
  final bool isBilled;
  final ValueChanged<bool> onChanged;

  const _BilledPopupButton({
    required this.isBilled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      position: PopupMenuPosition.under,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: false,
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text('未报账',
                    style: TextStyle(
                      fontSize: 15,
                      color: isBilled
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).colorScheme.secondary,
                      fontWeight: isBilled ? FontWeight.normal : FontWeight.bold,
                    )),
              ),
              if (!isBilled)
                Icon(Icons.check, size: 20,
                    color: Theme.of(context).colorScheme.secondary),
            ],
          ),
        ),
        PopupMenuItem(
          value: true,
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text('已报账',
                    style: TextStyle(
                      fontSize: 15,
                      color: isBilled
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isBilled ? FontWeight.bold : FontWeight.normal,
                    )),
              ),
              if (isBilled)
                Icon(Icons.check, size: 20,
                    color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      ],
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          isDense: true,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isBilled ? '已报账' : '未报账',
                style: TextStyle(
                  fontSize: 14,
                  color: isBilled
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.secondary,
                )),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, size: 20,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
