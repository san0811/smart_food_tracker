import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';
import '../Inventory/inventory_screen.dart';
import '../food/add_food_screen.dart';
import '../food/food_list_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int? _hoveredIndex;
  late final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _DashboardView(),
      const InventoryScreen(),
      const AddFoodScreen(),
      const FoodListScreen(),
      const SettingsScreen(),
    ];

    final icons = <IconData>[
      Icons.kitchen_rounded,
      Icons.inventory_2_rounded,
      Icons.add_circle_outline_rounded,
      Icons.receipt_long_rounded,
      Icons.tune_rounded,
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            children: pages,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0x18FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 30,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(icons.length, (index) {
                    final selected = index == _selectedIndex;
                    final hovered = index == _hoveredIndex;
                    return Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = null),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          scale: selected ? 1.0 : (hovered ? 0.985 : 0.94),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              splashColor: Colors.white24,
                              highlightColor: Colors.white12,
                              onTap: () {
                                setState(() => _selectedIndex = index);
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.actionBlue
                                      : hovered
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Icon(
                                  icons[index],
                                  color: selected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        final inventory = provider.availableItems;
        final calories = provider.totalCalories;
        final protein = provider.totalProtein;
        final carbs = provider.totalCarbs;
        final fat = provider.totalFat;

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const _BrandHeader(),
                const SizedBox(height: 16),
                Text('Today at a glance', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved nutrition overview',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: Center(
                          child: _CalorieRing(
                            consumed: calories.round(),
                            target: 2200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricLine(
                              label: 'Items in inventory',
                              value: inventory.length.toString(),
                            ),
                          ),
                          Expanded(
                            child: _MetricLine(
                              label: 'Expiring soon',
                              value: provider.expiringSoonCount.toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MacroCard(
                        title: 'Protein',
                        amount: '${protein.toStringAsFixed(1)}g',
                        progress: protein == 0
                            ? 0
                            : (protein / 120).clamp(0, 1),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MacroCard(
                        title: 'Carbs',
                        amount: '${carbs.toStringAsFixed(1)}g',
                        progress: carbs == 0 ? 0 : (carbs / 200).clamp(0, 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MacroCard(
                        title: 'Fat',
                        amount: '${fat.toStringAsFixed(1)}g',
                        progress: fat == 0 ? 0 : (fat / 70).clamp(0, 1),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MacroCard(
                        title: 'Expiry alerts',
                        amount: '${provider.expiringSoonCount} items',
                        progress: provider.expiringSoonCount == 0
                            ? 0
                            : (provider.expiringSoonCount / 10).clamp(0, 1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Text('Inventory priorities', style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),
                if (inventory.isEmpty)
                  const _EmptyPriorityCard()
                else
                  ...inventory
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InventoryCard(
                            title: item.name,
                            subtitle:
                                '${item.brand ?? item.category} | ${item.packageDetail}',
                            quantity: item.stockCount.toString(),
                            icon: _itemIcon(item),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _itemIcon(FoodItem item) {
    return item.category.toLowerCase() == 'drink'
        ? Icons.local_cafe_rounded
        : Icons.lunch_dining_rounded;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
               child: Image.asset(
                 'assets/images/Fridgi_logo.png',
                 fit: BoxFit.contain,
               ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fridgi', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.consumed, required this.target});

  final int consumed;
  final int target;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : consumed / target;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(160),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$consumed',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'kcal consumed',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0x19000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.black, Color(0xFF5A5A5A)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi * 0.75, math.pi * 1.5, false, backgroundPaint);
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.title,
    required this.amount,
    required this.progress,
  });

  final String title;
  final String amount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.surface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String quantity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.actionBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            quantity,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPriorityCard extends StatelessWidget {
  const _EmptyPriorityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Text(
        'No saved inventory yet. Use the add food tab to scan a barcode or save an item manually.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
