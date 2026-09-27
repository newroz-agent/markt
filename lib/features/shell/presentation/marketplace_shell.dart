import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/account/presentation/account_screen.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/presentation/categories_foundation_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_inbox_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_foundation_screen.dart';
import 'package:zerin_marketplace/features/sell/presentation/sell_foundation_screen.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class MarketplaceShell extends ConsumerStatefulWidget {
  const MarketplaceShell({required this.initialIndex, super.key});

  final int initialIndex;

  @override
  ConsumerState<MarketplaceShell> createState() => _MarketplaceShellState();
}

class _MarketplaceShellState extends ConsumerState<MarketplaceShell> {
  static const _sellIndex = 2;
  static const _chatIndex = 3;
  static const _lastIndex = 4;

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizedIndex(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant MarketplaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = _normalizedIndex(widget.initialIndex);
    }
  }

  int _normalizedIndex(int index) =>
      index >= 0 && index <= _lastIndex ? index : 0;

  void _select(int index) {
    if (index == _sellIndex || index == _chatIndex) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        AuthRoute(
          redirectTo: MarketplaceRoute(tab: index).location,
        ).push<void>(context);
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.watch(authStateProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final unread = user == null
        ? 0
        : ref.watch(unreadChatCountProvider).asData?.value ?? 0;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          HomeFoundationScreen(),
          CategoriesFoundationScreen(),
          SellFoundationScreen(),
          ChatInboxScreen(),
          AccountScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox.square(
        dimension: AppSizes.sellFabSize,
        child: FloatingActionButton(
          elevation: AppElevation.sellFab,
          tooltip: l10n.navigationSell,
          onPressed: () => _select(_sellIndex),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: AppSizes.bottomBarHeight,
        shape: const CircularNotchedRectangle(),
        notchMargin: AppSpacing.xs,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _NavigationItem(
                label: l10n.navigationHome,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: _currentIndex == 0,
                onTap: () => _select(0),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                label: l10n.navigationCategories,
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                selected: _currentIndex == 1,
                onTap: () => _select(1),
              ),
            ),
            SizedBox(
              width: AppSizes.sellFabSize,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  l10n.navigationSell,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _currentIndex == _sellIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                label: l10n.navigationMessages,
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum_rounded,
                selected: _currentIndex == _chatIndex,
                unreadCount: unread,
                onTap: () => _select(_chatIndex),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                label: l10n.navigationAccount,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                selected: _currentIndex == _lastIndex,
                onTap: () => _select(_lastIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.unreadCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final iconWidget = Icon(selected ? selectedIcon : icon, color: color);

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? context.l10n.semanticsSelectedTab(label: label) : label,
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.minimumTouchTarget,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: iconWidget,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
