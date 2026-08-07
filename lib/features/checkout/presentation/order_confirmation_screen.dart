import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/checkout/domain/checkout.dart';
import 'package:zerin_marketplace/features/checkout/presentation/checkout_copy.dart';
import 'package:zerin_marketplace/features/checkout/presentation/checkout_formatters.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    required this.confirmation,
    required this.copy,
    required this.formatMoney,
    required this.onViewOrder,
    required this.onContinueShopping,
    super.key,
  });

  final CheckoutConfirmation confirmation;
  final OrderConfirmationCopy copy;
  final CheckoutMoneyFormatter formatMoney;
  final VoidCallback onViewOrder;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(copy.title)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.semanticColors.successContainer,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: AppSizes.iconHero,
                        child: Icon(
                          Icons.check_rounded,
                          size: AppSizes.iconState,
                          color: context.semanticColors.onSuccessContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    copy.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    copy.emailNotice,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    child: Padding(
                      padding: AppSpacing.card,
                      child: Column(
                        children: <Widget>[
                          _ConfirmationRow(
                            label: copy.orderNumberLabel(
                              confirmation.orderNumber,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Divider(),
                          ),
                          _ConfirmationRow(
                            label: copy.totalLabel,
                            value: formatMoney(
                              confirmation.totalMinor,
                              confirmation.currencyCode,
                            ),
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: copy.viewOrderLabel,
                    leading: const Icon(Icons.receipt_long_outlined),
                    onPressed: onViewOrder,
                    size: AppButtonSize.large,
                    expand: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.ghost(
                    label: copy.continueShoppingLabel,
                    onPressed: onContinueShopping,
                    expand: true,
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

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.label,
    this.value,
    this.emphasized = false,
  });

  final String label;
  final String? value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized ? textTheme.titleMedium : textTheme.bodyMedium;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        if (value case final value?) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Text(value, style: style),
        ],
      ],
    );
  }
}
