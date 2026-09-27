import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/presentation/business_labels.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Weekly opening hours with several intervals per day. A closing time
/// before the opening time runs past midnight (Europe/Berlin on the server).
class BusinessHoursEditorScreen extends ConsumerWidget {
  const BusinessHoursEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final onboarding = ref.watch(directoryOnboardingProvider);
    return switch (onboarding) {
      AsyncData(:final value) when value.profile != null => _HoursForm(
        initial: value.hours,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(title: Text(l10n.businessHoursTile)),
        body: AppEmptyState(
          title: l10n.businessHoursTile,
          message: l10n.businessNeedsProfileFirst,
          icon: Icons.schedule_rounded,
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(title: Text(l10n.businessHoursTile)),
        body: AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(directoryOnboardingProvider),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: Text(l10n.businessHoursTile)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _HoursForm extends ConsumerStatefulWidget {
  const _HoursForm({required this.initial});

  final List<OpeningInterval> initial;

  @override
  ConsumerState<_HoursForm> createState() => _HoursFormState();
}

class _HoursFormState extends ConsumerState<_HoursForm> {
  static const _maxPerDay = 6;

  late final Map<int, List<OpeningInterval>> _days = {
    for (final weekday in displayWeekdays)
      weekday: widget.initial
          .where((interval) => interval.weekday == weekday)
          .toList(),
  };
  bool _saving = false;

  Future<void> _addInterval(int weekday) async {
    final l10n = context.l10n;
    if (_days[weekday]!.length >= _maxPerDay) {
      AppSnackBar.show(
        context,
        message: l10n.businessHoursTooMany,
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    final opens = await _pickTime(
      l10n.businessHoursPickOpen,
      const TimeOfDay(hour: 11, minute: 0),
    );
    if (opens == null || !mounted) return;
    final closes = await _pickTime(
      l10n.businessHoursPickClose,
      const TimeOfDay(hour: 22, minute: 0),
    );
    if (closes == null || !mounted) return;
    final interval = OpeningInterval(
      weekday: weekday,
      opensAt: DirectoryTime(opens.hour * 60 + opens.minute),
      // Midnight as a closing time means the end of the day.
      closesAt: DirectoryTime(
        closes.hour == 0 && closes.minute == 0
            ? 24 * 60
            : closes.hour * 60 + closes.minute,
      ),
    );
    if (interval.opensAt == interval.closesAt) {
      AppSnackBar.show(
        context,
        message: l10n.businessHoursSameTime,
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    setState(() {
      final day = _days[weekday]!;
      if (!day.contains(interval)) day.add(interval);
      day.sort((a, b) => a.opensAt.compareTo(b.opensAt));
    });
  }

  Future<TimeOfDay?> _pickTime(String title, TimeOfDay initial) =>
      showTimePicker(
        context: context,
        initialTime: initial,
        helpText: title,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(businessRepositoryProvider).saveHours([
        for (final weekday in displayWeekdays) ..._days[weekday]!,
      ]);
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

  String _intervalLabel(OpeningInterval interval) {
    final l10n = context.l10n;
    final opens = formatDirectoryTime(context, interval.opensAt);
    final closes = formatDirectoryTime(context, interval.closesAt);
    return interval.isOvernight
        ? l10n.businessHoursOvernight(opens: opens, closes: closes)
        : l10n.businessHoursInterval(opens: opens, closes: closes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessHoursTile),
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
              Text(l10n.businessHoursHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final weekday in displayWeekdays)
                _WeekdayCard(
                  label: weekdayLabel(l10n, weekday),
                  intervals: _days[weekday]!,
                  intervalLabel: _intervalLabel,
                  onAdd: () => _addInterval(weekday),
                  onRemove: (interval) =>
                      setState(() => _days[weekday]!.remove(interval)),
                ),
              const SizedBox(height: AppSpacing.lg),
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

/// One weekday: name and add button on top, slots below at full width so an
/// overnight label such as "12:00 – 02:00 (nächster Tag)" never truncates.
class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({
    required this.label,
    required this.intervals,
    required this.intervalLabel,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<OpeningInterval> intervals;
  final String Function(OpeningInterval) intervalLabel;
  final VoidCallback onAdd;
  final ValueChanged<OpeningInterval> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxs,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: l10n.businessHoursAdd,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: onAdd,
                ),
              ],
            ),
            if (intervals.isEmpty)
              Text(
                l10n.businessHoursClosed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final interval in intervals)
                    InputChip(
                      label: Text(intervalLabel(interval)),
                      deleteButtonTooltipMessage: l10n.businessHoursRemove,
                      onDeleted: () => onRemove(interval),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
