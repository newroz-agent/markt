import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/app_button.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    await ref.read(appSettingsControllerProvider.notifier).completeOnboarding();
    if (mounted) const MarketplaceRoute().go(context);
  }

  Future<void> _next() async {
    if (_currentPage == 2) {
      await _complete();
      return;
    }
    await _pageController.nextPage(
      duration: AppDurations.standard,
      curve: AppMotion.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = <_OnboardingPageData>[
      _OnboardingPageData(
        icon: Icons.storefront_rounded,
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      _OnboardingPageData(
        icon: Icons.near_me_rounded,
        title: l10n.onboardingDiscoverTitle,
        body: l10n.onboardingDiscoverBody,
      ),
      _OnboardingPageData(
        icon: Icons.sell_rounded,
        title: l10n.onboardingSellTitle,
        body: l10n.onboardingSellBody,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: AppSpacing.page,
              child: Row(
                children: <Widget>[
                  _BrandLockup(name: l10n.appName),
                  const Spacer(),
                  AppButton.ghost(
                    label: l10n.actionSkip,
                    onPressed: _complete,
                    loading: _isCompleting,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      pages.length,
                      (index) => Semantics(
                        selected: index == _currentPage,
                        child: AnimatedContainer(
                          duration: AppDurations.quick,
                          curve: AppMotion.standardCurve,
                          width: index == _currentPage
                              ? AppSizes.pageIndicatorSelected
                              : AppSizes.pageIndicator,
                          height: AppSizes.pageIndicator,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: AppRadius.pill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.primary(
                    label: _currentPage == pages.length - 1
                        ? l10n.actionGetStarted
                        : l10n.actionNext,
                    onPressed: _next,
                    loading: _isCompleting,
                    expand: true,
                    size: AppButtonSize.large,
                    leading: Icon(
                      _currentPage == pages.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.navigate_next_rounded,
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      namesRoute: true,
      header: true,
      label: data.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: AppSizes.onboardingVisual,
              height: AppSizes.onboardingVisual,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: <Color>[
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: AppRadius.extraLarge,
              ),
              child: Icon(
                data.icon,
                size: AppSizes.iconHero,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              data.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formMaxWidth,
              ),
              child: Text(
                data.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: AppSizes.avatarMedium,
        height: AppSizes.avatarMedium,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: AppRadius.medium,
        ),
        child: Icon(
          Icons.diamond_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(name, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
