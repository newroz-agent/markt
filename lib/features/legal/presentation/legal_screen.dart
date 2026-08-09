import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';
import 'package:zerin_marketplace/features/legal/presentation/controllers/legal_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class LegalScreen extends ConsumerWidget {
  const LegalScreen({required this.document, super.key});

  final String document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = LegalDocumentSlugs.parse(document);
    final (title, icon) = _titleAndIcon(l10n, kind);

    if (kind == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AppEmptyState(
          title: title,
          message: l10n.legalUnknownDocumentBody,
          icon: icon,
        ),
      );
    }

    final localeCode = Localizations.localeOf(context).languageCode;
    final request = legalDocumentProvider(kind: kind, localeCode: localeCode);
    final async = ref.watch(request);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        // `AsyncValue` is not sealed in Riverpod 2, so the wildcard is required
        // rather than optional; it carries the loading case.
        child: switch (async) {
          AsyncError<LegalDocument?>() => AppErrorState(
            title: l10n.legalLoadErrorTitle,
            message: l10n.legalLoadErrorBody,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(request),
          ),
          AsyncData<LegalDocument?>(value: final document?) => _LegalContent(
            document: document,
          ),
          // Loaded, but this locale has no published document yet.
          AsyncData<LegalDocument?>() => AppEmptyState(
            title: title,
            message: l10n.legalComingSoonBody,
            icon: icon,
          ),
          _ => const _LegalSkeleton(),
        },
      ),
    );
  }

  (String, IconData) _titleAndIcon(AppLocalizations l10n, LegalDocumentKind? kind) {
    return switch (kind) {
      LegalDocumentKind.imprint => (l10n.legalImprint, Icons.business_outlined),
      LegalDocumentKind.terms => (
        l10n.legalTerms,
        Icons.description_outlined,
      ),
      LegalDocumentKind.privacy => (l10n.legalPrivacy, Icons.shield_outlined),
      LegalDocumentKind.withdrawal => (
        l10n.legalWithdrawal,
        Icons.assignment_return_outlined,
      ),
      null => (l10n.accountLegal, Icons.gavel_outlined),
    };
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final effective = MaterialLocalizations.of(
      context,
    ).formatFullDate(document.effectiveAt.toLocal());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(document.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.legalVersionLine(
            version: document.version,
            date: effective,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(color: semantic.divider),
        const SizedBox(height: AppSpacing.md),
        AppMarkdown(
          source: document.contentMarkdown,
          onLinkTap: (url) => _openLink(context, url),
        ),
      ],
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    // Only http(s) is followed: legal copy is operator-supplied content, and a
    // mailto: or custom scheme should not be launched without the user asking.
    final launched =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.legalLinkFailed)));
    }
  }
}

class _LegalSkeleton extends StatelessWidget {
  const _LegalSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: AppSizes.skeletonHeadingWidthFactor,
          child: const AppSkeletonBox(),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var line = 0; line < AppSizes.skeletonTextLines; line++) ...[
          const AppSkeletonBox(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
