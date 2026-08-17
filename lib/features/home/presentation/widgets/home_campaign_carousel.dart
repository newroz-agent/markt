import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

class HomeCampaignCarousel extends StatefulWidget {
  const HomeCampaignCarousel({required this.campaigns, super.key});

  final List<AdCampaign> campaigns;

  @override
  State<HomeCampaignCarousel> createState() => _HomeCampaignCarouselState();
}

class _HomeCampaignCarouselState extends State<HomeCampaignCarousel> {
  final PageController _controller = PageController();
  Timer? _autoPlayTimer;
  Timer? _resumeTimer;
  int _currentPage = 0;
  bool _touching = false;
  bool _disableAnimations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations == disableAnimations && _autoPlayTimer != null) {
      return;
    }
    _disableAnimations = disableAnimations;
    _scheduleAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HomeCampaignCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.campaigns.length) {
      _currentPage = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
    if (oldWidget.campaigns.length != widget.campaigns.length) {
      _scheduleAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_disableAnimations || _touching || widget.campaigns.length < 2) return;
    _autoPlayTimer = Timer.periodic(AppDurations.carouselAutoPlay, (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.campaigns.length;
      _controller.animateToPage(
        nextPage,
        duration: AppDurations.emphasized,
        curve: AppMotion.emphasizedCurve,
      );
    });
  }

  void _pauseForTouch() {
    _touching = true;
    _resumeTimer?.cancel();
    _autoPlayTimer?.cancel();
  }

  void _resumeAfterTouch() {
    _touching = false;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(AppDurations.carouselResume, _scheduleAutoPlay);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Listener(
      onPointerDown: (_) => _pauseForTouch(),
      onPointerUp: (_) => _resumeAfterTouch(),
      onPointerCancel: (_) => _resumeAfterTouch(),
      child: AspectRatio(
        aspectRatio: AppRatios.widescreen,
        child: ClipRRect(
          borderRadius: AppRadius.extraLarge,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.campaigns.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final campaign = widget.campaigns[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final page =
                      _controller.hasClients &&
                          _controller.position.hasContentDimensions
                      ? _controller.page ?? _currentPage.toDouble()
                      : _currentPage.toDouble();
                  final delta = (index - page).clamp(-1.0, 1.0);
                  return _CampaignSlide(
                    campaign: campaign,
                    languageCode: languageCode,
                    pageOffset: delta,
                    pageCount: widget.campaigns.length,
                    activePage: _currentPage,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CampaignSlide extends StatelessWidget {
  const _CampaignSlide({
    required this.campaign,
    required this.languageCode,
    required this.pageOffset,
    required this.pageCount,
    required this.activePage,
  });

  final AdCampaign campaign;
  final String languageCode;
  final double pageOffset;
  final int pageCount;
  final int activePage;

  @override
  Widget build(BuildContext context) {
    final title = campaign.titleForLanguage(languageCode);
    final subtitle = campaign.subtitleForLanguage(languageCode);
    return Semantics(
      image: true,
      label: '$title. $subtitle',
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FractionalTranslation(
            translation: Offset(pageOffset * 0.1, 0),
            child: Transform.scale(
              scale: 1.12,
              child: CachedNetworkImage(
                imageUrl: campaign.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const AppSkeletonBox(borderRadius: BorderRadius.zero),
                errorWidget: (_, _, _) => const _CampaignFallback(),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.petrol950.withValues(alpha: AppOpacity.subtle),
                  AppColors.petrol950.withValues(alpha: AppOpacity.overlay),
                  AppColors.petrol950.withValues(alpha: AppOpacity.strong),
                ],
                stops: <double>[0, 0.42, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.md,
            end: AppSpacing.md,
            child: _PageDots(count: pageCount, activeIndex: activePage),
          ),
          PositionedDirectional(
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.berf0,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.berf100,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: AppDurations.quick,
          curve: AppMotion.standardCurve,
          width: active
              ? AppSizes.homeCarouselDotSelected
              : AppSizes.homeCarouselDot,
          height: AppSizes.homeCarouselDot,
          margin: EdgeInsetsDirectional.only(
            start: index == 0 ? 0 : AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.berf0.withValues(
              alpha: active ? AppOpacity.opaque : AppOpacity.half,
            ),
            borderRadius: AppRadius.pill,
          ),
        );
      }),
    );
  }
}

class _CampaignFallback extends StatelessWidget {
  const _CampaignFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.petrol800,
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: AppColors.berf100,
          size: AppSizes.iconState,
        ),
      ),
    );
  }
}

class HomeCampaignSkeleton extends StatelessWidget {
  const HomeCampaignSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: AppRatios.widescreen,
      child: AppSkeletonBox(borderRadius: AppRadius.extraLarge),
    );
  }
}
