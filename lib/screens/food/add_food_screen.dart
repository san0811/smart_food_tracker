import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/food_provider.dart';
import '../scanner/barcode_screen.dart';

enum _AddFoodOption { manual, barcode }

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  _AddFoodOption? _selectedOption;

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

  Future<void> _openBarcodeScanner() async {
    setState(() {
      _selectedOption = _AddFoodOption.barcode;
    });

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BarcodeScreen()));

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedOption = null;
    });
  }

  Future<void> _submitManualForm(FoodProvider provider) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await provider.addManualItem(
      name: _nameController.text.trim(),
      brand: _optionalValue(_brandController),
      category: _categoryController.text.trim(),
      quantityLabel: _quantityController.text.trim(),
      expiryDate: _optionalValue(_expiryController),
      calories: _parseNumber(_caloriesController),
      protein: _parseNumber(_proteinController),
      carbs: _parseNumber(_carbsController),
      fat: _parseNumber(_fatController),
    );

    if (!mounted || saved == null) {
      return;
    }

    _formKey.currentState!.reset();
    _nameController.clear();
    _brandController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _expiryController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${saved.name} added to your inventory')),
    );
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  double _parseNumber(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add food',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose how you want to add a food item to your inventory.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _AddOptionCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Add manually',
                  subtitle:
                      'Open a form and enter the food name, quantity, and nutrition details.',
                  selected: _selectedOption == _AddFoodOption.manual,
                  actionLabel: 'Open form',
                  onTap: () {
                    setState(() {
                      _selectedOption = _AddFoodOption.manual;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _AddOptionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan barcode',
                  subtitle:
                      'Use the camera to scan packaged food and fetch nutrition data automatically.',
                  selected: _selectedOption == _AddFoodOption.barcode,
                  actionLabel: 'Open camera',
                  onTap: _openBarcodeScanner,
                ),
                const SizedBox(height: 20),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _selectedOption == _AddFoodOption.manual
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const _AddFoodHintCard(),
                  secondChild: _ManualFoodForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    brandController: _brandController,
                    categoryController: _categoryController,
                    quantityController: _quantityController,
                    expiryController: _expiryController,
                    caloriesController: _caloriesController,
                    proteinController: _proteinController,
                    carbsController: _carbsController,
                    fatController: _fatController,
                    isLoading: provider.isLoading,
                    onSubmit: () => _submitManualForm(provider),
                  ),
                ),
                if (provider.errorMessage != null &&
                    _selectedOption == _AddFoodOption.manual) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x33E06C75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x55E06C75)),
                    ),
                    child: Text(
                      provider.errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surface : AppTheme.panel,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0x12FFFFFF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? Colors.black : AppTheme.panelSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppTheme.surface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: selected ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? Colors.black87 : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: selected ? Colors.black : AppTheme.surface,
                      fontWeight: FontWeight.w700,
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

class _AddFoodHintCard extends StatelessWidget {
  const _AddFoodHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(
        'Pick one option above. Manual entry opens a form here, while barcode scan launches the camera.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ManualFoodForm extends StatelessWidget {
  const _ManualFoodForm({
    required this.formKey,
    required this.nameController,
    required this.brandController,
    required this.categoryController,
    required this.quantityController,
    required this.expiryController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController brandController;
  final TextEditingController categoryController;
  final TextEditingController quantityController;
  final TextEditingController expiryController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual form', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add the basic details and nutrition values for this item.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Food name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a food name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: brandController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Brand',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: categoryController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: quantityController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'Example: 1 bottle, 500g, 2 packs',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: expiryController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Expiry date',
                hintText: 'Optional, example: 2026-06-30',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Calories'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Protein (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Carbs (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: fatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Fat (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: isLoading ? null : onSubmit,
                child: Text(isLoading ? 'Saving...' : 'Save food'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
