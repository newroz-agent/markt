import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';
import 'package:zerin_marketplace/features/business/presentation/business_hub_screen.dart';
import 'package:zerin_marketplace/features/business/presentation/business_labels.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Verification documents: the type decides exactly which documents are
/// needed; each shows its review status and any rejection note.
class BusinessDocumentsScreen extends ConsumerWidget {
  const BusinessDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final onboarding = ref.watch(directoryOnboardingProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessDocumentsTile)),
      body: switch (onboarding) {
        AsyncData(:final value)
            when value.seller != null && value.directoryType != null =>
          _DocumentsBody(onboarding: value),
        AsyncData() => AppEmptyState(
          title: l10n.businessStartTitle,
          message: l10n.businessStartBody,
          icon: Icons.storefront_outlined,
        ),
        AsyncError() => AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(directoryOnboardingProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DocumentsBody extends ConsumerStatefulWidget {
  const _DocumentsBody({required this.onboarding});

  final DirectoryOnboarding onboarding;

  @override
  ConsumerState<_DocumentsBody> createState() => _DocumentsBodyState();
}

class _DocumentsBodyState extends ConsumerState<_DocumentsBody> {
  bool _changingType = false;

  Future<void> _changeType(DirectoryType type) async {
    if (type == widget.onboarding.directoryType) return;
    setState(() => _changingType = true);
    try {
      await ref.read(businessRepositoryProvider).setDirectoryType(type);
      ref.invalidate(directoryOnboardingProvider);
    } on Exception catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(context.l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _changingType = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final onboarding = widget.onboarding;
    final type = onboarding.directoryType!;
    final typeLocked = onboarding.profile != null;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(directoryOnboardingProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              Text(l10n.businessTypeLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              DirectoryTypeChoice(
                selected: type,
                enabled: !typeLocked && !_changingType,
                onSelected: _changeType,
              ),
              if (typeLocked) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.businessTypeLockedHint,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(l10n.businessDocumentsIntro(type: type.label(l10n))),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.businessDocumentsFormats,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final kind in onboarding.requiredDocumentKinds) ...<Widget>[
                _DocumentCard(
                  sellerId: onboarding.seller!.id,
                  kind: kind,
                  document: onboarding.latestDocument(kind),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _UploadSource { camera, gallery, pdf }

class _DocumentCard extends ConsumerStatefulWidget {
  const _DocumentCard({
    required this.sellerId,
    required this.kind,
    required this.document,
  });

  final String sellerId;
  final SellerDocumentKind kind;
  final SellerDocument? document;

  @override
  ConsumerState<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends ConsumerState<_DocumentCard> {
  bool _busy = false;

  Future<void> _upload() async {
    final l10n = context.l10n;
    final source = await AppBottomSheet.show<_UploadSource>(
      context: context,
      title: widget.kind.label(l10n),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final (source, icon, label)
              in <(_UploadSource, IconData, String)>[
                (
                  _UploadSource.camera,
                  Icons.photo_camera_outlined,
                  l10n.documentSourceCamera,
                ),
                (
                  _UploadSource.gallery,
                  Icons.photo_library_outlined,
                  l10n.documentSourceGallery,
                ),
                (
                  _UploadSource.pdf,
                  Icons.picture_as_pdf_outlined,
                  l10n.documentSourcePdf,
                ),
              ])
            Builder(
              builder: (sheetContext) => ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop(source),
              ),
            ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    final files = ref.read(documentFileServiceProvider);
    setState(() => _busy = true);
    try {
      final file = switch (source) {
        _UploadSource.camera => await files.takePhoto(),
        _UploadSource.gallery => await files.pickImage(),
        _UploadSource.pdf => await files.pickPdf(),
      };
      if (file == null) return;
      await ref
          .read(businessRepositoryProvider)
          .uploadDocument(
            sellerId: widget.sellerId,
            kind: widget.kind,
            file: file,
          );
      ref.invalidate(directoryOnboardingProvider);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.documentUploaded,
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(SellerDocument document) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(businessRepositoryProvider).withdrawDocument(document);
      ref.invalidate(directoryOnboardingProvider);
      if (mounted) {
        AppSnackBar.show(context, message: l10n.documentWithdrawn);
      }
    } on BusinessException catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final document = widget.document;
    final status = document?.status;
    final (statusLabel, statusIcon, statusColor) = switch (status) {
      null => (
        l10n.documentStatusMissing,
        Icons.upload_file_rounded,
        theme.colorScheme.outline,
      ),
      SellerDocumentStatus.pending => (
        l10n.documentStatusPending,
        Icons.hourglass_top_rounded,
        theme.colorScheme.tertiary,
      ),
      SellerDocumentStatus.approved => (
        l10n.documentStatusApproved,
        Icons.check_circle_rounded,
        theme.colorScheme.primary,
      ),
      SellerDocumentStatus.rejected => (
        l10n.documentStatusRejected,
        Icons.cancel_rounded,
        theme.colorScheme.error,
      ),
    };
    final adminNote = document?.adminNote;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(widget.kind.icon),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.kind.label(l10n),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.kind.hint(l10n),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  avatar: Icon(
                    statusIcon,
                    size: AppSizes.iconSmall,
                    color: statusColor,
                  ),
                  label: Text(statusLabel),
                ),
                if (document != null)
                  Text(
                    l10n.documentUploadedAt(
                      date: MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(document.createdAt.toLocal()),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            if (status == SellerDocumentStatus.rejected &&
                adminNote != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: AppRadius.medium,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    l10n.documentRejectionNote(note: adminNote),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
            if (status != SellerDocumentStatus.approved) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: status == SellerDocumentStatus.pending
                    ? AppButton.ghost(
                        label: l10n.documentWithdrawAction,
                        loading: _busy,
                        onPressed: _busy ? null : () => _withdraw(document!),
                      )
                    : AppButton.secondary(
                        label: status == SellerDocumentStatus.rejected
                            ? l10n.documentReuploadAction
                            : l10n.documentUploadAction,
                        leading: const Icon(Icons.upload_rounded),
                        loading: _busy,
                        onPressed: _busy ? null : _upload,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
