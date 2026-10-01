import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// Circular avatar with cached delivery, explicit loading, and a resilient
/// personal/store fallback when no URL exists or image delivery fails.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.avatarUrl,
    required this.radius,
    this.isBusiness = false,
    this.semanticLabel,
    super.key,
  });

  final String? avatarUrl;
  final double radius;
  final bool isBusiness;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = avatarUrl?.trim();
    final dimension = radius * 2;

    Widget fallback() => ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Icon(
          isBusiness ? Icons.storefront_rounded : Icons.person_rounded,
          size: radius,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );

    final avatar = SizedBox.square(
      dimension: dimension,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? fallback()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(
                  color: scheme.primaryContainer,
                  child: Center(
                    child: SizedBox.square(
                      dimension: AppSizes.iconMedium,
                      child: CircularProgressIndicator(
                        strokeWidth: AppStrokes.progress,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => fallback(),
              ),
      ),
    );
    if (semanticLabel == null) return avatar;
    return Semantics(image: true, label: semanticLabel, child: avatar);
  }
}
