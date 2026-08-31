import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/privacy/domain/data_subject_request.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_overview.dart';
import 'package:zerin_marketplace/features/privacy/presentation/controllers/privacy_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// DSGVO self-service: analytics consent, data export (Art. 15) and account
/// deletion (Art. 17).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSignedIn = ref.watch(authStateProvider).valueOrNull != null;
    final async = ref.watch(privacyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: SafeArea(
        child: switch (async) {
          _ when !isSignedIn => AppEmptyState(
            title: l10n.privacySignedOutTitle,
            message: l10n.privacySignedOutBody,
            icon: Icons.lock_outline_rounded,
          ),
          AsyncError<PrivacyOverview>() => AppErrorState(
            title: l10n.stateErrorTitle,
            message: l10n.stateErrorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(privacyControllerProvider),
          ),
          AsyncData<PrivacyOverview>(:final value) => _PrivacyContent(
            overview: value,
          ),
          _ => const _PrivacySkeleton(),
        },
      ),
    );
  }
}

class _PrivacyContent extends ConsumerWidget {
  const _PrivacyContent({required this.overview});

  final PrivacyOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = overview.settings;
    final consentAt = settings.analyticsConsentAt;

    return Align(
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
            Card(
              child: SwitchListTile.adaptive(
                title: Text(l10n.privacyAnalyticsTitle),
                subtitle: Text(
                  settings.analyticsConsent && consentAt != null
                      ? '${l10n.privacyAnalyticsBody}\n'
                            '${l10n.privacyAnalyticsGrantedAt(date: MaterialLocalizations.of(context).formatFullDate(consentAt))}'
                      : l10n.privacyAnalyticsBody,
                ),
                isThreeLine: settings.analyticsConsent && consentAt != null,
                value: settings.analyticsConsent,
                onChanged: (next) => _setAnalytics(context, ref, granted: next),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.privacyDataSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ExportCard(
              request: overview.latestRequest(DataSubjectRequestKind.export),
            ),
            const SizedBox(height: AppSpacing.md),
            _DeletionCard(
              request: overview.openRequest(DataSubjectRequestKind.deletion),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setAnalytics(
    BuildContext context,
    WidgetRef ref, {
    required bool granted,
  }) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(privacyControllerProvider.notifier)
          .setAnalyticsConsent(granted: granted);
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    }
  }
}

class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard({required this.request});

  final DataSubjectRequest? request;

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = widget.request;
    final isPending = request != null && request.status.isOpen;
    final isReady =
        request != null && request.isDownloadable(DateTime.now().toUtc());
    final isExpired =
        request != null &&
        request.status == DataSubjectRequestStatus.completed &&
        !isReady;

    return _ActionCard(
      icon: Icons.download_outlined,
      title: l10n.privacyExportTitle,
      body: l10n.privacyExportBody,
      status: switch ((isPending, isReady, isExpired)) {
        (true, _, _) => l10n.privacyExportPending,
        (_, true, _) => l10n.privacyExportReady,
        (_, _, true) => l10n.privacyExportExpired,
        _ => null,
      },
      action: isReady
          ? AppButton.secondary(
              label: l10n.privacyExportDownload,
              loading: _busy,
              onPressed: _busy ? null : _download,
              expand: true,
            )
          : AppButton.secondary(
              label: l10n.privacyExportRequest,
              loading: _busy,
              // Disabled while one is running: the RPC would return the same
              // request anyway, so offering the button implies a second export
              // that never happens.
              onPressed: _busy || isPending ? null : _request,
              expand: true,
            ),
    );
  }

  Future<void> _request() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(privacyControllerProvider.notifier).requestDataExport();
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.privacyExportRequested,
          variant: AppSnackBarVariant.success,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    final l10n = context.l10n;
    final request = widget.request;
    if (request == null) return;

