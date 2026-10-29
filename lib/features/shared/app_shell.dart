
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../products/product_state.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  int get selectedIndex {
    /*if (location.startsWith('/explore')) return 1;*/
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/account')) return 3;
    return 0;
  }

  static const destinations = [
    // (label: 'Home', icon: Icons.home_outlined, route: '/'),
    (label: 'Explore', icon: Icons.grid_view_rounded, route: '/'),
    (
    label: 'Chat',
    icon: Icons.chat_bubble_outline_rounded,
    route: '/chat',
    ),
    (
    label: 'Cart',
    icon: Icons.shopping_bag_outlined,
    route: '/cart',
    ),
    (
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    route: '/account',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= Breakpoints.tablet;

    final cartCount = ref.watch(storeProvider).cart.values.fold<int>(
      0,
          (sum, line) => sum + line.quantity,
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _GlassNavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                context.go(destinations[index].route);
              },
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _GlassBottomNavigation(
        selectedIndex: selectedIndex,
        cartCount: cartCount,
        onDestinationSelected: (index) {
          context.go(destinations[index].route);
        },
      ),
    );
  }
}

class _GlassBottomNavigation extends StatelessWidget {
  const _GlassBottomNavigation({
    required this.selectedIndex,
    required this.cartCount,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(70),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey900.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(70),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.22),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.13),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.white.withValues(alpha: 0.06),
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: List.generate(
                AppShell.destinations.length,
                    (index) {
                  final destination = AppShell.destinations[index];
                  final selected = selectedIndex == index;

                  return Expanded(
                    child: _GlassNavItem(
                      label: destination.label,
                      icon: destination.icon,
                      selected: selected,
                      badgeCount: index == 2  ? cartCount : 0,
                      onTap: () => onDestinationSelected(index),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.black
        : AppColors.white.withValues(alpha: 0.78);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(70),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              vertical: 7,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.white.withValues(alpha: 0.96)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              border: selected
                  ? Border.all(
                color: AppColors.white.withValues(alpha: 0.8),
              )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 15,
                  child: /*Stack(
                    clipBehavior: Clip.none,
                    children: [*/
                      Center(
                        child: AnimatedScale(
                          scale: selected ? 1.05 : 1,
                          duration: const Duration(milliseconds: 180),
                          child:

                          Stack(
                              clipBehavior: Clip.none,
                              children: [
                          Icon(
                            selected ? _selectedIcon(icon) : icon,
                            size: 21,
                            color: foreground,
                          ),
                                if (badgeCount > 0)
                                  Positioned(
                                    top: -5,
                                    right: -10,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.black
                                            : AppColors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.white
                                              : AppColors.grey900,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          badgeCount > 99 ? '99+' : '$badgeCount',
                                          style: TextStyle(
                                            color: selected
                                                ? AppColors.white
                                                : AppColors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                          ),

                        ),
                      ),
                      /*if (badgeCount > 0)
                        Positioned(
                          top: -5,
                          right: -10,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.black
                                  : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppColors.white
                                    : AppColors.grey900,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),*/
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10,
                    letterSpacing: 0.1,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _selectedIcon(IconData icon) {
    switch (label) {
     /* case 'Home':
        return Icons.home_rounded;*/
      case 'Explore':
        return Icons.grid_view_rounded;
      case 'Chat':
        return Icons.chat_bubble_rounded;
      case 'Cart':
        return Icons.shopping_bag_rounded;
      case 'Profile':
        return Icons.person_rounded;
      default:
        return icon;
    }
  }
}

class _GlassNavigationRail extends StatelessWidget {
  const _GlassNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.grey900.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            minWidth: 88,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.65,
            leading: const Padding(
              padding: EdgeInsets.only(top: 22, bottom: 32),
              child: Text(
                'M.',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            indicatorColor: AppColors.white.withValues(alpha: 0.96),
            selectedIconTheme: const IconThemeData(
              color: AppColors.black,
              size: 23,
            ),
            unselectedIconTheme: IconThemeData(
              color: AppColors.white.withValues(alpha: 0.72),
              size: 22,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: AppColors.white.withValues(alpha: 0.72),
              fontSize: 11,
            ),
            destinations: AppShell.destinations.map((destination) {
              return NavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(_railSelectedIcon(destination.label)),
                label: Text(destination.label),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _railSelectedIcon(String label) {
    switch (label) {
     /* case 'Home':
        return Icons.home_rounded;*/
      case 'Explore':
        return Icons.grid_view_rounded;
      case 'Chat':
        return Icons.chat_bubble_rounded;
      case 'Cart':
        return Icons.shopping_bag_rounded;
      case 'Profile':
        return Icons.person_rounded;
      default:
        return Icons.circle;
    }
  }
}
