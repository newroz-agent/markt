import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/checkout/domain/checkout.dart';
import 'package:zerin_marketplace/features/checkout/presentation/checkout_copy.dart';
import 'package:zerin_marketplace/features/checkout/presentation/checkout_formatters.dart';

typedef ShippingSelectionCallback =
    void Function(String sellerId, String shippingOptionId);

sealed class CheckoutViewState {
  const CheckoutViewState();
}

final class CheckoutLoading extends CheckoutViewState {
  const CheckoutLoading();
}

final class CheckoutFailure extends CheckoutViewState {
  const CheckoutFailure({this.message});

  final String? message;
}

final class CheckoutOffline extends CheckoutViewState {
  const CheckoutOffline();
}

final class CheckoutReady extends CheckoutViewState {
  const CheckoutReady({required this.session, this.isSubmitting = false});

  final CheckoutSession session;
  final bool isSubmitting;
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    required this.state,
    required this.copy,
    required this.formatMoney,
    required this.onChooseAddress,
    required this.onShippingSelected,
    required this.onPaymentSelected,
    required this.onSubmit,
    this.onRetry,
    super.key,
  });

  final CheckoutViewState state;
  final CheckoutCopy copy;
  final CheckoutMoneyFormatter formatMoney;
  final VoidCallback onChooseAddress;
  final ShippingSelectionCallback onShippingSelected;
  final ValueChanged<CheckoutPaymentKind> onPaymentSelected;
  final VoidCallback onSubmit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: switch (state) {
        CheckoutLoading() => _CheckoutSkeleton(label: copy.loadingLabel),
        CheckoutFailure(:final message) => AppErrorState(
          title: copy.errorTitle,
          message: message ?? copy.errorMessage,
          retryLabel: onRetry == null ? null : copy.retryLabel,
          onRetry: onRetry,
        ),
        CheckoutOffline() => AppErrorState(
          title: copy.offlineTitle,
          message: copy.offlineMessage,
          icon: Icons.wifi_off_rounded,
          retryLabel: onRetry == null ? null : copy.retryLabel,
          onRetry: onRetry,
        ),
        CheckoutReady(:final session, :final isSubmitting) => _CheckoutContent(
          session: session,
          copy: copy,
          formatMoney: formatMoney,
          isSubmitting: isSubmitting,
          onChooseAddress: onChooseAddress,
          onShippingSelected: onShippingSelected,
          onPaymentSelected: onPaymentSelected,
          onSubmit: onSubmit,
        ),
      },
    );
  }
}

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({
    required this.session,
    required this.copy,
    required this.formatMoney,
    required this.isSubmitting,
    required this.onChooseAddress,
    required this.onShippingSelected,
    required this.onPaymentSelected,
    required this.onSubmit,
  });

  final CheckoutSession session;
  final CheckoutCopy copy;
  final CheckoutMoneyFormatter formatMoney;
  final bool isSubmitting;
  final VoidCallback onChooseAddress;
  final ShippingSelectionCallback onShippingSelected;
  final ValueChanged<CheckoutPaymentKind> onPaymentSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _AddressSection(
                address: session.deliveryAddress,
                copy: copy,
                onPressed: onChooseAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final group in session.sellerGroups) ...<Widget>[
                _SellerShippingSection(
                  group: group,
                  copy: copy,
                  formatMoney: formatMoney,
                  onSelected: (optionId) {
                    onShippingSelected(group.sellerId, optionId);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _PaymentSection(
                options: session.paymentOptions,
                selectedKind: session.selectedPaymentKind,
                title: copy.paymentMethodsTitle,
                onSelected: onPaymentSelected,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummarySection(
                totals: session.totals,
                copy: copy,
                formatMoney: formatMoney,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                copy.legalNotice,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: copy.placeOrderLabel,
                leading: const Icon(Icons.lock_outline_rounded),
                onPressed: session.canSubmit ? onSubmit : null,
                loading: isSubmitting,
                size: AppButtonSize.large,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.address,
    required this.copy,
    required this.onPressed,
  });

  final CheckoutAddress? address;
  final CheckoutCopy copy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _CheckoutSection(
      title: copy.deliveryAddressTitle,
      trailing: address == null
          ? null
          : AppButton.ghost(
              label: copy.editLabel,
              onPressed: onPressed,
              size: AppButtonSize.small,
            ),
      child: address == null
          ? AppButton.secondary(
              label: copy.chooseAddressLabel,
              leading: const Icon(Icons.add_location_alt_outlined),
              onPressed: onPressed,
              expand: true,
            )
          : _Address(address: address!),
    );
  }
}

class _Address extends StatelessWidget {
  const _Address({required this.address});

  final CheckoutAddress address;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondaryStyle = textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.location_on_outlined),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(address.recipientName, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${address.street} ${address.houseNumber}',
                style: secondaryStyle,
              ),
              if (address.additionalLine case final additionalLine?)
                Text(additionalLine, style: secondaryStyle),
              Text(
                '${address.postalCode} ${address.city}',
                style: secondaryStyle,
              ),
              Text(address.countryName, style: secondaryStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerShippingSection extends StatelessWidget {
  const _SellerShippingSection({
    required this.group,
    required this.copy,
    required this.formatMoney,
    required this.onSelected,
  });

  final CheckoutSellerGroup group;
  final CheckoutCopy copy;
  final CheckoutMoneyFormatter formatMoney;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _CheckoutSection(
      title: group.sellerName,
      child: Column(
        children: <Widget>[
          for (var index = 0; index < group.items.length; index++) ...<Widget>[
            _CheckoutItemRow(
              item: group.items[index],
              quantityLabel: copy.quantityLabel(group.items[index].quantity),
              formattedTotal: formatMoney(
                group.items[index].lineTotalMinor,
                group.items[index].currencyCode,
              ),
            ),
            if (index < group.items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              copy.shippingMethodsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (
            var index = 0;
            index < group.shippingOptions.length;
            index++
          ) ...<Widget>[
            _SelectableOption(
              label: group.shippingOptions[index].label,
              description: _shippingDescription(group.shippingOptions[index]),
              valueLabel: formatMoney(
                group.shippingOptions[index].priceMinor,
                group.shippingOptions[index].currencyCode,
              ),
              icon: Icons.local_shipping_outlined,
              selected:
                  group.shippingOptions[index].id ==
                  group.selectedShippingOptionId,
              enabled: group.shippingOptions[index].enabled,
              onPressed: () => onSelected(group.shippingOptions[index].id),
            ),
            if (index < group.shippingOptions.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  static String? _shippingDescription(CheckoutShippingOption option) {
    final description = option.description;
    final estimate = option.estimatedDelivery;
    if (description == null || description.isEmpty) return estimate;
    if (estimate == null || estimate.isEmpty) return description;
    return '$description\n$estimate';
  }
}

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({
    required this.item,
    required this.quantityLabel,
    required this.formattedTotal,
  });

  final CheckoutLineItem item;
  final String quantityLabel;
  final String formattedTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        _ProductThumbnail(imageUrl: item.imageUrl, semanticLabel: item.title),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                quantityLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(formattedTotal, style: theme.textTheme.labelLarge),
      ],
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.options,
    required this.selectedKind,
    required this.title,
    required this.onSelected,
  });

  final List<CheckoutPaymentOption> options;
  final CheckoutPaymentKind? selectedKind;
  final String title;
  final ValueChanged<CheckoutPaymentKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return _CheckoutSection(
      title: title,
      child: Column(
        children: <Widget>[
          for (var index = 0; index < options.length; index++) ...<Widget>[
            _SelectableOption(
              label: options[index].label,
              description: options[index].description,
              icon: _paymentIcon(options[index].kind),
              selected: options[index].kind == selectedKind,
              enabled: options[index].enabled,
              onPressed: () => onSelected(options[index].kind),
            ),
            if (index < options.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  static IconData _paymentIcon(CheckoutPaymentKind kind) => switch (kind) {
    CheckoutPaymentKind.card => Icons.credit_card_rounded,
    CheckoutPaymentKind.paypal => Icons.account_balance_wallet_outlined,
    CheckoutPaymentKind.klarna => Icons.payments_outlined,
    CheckoutPaymentKind.sepaDebit => Icons.account_balance_outlined,
    CheckoutPaymentKind.applePay => Icons.apple,
    CheckoutPaymentKind.googlePay => Icons.wallet_outlined,
  };
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.totals,
    required this.copy,
    required this.formatMoney,
  });

  final CheckoutTotals totals;
  final CheckoutCopy copy;
  final CheckoutMoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    return _CheckoutSection(
      title: copy.orderSummaryTitle,
      child: Column(
        children: <Widget>[
          _SummaryRow(
            label: copy.subtotalLabel,
            value: formatMoney(totals.subtotalMinor, totals.currencyCode),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            label: copy.shippingLabel,
            value: formatMoney(totals.shippingMinor, totals.currencyCode),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            label: copy.vatLabel,
            value: formatMoney(totals.vatMinor, totals.currencyCode),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          _SummaryRow(
            label: copy.totalLabel,
            value: formatMoney(totals.totalMinor, totals.currencyCode),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized ? textTheme.titleMedium : textTheme.bodyMedium;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: AppSpacing.md),
        Text(value, style: style),
      ],
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectableOption extends StatelessWidget {
  const _SelectableOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.description,
    this.valueLabel,
  });

  final String label;
  final String? description;
  final String? valueLabel;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: AppOpacity.disabledContent);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? AppStrokes.focused : AppStrokes.thin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.controlLarge),
            child: Padding(
              padding: AppSpacing.card,
              child: Row(
                children: <Widget>[
                  Icon(icon, color: foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: foreground,
                          ),
                        ),
                        if (description case final description?) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: enabled
                                  ? scheme.onSurfaceVariant
                                  : foreground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (valueLabel case final valueLabel?) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    Text(valueLabel, style: theme.textTheme.labelLarge),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? scheme.primary : foreground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageUrl,
    required this.semanticLabel,
  });

  final String? imageUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl == null
        ? _fallback(context)
        : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => const AppSkeletonBox(
              animate: false,
              borderRadius: BorderRadius.zero,
            ),
            errorWidget: (_, _, _) => _fallback(context),
          );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: AppRadius.small,
        child: SizedBox.square(dimension: AppSizes.brandIcon, child: image),
      ),
    );
  }

  static Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: context.semanticColors.surfaceMuted,
      child: Icon(
        Icons.inventory_2_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CheckoutSkeleton extends StatelessWidget {
  const _CheckoutSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: AppSkeletonLoader(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const <Widget>[
                AppSkeletonBox(
                  height: AppSizes.stateIllustration,
                  animate: false,
                ),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBox(
                  height: AppSizes.onboardingVisual,
                  animate: false,
                ),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBox(
                  height: AppSizes.stateIllustration * 2,
                  animate: false,
                ),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBox(
                  height: AppSizes.onboardingVisual,
                  animate: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
