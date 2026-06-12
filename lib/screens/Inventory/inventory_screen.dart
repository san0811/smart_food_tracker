import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';
import '../food/edit_food_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key, this.onHistoryRequested});

  final VoidCallback? onHistoryRequested;

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        final availableItems = provider.availableItems;
        final historyItems = provider.archivedItems.take(3).toList();

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryStat(
                        label: 'Active items',
                        value: provider.activeInventoryCount.toString(),
                        note: 'Currently in storage',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InventoryStat(
                        label: 'Expiring soon',
                        value: provider.expiringSoonCount.toString(),
                        note: 'Use within 2 days',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryStat(
                        label: 'Out of stock',
                        value: provider.outOfStockCount.toString(),
                        note: 'Previously scanned',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InventoryStat(
                        label: 'Categories',
                        value: _categoryCount(provider.items).toString(),
                        note: 'Saved food groups',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Use first',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                if (availableItems.isEmpty)
                  const _EmptyInventoryState(
                    title: 'No saved inventory yet',
                    subtitle:
                        'Scan a barcode or save a food item to start building your inventory.',
                  )
                else
                  ...availableItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InventoryEntry(
                        item: item,
                        onHistoryRequested: onHistoryRequested,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('History', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.panel,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0x12FFFFFF)),
                  ),
                  child: historyItems.isEmpty
                      ? const _EmptyInventoryState(
                          title: 'No used items yet',
                          subtitle:
                              'Items marked used or out of stock will appear here.',
                          compact: true,
                        )
                      : Column(
                          children: historyItems
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _MiniInventoryRow(item: item),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _categoryCount(List<FoodItem> items) {
    return items.map((item) => item.category).toSet().length;
  }
}

class _InventoryStat extends StatelessWidget {
  const _InventoryStat({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(note, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InventoryEntry extends StatelessWidget {
  const _InventoryEntry({required this.item, required this.onHistoryRequested});

  final FoodItem item;
  final VoidCallback? onHistoryRequested;

  @override
  Widget build(BuildContext context) {
    final highlighted = item.expiryDate != null;
    final foreground = highlighted ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.surface : AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? Colors.transparent : const Color(0x12FFFFFF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: highlighted ? Colors.black : AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _itemIcon(item),
              color: highlighted ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: highlighted ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: TextStyle(
                    color: highlighted
                        ? Colors.black54
                        : const Color(0xFFB9B2A8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.packageDetail,
                  style: TextStyle(
                    color: highlighted ? Colors.black54 : Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.expiryDate ?? 'No expiry date added',
                  style: TextStyle(
                    color: highlighted ? Colors.black87 : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit item',
                onPressed: () => _openEditFoodScreen(context, item),
                icon: Icon(Icons.edit_rounded, color: foreground),
              ),
              const SizedBox(height: 4),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: highlighted
                      ? Colors.black.withValues(alpha: 0.08)
                      : AppTheme.surface,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _useItem(context, item, onHistoryRequested),
                child: const Text('Use'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 92,
                child: Text(
                  item.stockCount.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInventoryRow extends StatelessWidget {
  const _MiniInventoryRow({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(_itemIcon(item), color: Colors.black),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                item.brand == null
                    ? item.packageDetail
                    : '${item.brand} | ${item.packageDetail}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Edit item',
              onPressed: () => _openEditFoodScreen(context, item),
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
            SizedBox(
              width: 92,
              child: Text(
                item.stockCount.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openEditFoodScreen(BuildContext context, FoodItem item) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => EditFoodScreen(item: item)));
}

Future<void> _useItem(
  BuildContext context,
  FoodItem item,
  VoidCallback? onHistoryRequested,
) async {
  final provider = context.read<FoodProvider>();

  final used = await provider.useInventoryItem(item: item, quantityUsed: 1);

  if (!context.mounted) {
    return;
  }

  if (used == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Could not update this item right now.',
        ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        item.stockCount > 1
            ? 'Used 1 from ${item.name}'
            : '${item.name} moved to history',
      ),
    ),
  );

  onHistoryRequested?.call();
}

IconData _itemIcon(FoodItem item) {
  return item.category.toLowerCase() == 'drink'
      ? Icons.local_cafe_rounded
      : Icons.lunch_dining_rounded;
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
