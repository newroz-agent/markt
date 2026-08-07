import 'package:flutter/material.dart';

enum AppChipVariant { filled, outlined }

/// Reusable chip supporting static, selectable, and removable states.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.variant = AppChipVariant.filled,
    this.selected = false,
    this.enabled = true,
    this.leading,
    this.onSelected,
    this.onDeleted,
    this.deleteIcon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final AppChipVariant variant;
  final bool selected;
  final bool enabled;
  final Widget? leading;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final Widget? deleteIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;
    final side = variant == AppChipVariant.outlined
        ? BorderSide(color: theme.colorScheme.outline)
        : BorderSide.none;
    final labelWidget = Text(label);
    final effectiveOnSelected = enabled ? onSelected : null;
    final effectiveOnDeleted = enabled ? onDeleted : null;

    final Widget chip;
    if (onDeleted != null) {
      chip = InputChip(
        label: labelWidget,
        avatar: leading,
        selected: selected,
        isEnabled: enabled,
        onSelected: effectiveOnSelected,
        onDeleted: effectiveOnDeleted,
        deleteIcon: deleteIcon,
        side: side,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );
    } else if (onSelected != null) {
      chip = FilterChip(
        label: labelWidget,
        avatar: leading,
        selected: selected,
        onSelected: effectiveOnSelected,
        side: side,
        showCheckmark: chipTheme.showCheckmark,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );
    } else {
      chip = Chip(
        label: labelWidget,
        avatar: leading,
        side: side,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );
    }

    return Semantics(
      label: semanticLabel ?? label,
      selected: onSelected == null ? null : selected,
      enabled: enabled,
      child: chip,
    );
  }
}
