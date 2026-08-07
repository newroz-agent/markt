import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// Tokenized modal-sheet frame with safe-area and keyboard handling.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    this.title,
    this.leading,
    this.trailing,
    this.actions = const <Widget>[],
    this.showDragHandle = true,
    this.scrollable = true,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> actions;
  final bool showDragHandle;
  final bool scrollable;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? leading,
    Widget? trailing,
    List<Widget> actions = const <Widget>[],
    bool showDragHandle = true,
    bool scrollable = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      constraints: const BoxConstraints(maxWidth: AppSizes.bottomSheetMaxWidth),
      builder: (_) => AppBottomSheet(
        title: title,
        leading: leading,
        trailing: trailing,
        actions: actions,
        showDragHandle: showDragHandle,
        scrollable: scrollable,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight =
        mediaQuery.size.height - mediaQuery.padding.top - AppSpacing.lg;
    final body = scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: child,
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: child,
          );

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: AppDurations.standard,
        curve: AppMotion.standardCurve,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: AppRadius.pill,
                    ),
                    child: const SizedBox(
                      width: AppSizes.dragHandleWidth,
                      height: AppSizes.dragHandleHeight,
                    ),
                  ),
                ),
              if (title != null || leading != null || trailing != null)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (leading != null) ...<Widget>[
                        leading!,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        )
                      else
                        const Spacer(),
                      if (trailing != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              Flexible(child: body),
              if (actions.isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.semanticColors.divider),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < actions.length;
                          index++
                        ) ...<Widget>[
                          if (index > 0) const SizedBox(width: AppSpacing.sm),
                          Flexible(child: actions[index]),
                        ],
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  Widget? leading,
  Widget? trailing,
  List<Widget> actions = const <Widget>[],
  bool showDragHandle = true,
  bool scrollable = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  return AppBottomSheet.show<T>(
    context: context,
    child: child,
    title: title,
    leading: leading,
    trailing: trailing,
    actions: actions,
    showDragHandle: showDragHandle,
    scrollable: scrollable,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
  );
}
