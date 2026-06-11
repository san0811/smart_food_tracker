import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
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
      Icons.home_rounded,
      Icons.inventory_2_rounded,
      Icons.add_circle_outline_rounded,
      Icons.restaurant_menu_rounded,
      Icons.settings_rounded,
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A).withValues(alpha: 0.92),
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
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      icons[index],
                      color: selected ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Evening',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text('Harit', style: theme.textTheme.titleLarge),
                        ],
                      ),
                    ),
                    const _CircleButton(icon: Icons.notifications_none_rounded),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _DayChip(day: 'Mon', date: '03'),
                      _DayChip(day: 'Tue', date: '04'),
                      _DayChip(day: 'Wed', date: '05'),
                      _DayChip(day: 'Thu', date: '06', selected: true),
                      _DayChip(day: 'Fri', date: '07'),
                      _DayChip(day: 'Sat', date: '08'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
                        goal: 'Saved across items',
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
                        goal: 'Saved across items',
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
                        goal: 'Saved across items',
                        progress: fat == 0 ? 0 : (fat / 70).clamp(0, 1),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MacroCard(
                        title: 'Expiry alerts',
                        amount: '${provider.expiringSoonCount} items',
                        goal: 'Need checking',
                        progress: provider.expiringSoonCount == 0 ? 0 : 0.55,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Quick tools', style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),
                const _QuickFeatureRow(),
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
                            subtitle: item.brand ?? item.category,
                            quantity: item.quantityLabel,
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
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.date,
    this.selected = false,
  });

  final String day;
  final String date;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x22FFFFFF)),
        color: AppTheme.panelSoft,
      ),
      child: Icon(icon, color: Colors.white),
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
    final left = (target - consumed).clamp(0, target);

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
                '$left',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'kcal left',
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
    required this.goal,
    required this.progress,
  });

  final String title;
  final String amount;
  final String goal;
  final double progress;

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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(goal, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
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
    );
  }
}

class _QuickFeatureRow extends StatelessWidget {
  const _QuickFeatureRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _FeatureCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'Add food',
            subtitle: 'Manual form or barcode scan',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Barcode',
            subtitle: 'Read packaged food',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.list_alt_rounded,
            title: 'Items',
            subtitle: 'Check saved nutrition',
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.title,
    required this.subtitle,
    required this.quantity,
  });

  final String title;
  final String subtitle;
  final String quantity;

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
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.black),
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