    setState(() => _busy = true);
    try {
      final url = await ref
          .read(privacyControllerProvider.notifier)
          .createExportDownloadUrl(request);
      final uri = url == null ? null : Uri.tryParse(url);
      final opened =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        AppSnackBar.show(
          context,
          message: l10n.privacyExportExpired,
          variant: AppSnackBarVariant.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DeletionCard extends ConsumerStatefulWidget {
  const _DeletionCard({required this.request});

  /// The open deletion request, if the user has one.
  final DataSubjectRequest? request;

  @override
  ConsumerState<_DeletionCard> createState() => _DeletionCardState();
}

class _DeletionCardState extends ConsumerState<_DeletionCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = widget.request;
    final canCancel = request?.status.isCancellable ?? false;

    return _ActionCard(
      icon: Icons.delete_outline_rounded,
      title: l10n.privacyDeleteTitle,
      body: l10n.privacyDeleteBody,
      status: switch (request) {
        null => null,
        _ when canCancel => l10n.privacyDeletePending,
        _ => l10n.privacyDeleteProcessing,
      },
      action: canCancel
          ? AppButton.secondary(
              label: l10n.privacyDeleteCancel,
              loading: _busy,
              onPressed: _busy ? null : _cancel,
              expand: true,
            )
          : AppButton.destructive(
              label: l10n.privacyDeleteTitle,
              loading: _busy,
              onPressed: _busy || request != null ? null : _confirmAndRequest,
              expand: true,
            ),
    );
  }

  Future<void> _confirmAndRequest() async {
    final l10n = context.l10n;
    final confirmed = await _showConfirmationDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(privacyControllerProvider.notifier)
          .requestAccountDeletion();
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.privacyDeleteRequested,
          variant: AppSnackBarVariant.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final cancelled = await ref
          .read(privacyControllerProvider.notifier)
          .cancelAccountDeletion();
      if (mounted) {
        AppSnackBar.show(
          context,
          message: cancelled
              ? l10n.privacyDeleteCancelled
              : l10n.privacyDeleteCancelFailed,
          variant: cancelled
              ? AppSnackBarVariant.success
              : AppSnackBarVariant.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Asks the user to type the confirmation word before deleting.
///
/// The word is compared verbatim in SQL, so it is shown untranslated and
/// matched case-insensitively here — the RPC upper-cases before comparing.
Future<bool> _showConfirmationDialog(BuildContext context) async {
  final l10n = context.l10n;
  final controller = TextEditingController();

  try {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: l10n.privacyDeleteConfirmTitle,
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      content: _ConfirmationField(
        controller: controller,
        prompt: l10n.privacyDeleteConfirmBody(word: deletionConfirmationWord),
        label: l10n.privacyDeleteConfirmLabel,
      ),
      actions: <Widget>[
        AppButton.ghost(
          label: l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ConfirmButton(controller: controller, label: l10n.actionDelete),
      ],
    );
    return confirmed ?? false;
  } finally {
    controller.dispose();
  }
}

class _ConfirmationField extends StatelessWidget {
  const _ConfirmationField({
    required this.controller,
    required this.prompt,
    required this.label,
  });

  final TextEditingController controller;
  final String prompt;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(prompt),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: controller,
          label: label,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }
}

/// Enables only once the typed text matches the confirmation word.
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final matches =
            value.text.trim().toUpperCase() == deletionConfirmationWord;
        return AppButton.destructive(
          label: label,
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    this.status,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? status;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final status = this.status;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (status != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                status,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: semantic.info,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            action,
          ],
        ),
      ),
    );
  }
}

class _PrivacySkeleton extends StatelessWidget {
  const _PrivacySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const <Widget>[
        AppSkeletonBox(height: AppSizes.controlLarge),
        SizedBox(height: AppSpacing.lg),
        AppSkeletonBox(height: AppSizes.onboardingVisual),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBox(height: AppSizes.onboardingVisual),
      ],
    );
  }
}
