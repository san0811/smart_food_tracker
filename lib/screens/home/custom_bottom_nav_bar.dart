import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onDoubleTapCurrentTab,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onDoubleTapCurrentTab;

  static const List<_NavItemData> _items = <_NavItemData>[
    _NavItemData(icon: Icons.kitchen_rounded, label: 'Home'),
    _NavItemData(icon: Icons.inventory_2_rounded, label: 'Stock'),
    _NavItemData(icon: Icons.add_circle_outline_rounded, label: 'Add'),
    _NavItemData(icon: Icons.receipt_long_rounded, label: 'List'),
    _NavItemData(icon: Icons.tune_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141414).withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0x16FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4A000000),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;

                return SizedBox(
                  height: 74,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * itemWidth + 6,
                        top: 8,
                        bottom: 8,
                        width: itemWidth - 12,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.actionBlue.withValues(alpha: 0.28),
                                AppTheme.actionBlueOnDark.withValues(alpha: 0.14),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.actionBlue.withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(_items.length, (index) {
                          final item = _items[index];
                          final selected = index == currentIndex;
                          final color =
                              selected ? AppTheme.actionBlueOnDark : Colors.white70;

                          return Expanded(
                            child: Tooltip(
                              message: item.label,
                              child: _NavTapRegion(
                                selected: selected,
                                onTap: () => onTap(index),
                                onDoubleTap: () {
                                  if (selected) {
                                    onDoubleTapCurrentTab(index);
                                  }
                                },
                                child: SizedBox(
                                  height: double.infinity,
                                  child: Center(
                                    child: AnimatedScale(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      scale: selected ? 1.18 : 1.0,
                                      child: Icon(item.icon, color: color),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTapRegion extends StatelessWidget {
  const _NavTapRegion({
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: child,
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
