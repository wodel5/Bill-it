//输入卡片
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import 'category_picker.dart';

class InputCard extends StatefulWidget {
  const InputCard({super.key});

  @override
  State<InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<InputCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _fromPersonController = TextEditingController();
  final _fromPersonFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  bool _isBilled = false;
  bool _showFromPersonInput = false;
  String? _selectedCategoryId;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2004, 3, 10),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _toggleFromPersonInput() {
    setState(() {
      _showFromPersonInput = !_showFromPersonInput;
      if (_showFromPersonInput) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fromPersonFocusNode.requestFocus();
        });
      }
    });
  }

  Future<void> _openCategoryPicker() async {
    final id = await showCategoryPicker(context, _selectedCategoryId);
    if (id != null && mounted) {
      setState(() => _selectedCategoryId = id.isEmpty ? null : id);
    }
  }

  Widget _buildCategorySelector() {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final selected = categoryProvider.getById(_selectedCategoryId);

    return GestureDetector(
      onTap: _openCategoryPicker,
      child: InputDecorator(
        decoration: _inputDecoration(context).copyWith(
          hintText: '选择分类',
        ),
        child: selected != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected.icon, size: 18, color: selected.color),
                  const SizedBox(width: 6),
                  Text(
                    selected.name,
                    style: TextStyle(color: selected.color, fontSize: 14),
                  ),
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
                            ?.withValues(alpha: 0.6),
                        fontSize: 14,
                      )),
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final fromPerson =
        _fromPersonController.text.isEmpty ? '我' : _fromPersonController.text;

    provider.addExpense(
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        purpose: _purposeController.text,
        date: _selectedDate,
        isBilled: _isBilled,
        fromPerson: fromPerson,
        categoryId: _selectedCategoryId,
      ),
    );
    _reset();
  }

  void _reset() {
    _amountController.clear();
    _purposeController.clear();
    _fromPersonController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _isBilled = false;
      _showFromPersonInput = false;
      _selectedCategoryId = null;
    });
  }

  InputDecoration _inputDecoration(BuildContext context) => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
    ),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    isDense: true,
  );

  @override
  void dispose() {
    _fromPersonController.dispose();
    _fromPersonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(context)
                          .copyWith(hintText: '金额', prefixText: '¥ '),
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
                    child: InputDecorator(
                      decoration: _inputDecoration(context),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          borderRadius: BorderRadius.circular(8),
                          isExpanded: true,
                          isDense: true,
                          value: _isBilled,
                          icon: Icon(Icons.keyboard_arrow_down,
                              size: 20,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color),
                          style: Theme.of(context).textTheme.bodyMedium,
                          items: const [
                            DropdownMenuItem(
                                value: false, child: Text('未报账')),
                            DropdownMenuItem(
                                value: true, child: Text('已报账')),
                          ],
                          onChanged: (v) => setState(() => _isBilled = v!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purposeController,
                decoration:
                    _inputDecoration(context).copyWith(hintText: '用途'),
                validator: (v) =>
                    v == null || v.isEmpty ? '请输入用途' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: _inputDecoration(context),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCategorySelector()),
                ],
              ),
              const SizedBox(height: 12),
              if (_showFromPersonInput)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _fromPersonController,
                    focusNode: _fromPersonFocusNode,
                    decoration:
                        _inputDecoration(context).copyWith(
                      hintText: '来源人',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, size: 20),
                        onPressed: _toggleFromPersonInput,
                      ),
                    ),
                    onFieldSubmitted: (_) => _toggleFromPersonInput(),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text('添加记录',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  if (!_showFromPersonInput) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _toggleFromPersonInput,
                        child: Icon(Icons.person_outline,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                            size: 22),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
