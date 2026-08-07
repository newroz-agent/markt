import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// Consistent dialog frame for confirmations and focused tasks.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    this.content,
    this.icon,
    this.actions = const <Widget>[],
    this.semanticLabel,
    super.key,
  });

  final String title;
  final Widget? content;
  final Widget? icon;
  final List<Widget> actions;
  final String? semanticLabel;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? content,
    Widget? icon,
    List<Widget> actions = const <Widget>[],
    String? semanticLabel,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (_) => AppDialog(
        title: title,
        content: content,
        icon: icon,
        actions: actions,
        semanticLabel: semanticLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticLabel ?? title,
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  icon!,
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(title, style: theme.textTheme.titleLarge),
                if (content != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  DefaultTextStyle(
                    style:
                        theme.dialogTheme.contentTextStyle ??
                        theme.textTheme.bodyMedium!,
                    child: content!,
                  ),
                ],
                if (actions.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  Widget? content,
  Widget? icon,
  List<Widget> actions = const <Widget>[],
  String? semanticLabel,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return AppDialog.show<T>(
    context: context,
    title: title,
    content: content,
    icon: icon,
    actions: actions,
    semanticLabel: semanticLabel,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
  );
}
