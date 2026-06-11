import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';

class EditFoodScreen extends StatefulWidget {
  const EditFoodScreen({super.key, required this.item});

  final FoodItem item;

  @override
  State<EditFoodScreen> createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends State<EditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _categoryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _expiryController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _brandController = TextEditingController(text: item.brand ?? '');
    _categoryController = TextEditingController(text: item.category);
    _quantityController = TextEditingController(text: item.packageDetail);
    _expiryController = TextEditingController(text: item.expiryDate ?? '');
    _caloriesController = TextEditingController(
      text: _formatNumber(item.nutrition.calories),
    );
    _proteinController = TextEditingController(
      text: _formatNumber(item.nutrition.protein),
    );
    _carbsController = TextEditingController(
      text: _formatNumber(item.nutrition.carbs),
    );
    _fatController = TextEditingController(
      text: _formatNumber(item.nutrition.fat),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _expiryController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 10);
    final parsedDate = DateTime.tryParse(_expiryController.text.trim());
    final fallbackDate = now.add(const Duration(days: 7));
    final initialDate = parsedDate == null
        ? fallbackDate
        : parsedDate.isBefore(firstDate)
        ? firstDate
        : parsedDate.isAfter(lastDate)
        ? lastDate
        : parsedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _expiryController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save(FoodProvider provider) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await provider.updateFoodItem(
      item: widget.item,
      name: _nameController.text.trim(),
      brand: _optionalValue(_brandController),
      category: _categoryController.text.trim(),
      quantityLabel: _buildQuantityLabel(_quantityController.text.trim()),
      expiryDate: _optionalValue(_expiryController),
      calories: _parseNumber(_caloriesController),
      protein: _parseNumber(_proteinController),
      carbs: _parseNumber(_carbsController),
      fat: _parseNumber(_fatController),
    );

    if (!mounted || saved == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('${saved.name} updated')));
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  double _parseNumber(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  String _buildQuantityLabel(String packageDetail) {
    return '${widget.item.stockCount} x $packageDetail';
  }

  String _formatNumber(double value) {
    if (value == 0) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Edit food',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.panel,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0x12FFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Food name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a food name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _brandController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Brand',
                              hintText: 'Optional',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _categoryController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _quantityController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Size or detail',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a size or detail';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _expiryController,
                            readOnly: true,
                            onTap: _pickExpiryDate,
                            decoration: InputDecoration(
                              labelText: 'Expiry date',
                              hintText: 'Optional',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_expiryController.text.isNotEmpty)
                                    IconButton(
                                      onPressed: () {
                                        setState(_expiryController.clear);
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  IconButton(
                                    onPressed: _pickExpiryDate,
                                    icon: const Icon(
                                      Icons.calendar_today_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _caloriesController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Calories',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _proteinController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Protein (g)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _carbsController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Carbs (g)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _fatController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Fat (g)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (provider.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              provider.errorMessage!,
                              style: const TextStyle(color: Color(0xFFFFB4AB)),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.surface,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: provider.isLoading
                                  ? null
                                  : () => _save(provider),
                              child: Text(
                                provider.isLoading
                                    ? 'Saving...'
                                    : 'Save changes',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
