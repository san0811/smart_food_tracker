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
import 'custom_bottom_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const Duration _transitionDuration = Duration(milliseconds: 300);

  late final PageController _pageController;
  late final List<ScrollController> _scrollControllers;
  late final List<Widget> _pages;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _scrollControllers = List<ScrollController>.generate(
      5,
      (_) => ScrollController(),
    );
    _pages = <Widget>[
      _buildPage(0, const _DashboardView()),
      _buildPage(1, InventoryScreen(onHistoryRequested: () => _selectTab(3))),
      _buildPage(2, const AddFoodScreen()),
      _buildPage(3, const FoodListScreen()),
      _buildPage(4, const SettingsScreen()),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      _scrollCurrentTabToTop(index);
      return;
    }

    _pageController.animateToPage(
      index,
      duration: _transitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollCurrentTabToTop(int index) {
    if (index != _selectedIndex) {
      return;
    }

    final controller = _scrollControllers[index];
    if (!controller.hasClients) {
      return;
    }

    controller.animateTo(
      0,
      duration: _transitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildPage(int index, Widget child) {
    return _KeepAlivePage(
      child: PrimaryScrollController(
        controller: _scrollControllers[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _pages,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14, top: 4),
                child: CustomBottomNavBar(
                  currentIndex: _selectedIndex,
                  onTap: _selectTab,
                  onDoubleTapCurrentTab: _scrollCurrentTabToTop,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/Fridgi_logo.jpeg',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
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
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.surface,
                ),
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
