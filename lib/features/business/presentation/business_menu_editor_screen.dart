import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/presentation/business_labels.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Structured menu for restaurants, cafés and fast food: sections with dishes
/// (create, edit, reorder, delete, availability). Saved as one replacement.
class BusinessMenuEditorScreen extends ConsumerWidget {
  const BusinessMenuEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final onboarding = ref.watch(directoryOnboardingProvider);
    return switch (onboarding) {
      AsyncData(:final value)
          when value.profile != null && value.profile!.type.isFood =>
        _MenuForm(initial: value.menu),
      AsyncData() => Scaffold(
        appBar: AppBar(title: Text(l10n.businessMenuTile)),
        body: AppEmptyState(
          title: l10n.businessMenuTile,
          message: l10n.businessNeedsProfileFirst,
          icon: Icons.menu_book_outlined,
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(title: Text(l10n.businessMenuTile)),
        body: AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(directoryOnboardingProvider),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: Text(l10n.businessMenuTile)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _MenuForm extends ConsumerStatefulWidget {
  const _MenuForm({required this.initial});

  final List<MenuSectionDraft> initial;

  @override
  ConsumerState<_MenuForm> createState() => _MenuFormState();
}

class _MenuFormState extends ConsumerState<_MenuForm> {
  late final List<MenuSectionDraft> _sections = [...widget.initial];
  bool _saving = false;

  void _move<T>(List<T> list, int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= list.length) return;
    setState(() => list.insert(target, list.removeAt(index)));
  }

  void _updateItems(
    int section,
    List<MenuItemDraft> Function(List<MenuItemDraft>) change,
  ) {
    setState(() {
      _sections[section] = _sections[section].copyWith(
        items: change([..._sections[section].items]),
      );
    });
  }

  Future<void> _editSectionName([int? index]) async {
    final name = await _askText(
      context,
      title: context.l10n.businessMenuSectionName,
      initial: index == null ? '' : _sections[index].name,
    );
    if (name == null) return;
    setState(() {
      if (index == null) {
        _sections.add(MenuSectionDraft(name: name));
      } else {
        _sections[index] = _sections[index].copyWith(name: name);
      }
    });
  }

  Future<void> _deleteSection(int index) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: l10n.businessMenuDeleteSection(name: _sections[index].name),
      actions: <Widget>[
        TextButton(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    );
    if (confirmed ?? false) setState(() => _sections.removeAt(index));
  }

  Future<void> _editItem(int section, [int? index]) async {
    final item = await AppBottomSheet.show<MenuItemDraft>(
      context: context,
      title: context.l10n.businessMenuEditItem,
      child: _ItemForm(
        initial: index == null ? null : _sections[section].items[index],
      ),
    );
    if (item == null) return;
    _updateItems(section, (items) {
      index == null ? items.add(item) : items[index] = item;
      return items;
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(businessRepositoryProvider).saveMenu(_sections);
      ref.invalidate(directoryOnboardingProvider);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.businessSaved,
          variant: AppSnackBarVariant.success,
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessMenuTile),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              if (_sections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(l10n.businessMenuEmpty),
                ),
              for (final (index, section) in _sections.indexed)
                _SectionCard(
                  section: section,
                  onRename: () => _editSectionName(index),
                  onMoveUp: index == 0
                      ? null
                      : () => _move(_sections, index, -1),
                  onMoveDown: index == _sections.length - 1
                      ? null
                      : () => _move(_sections, index, 1),
                  onDelete: () => _deleteSection(index),
                  onAddItem: () => _editItem(index),
                  onEditItem: (item) => _editItem(index, item),
                  onToggleItem: (item, available) => _updateItems(
                    index,
                    (items) => items
                      ..[item] = items[item].copyWith(isAvailable: available),
                  ),
                  onMoveItem: (item, delta) => _updateItems(index, (items) {
                    final target = item + delta;
                    if (target >= 0 && target < items.length) {
                      items.insert(target, items.removeAt(item));
                    }
                    return items;
                  }),
                  onDeleteItem: (item) =>
                      _updateItems(index, (items) => items..removeAt(item)),
                ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: l10n.businessMenuAddSection,
                leading: const Icon(Icons.playlist_add_rounded),
                expand: true,
                onPressed: _editSectionName,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.primary(
                label: l10n.actionSave,
                loading: _saving,
                expand: true,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ItemAction { edit, up, down, delete }

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.onRename,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onAddItem,
    required this.onEditItem,
    required this.onToggleItem,
    required this.onMoveItem,
    required this.onDeleteItem,
  });

  final MenuSectionDraft section;
  final VoidCallback onRename;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;
  final ValueChanged<int> onEditItem;
  final void Function(int item, bool available) onToggleItem;
  final void Function(int item, int delta) onMoveItem;
  final ValueChanged<int> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: onRename,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        section.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.businessMenuMoveUp,
                  icon: const Icon(Icons.arrow_upward_rounded),
                  onPressed: onMoveUp,
                ),
                IconButton(
                  tooltip: l10n.businessMenuMoveDown,
                  icon: const Icon(Icons.arrow_downward_rounded),
                  onPressed: onMoveDown,
                ),
                IconButton(
                  tooltip: l10n.actionDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                ),
              ],
            ),
            for (final (index, item) in section.items.indexed)
              ListTile(
                title: Text(item.name),
                subtitle: Text(
                  <String>[
                    formatMarketplacePrice(
                      Localizations.localeOf(context),
                      item.priceCents,
                      'EUR',
                    ),
                    if (item.isHalal) l10n.businessHalal,
                    if (item.isVegan)
                      l10n.menuFlagVegan
                    else if (item.isVegetarian)
                      l10n.menuFlagVegetarian,
                    if (!item.isAvailable) l10n.businessMenuItemUnavailable,
                  ].join(' · '),
                ),
                leading: Switch(
                  value: item.isAvailable,
                  onChanged: (available) => onToggleItem(index, available),
                ),
                trailing: PopupMenuButton<_ItemAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _ItemAction.edit:
                        onEditItem(index);
                      case _ItemAction.up:
                        onMoveItem(index, -1);
                      case _ItemAction.down:
                        onMoveItem(index, 1);
                      case _ItemAction.delete:
                        onDeleteItem(index);
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<_ItemAction>>[
                    PopupMenuItem(
                      value: _ItemAction.edit,
                      child: Text(l10n.businessMenuEditItem),
                    ),
                    PopupMenuItem(
                      value: _ItemAction.up,
                      enabled: index > 0,
                      child: Text(l10n.businessMenuMoveUp),
                    ),
                    PopupMenuItem(
                      value: _ItemAction.down,
                      enabled: index < section.items.length - 1,
                      child: Text(l10n.businessMenuMoveDown),
                    ),
                    PopupMenuItem(
                      value: _ItemAction.delete,
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                ),
                onTap: () => onEditItem(index),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.businessMenuAddItem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({required this.initial});

  final MenuItemDraft? initial;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _price = TextEditingController(
    text: widget.initial == null
        ? ''
        : (widget.initial!.priceCents / 100).toStringAsFixed(2),
  );
  late bool _available = widget.initial?.isAvailable ?? true;
  late bool _halal = widget.initial?.isHalal ?? false;
  late bool _vegetarian = widget.initial?.isVegetarian ?? false;
  late bool _vegan = widget.initial?.isVegan ?? false;
  String? _nameError;
  String? _priceError;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Accepts "8,50" and "8.50"; the server allows up to 1,000,000 €.
  static int? parsePriceCents(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (value == null || value < 0 || value > 1000000) return null;
    return (value * 100).round();
  }

  void _submit() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final cents = parsePriceCents(_price.text);
    setState(() {
      _nameError = name.isEmpty ? l10n.businessMenuNameRequired : null;
      _priceError = cents == null ? l10n.businessMenuPriceInvalid : null;
    });
    if (name.isEmpty || cents == null) return;
    final description = _description.text.trim();
    Navigator.of(context).pop(
      MenuItemDraft(
        name: name,
        description: description.isEmpty ? null : description,
        priceCents: cents,
        isAvailable: _available,
        isHalal: _halal,
        isVegetarian: _vegetarian || _vegan,
        isVegan: _vegan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: _name,
          label: l10n.businessMenuItemName,
          error: _nameError,
          maxLength: 160,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _description,
          label: l10n.businessMenuItemDescription,
          maxLength: 1000,
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _price,
          label: l10n.businessMenuItemPrice,
          error: _priceError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.businessMenuItemAvailable),
          value: _available,
          onChanged: (value) => setState(() => _available = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.businessHalal),
          value: _halal,
          onChanged: (value) => setState(() => _halal = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.menuFlagVegetarian),
          value: _vegetarian || _vegan,
          onChanged: _vegan
              ? null
              : (value) => setState(() => _vegetarian = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.menuFlagVegan),
          value: _vegan,
          onChanged: (value) => setState(() => _vegan = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.primary(
          label: l10n.actionDone,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextPrompt(title: title, initial: initial),
);

/// Owns its controller so it outlives the dialog's closing animation.
class _TextPrompt extends StatefulWidget {
  const _TextPrompt({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: widget.title,
      content: AppTextField(
        controller: _controller,
        label: widget.title,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}
