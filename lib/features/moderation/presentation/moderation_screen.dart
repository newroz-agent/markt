import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_models.dart';
import 'package:zerin_marketplace/features/moderation/presentation/controllers/moderation_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentUserIsAdminProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.moderationTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: admin.when(
            loading: () => const _Loading(),
            error: (_, _) =>
                Center(child: Text(context.l10n.moderationLoadFailed)),
            data: (isAdmin) => !isAdmin
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.admin_panel_settings_outlined),
                        Text(context.l10n.moderationAdminRequired),
                      ],
                    ),
                  )
                : _content(context),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final listing = ref.watch(moderationDashboardProvider);
    final docs = ref.watch(sellerVerificationQueueProvider);
    final reports = ref.watch(moderationReportsQueueProvider);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              _tab(
                context.l10n.moderationTabOverview,
                0,
                listing,
                docs,
                reports,
              ),
              _tab(
                context.l10n.moderationTabListings,
                1,
                listing,
                docs,
                reports,
              ),
              _tab(
                context.l10n.moderationTabVerification,
                2,
                listing,
                docs,
                reports,
              ),
              _tab(
                context.l10n.moderationTabReports,
                3,
                listing,
                docs,
                reports,
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: selected,
            children: <Widget>[
              _overview(listing, docs, reports),
              _listings(listing),
              _documents(docs),
              _reports(reports),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(
    String text,
    int index,
    AsyncValue<ModerationDashboard> listing,
    AsyncValue<SellerVerificationQueue> docs,
    AsyncValue<ModerationReportsQueue> reports,
  ) {
    final count = switch (index) {
      1 => listing.valueOrNull?.counts.pending,
      2 => docs.valueOrNull?.pending,
      3 => reports.valueOrNull?.open,
      _ => null,
    };
    return ChoiceChip(
      label: Text(count == null ? text : '$text ($count)'),
      selected: selected == index,
      onSelected: (_) => setState(() => selected = index),
    );
  }

  Widget _overview(
    AsyncValue<ModerationDashboard> listings,
    AsyncValue<SellerVerificationQueue> docs,
    AsyncValue<ModerationReportsQueue> reports,
  ) => ListView(
    padding: const EdgeInsets.all(AppSpacing.md),
    children: <Widget>[
      _overviewCard(
        context.l10n.moderationOverviewPendingListings,
        listings.valueOrNull?.counts.pending ?? 0,
        1,
      ),
      _overviewCard(
        context.l10n.moderationOverviewPendingDocuments,
        docs.valueOrNull?.pending ?? 0,
        2,
      ),
      _overviewCard(
        context.l10n.moderationOverviewOpenReports,
        reports.valueOrNull?.open ?? 0,
        3,
      ),
    ],
  );

  Widget _overviewCard(String title, int count, int tab) => Card(
    child: ListTile(
      title: Text(title),
      trailing: Text('$count'),
      onTap: () => setState(() => selected = tab),
    ),
  );

  Widget _listings(AsyncValue<ModerationDashboard> state) => state.when(
    loading: () => const _Loading(),
    error: (_, _) =>
        Center(child: Text(context.l10n.moderationListingsLoadFailed)),
    data: (dashboard) => RefreshIndicator(
      onRefresh: () => ref.refresh(moderationDashboardProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _CountRow(counts: dashboard.counts),
          if (dashboard.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.moderationListingsEmpty),
              ),
            ),
          ...dashboard.items.map((item) => _ModerationCard(item: item)),
        ],
      ),
    ),
  );

  Widget _documents(AsyncValue<SellerVerificationQueue> state) => state.when(
    loading: () => const _Loading(),
    error: (_, _) =>
        Center(child: Text(context.l10n.moderationDocumentsLoadFailed)),
    data: (queue) => RefreshIndicator(
      onRefresh: () => ref.refresh(sellerVerificationQueueProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          if (queue.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.moderationDocumentsEmpty),
              ),
            ),
          ...queue.items.map(
            (item) => Card(
              child: Padding(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.shopName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_documentKindLabel(context, item.kind)} \u2022 '
                      '${MaterialLocalizations.of(context).formatMediumDate(item.createdAt.toLocal())}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (item.signedUrl case final String url)
                      SizedBox(
                        height: 200,
                        child: item.mimeType.startsWith('image/')
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                              )
                            : Center(
                                child: TextButton.icon(
                                  onPressed: () => _openDocument(context, url),
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: Text(
                                    context.l10n.moderationOpenDocument,
                                  ),
                                ),
                              ),
                      ),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        FilledButton(
                          onPressed: () => _documentAction(
                            item,
                            SellerDocumentDecision.approve,
                          ),
                          child: Text(context.l10n.moderationApprove),
                        ),
                        OutlinedButton(
                          onPressed: () => _documentAction(
                            item,
                            SellerDocumentDecision.reject,
                          ),
                          child: Text(context.l10n.moderationReject),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _documentKindLabel(BuildContext context, String kind) =>
      switch (kind) {
        'identity' => context.l10n.documentKindIdentity,
        'business_registration' =>
          context.l10n.documentKindBusinessRegistration,
        'medical_professional_registration' =>
          context.l10n.moderationDocumentKindMedicalProfessionalRegistration,
        _ => kind,
      };

  Widget _reports(AsyncValue<ModerationReportsQueue> state) => state.when(
    loading: () => const _Loading(),
    error: (_, _) =>
        Center(child: Text(context.l10n.moderationReportsLoadFailed)),
    data: (queue) => RefreshIndicator(
      onRefresh: () => ref.refresh(moderationReportsQueueProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          if (queue.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.moderationReportsEmpty),
              ),
            ),
          ...queue.items.map(
            (item) => Card(
              child: Padding(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${item.targetType}: ${item.title ?? context.l10n.moderationReportTargetUnavailable}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${item.reason} \u2022 '
                      '${MaterialLocalizations.of(context).formatMediumDate(item.createdAt.toLocal())}',
                    ),
                    if (item.targetType == 'message' &&
                        item.messageBody != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(item.messageBody!),
                      ),
                    if (item.details != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(item.details!),
                      ),
                    if (item.shopName != null)
                      Text(
                        context.l10n.moderationReportSeller(
                          shopName: item.shopName!,
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        TextButton(
                          onPressed: () =>
                              _reportAction(item, ReportAction.dismiss),
                          child: Text(context.l10n.moderationReportDismiss),
                        ),
                        if (item.targetType == 'product')
                          FilledButton(
                            onPressed: () => _confirmBlock(item),
                            child: Text(context.l10n.moderationReportBlock),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _documentAction(
    SellerDocumentItem item,
    SellerDocumentDecision decision,
  ) async {
    final note = decision == SellerDocumentDecision.reject
        ? await _reason()
        : null;
    if (decision == SellerDocumentDecision.reject && note == null) {
      return;
    }
    final ok = await ref
        .read(moderationActionProvider.notifier)
        .decideDocument(documentId: item.id, decision: decision, note: note);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? context.l10n.moderationDocumentSaved
                : context.l10n.moderationDocumentFailed,
          ),
        ),
      );
    }
  }

  Future<void> _confirmBlock(ModerationReport report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.moderationBlockConfirmTitle),
        content: Text(
          context.l10n.moderationBlockConfirmBody(
            title: report.title ?? context.l10n.moderationReportFallbackTarget,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.moderationBlockConfirmAction),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _reportAction(report, ReportAction.blockListing);
    }
  }

  Future<void> _reportAction(
    ModerationReport report,
    ReportAction action,
  ) async {
    final ok = await ref
        .read(moderationActionProvider.notifier)
        .decideReport(reportId: report.id, action: action);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? context.l10n.moderationReportResolved
                : context.l10n.moderationReportActionFailed,
          ),
        ),
      );
    }
  }

  Future<String?> _reason() async {
    var value = '';
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.moderationRejectionReasonTitle),
        content: TextField(
          maxLength: 2000,
          maxLines: 4,
          onChanged: (v) => value = v,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: Text(context.l10n.moderationReject),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final opened = await launchUrl(Uri.parse(url));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.moderationDocumentOpenFailed)),
      );
    }
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.counts});
  final ModerationCounts counts;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _CountCard(
          label: context.l10n.moderationPending,
          value: counts.pending,
        ),
      ),
      Expanded(
        child: _CountCard(
          label: context.l10n.moderationApprovedToday,
          value: counts.approvedToday,
        ),
      ),
      Expanded(
        child: _CountCard(
          label: context.l10n.moderationRejectedToday,
          value: counts.rejectedToday,
        ),
      ),
    ],
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ModerationCard extends ConsumerWidget {
  const _ModerationCard({required this.item});
  final ModerationItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (item.imageUrls.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: item.imageUrls
                    .map(
                      (url) => CachedNetworkImage(
                        imageUrl: url,
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                    .toList(),
              ),
            ),
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          Text(
            formatMarketplacePrice(
              context.appLocale,
              item.priceCents,
              item.currency,
            ),
          ),
          Text(
            '${item.sellerName} \u2022 ${item.city} \u2022 ${item.categoryName(context.appLocale.languageCode)}',
          ),
          Text(item.description),
          Row(
            children: <Widget>[
              TextButton(
                key: ValueKey('moderation-reject-${item.id}'),
                onPressed: () => _act(context, ref, ModerationDecision.reject),
                child: Text(context.l10n.moderationReject),
              ),
              FilledButton(
                key: ValueKey('moderation-approve-${item.id}'),
                onPressed: () => _act(context, ref, ModerationDecision.approve),
                child: Text(context.l10n.moderationApprove),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    ModerationDecision decision,
  ) async {
    String? reason;
    if (decision == ModerationDecision.reject) {
      reason = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.moderationReject),
          content: TextField(maxLines: 4, onChanged: (value) => reason = value),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, reason?.trim() ?? ''),
              child: Text(context.l10n.moderationReject),
            ),
          ],
        ),
      );
      if (reason == null || !context.mounted) return;
    }
    await ref
        .read(moderationActionProvider.notifier)
        .decide(productId: item.id, decision: decision, reason: reason);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
