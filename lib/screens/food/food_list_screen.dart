import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        final items = provider.archivedItems;

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Used and out-of-stock items stay here so your active inventory stays clean.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _FoodList(items: items),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({required this.items});

  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyItemsState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Column(
        key: ValueKey(items.length),
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _FoodCard(data: item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.data});

  final FoodItem data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.brand == null
                            ? '${data.category} | ${data.packageDetail}'
                            : '${data.brand} | ${data.category} | ${data.packageDetail}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: data.isInInventory
                          ? AppTheme.surface
                          : AppTheme.panelSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      data.stockCount.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: data.isInInventory
                            ? Colors.black
                            : Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _NutritionTile(
                    label: 'Calories',
                    value: '${data.nutrition.calories.toStringAsFixed(0)} kcal',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionTile(
                    label: 'Protein',
                    value: '${data.nutrition.protein.toStringAsFixed(1)}g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NutritionTile(
                    label: 'Carbs',
                    value: '${data.nutrition.carbs.toStringAsFixed(1)}g',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionTile(
                    label: 'Fat',
                    value: '${data.nutrition.fat.toStringAsFixed(1)}g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x22FFFFFF)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      data.barcode ?? 'Manual item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => context
                        .read<FoodProvider>()
                        .toggleInventoryStatus(data),
                    child: const Text('Return to inventory'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No history yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            'When an item is marked used, it will move from inventory into history.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
