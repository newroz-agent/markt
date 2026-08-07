import 'package:flutter/material.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.document, super.key});

  final String document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, icon) = switch (document) {
      LegalDocumentSlugs.imprint => (
        l10n.legalImprint,
        Icons.business_outlined,
      ),
      LegalDocumentSlugs.terms => (l10n.legalTerms, Icons.description_outlined),
      LegalDocumentSlugs.privacy => (l10n.legalPrivacy, Icons.shield_outlined),
      LegalDocumentSlugs.withdrawal => (
        l10n.legalWithdrawal,
        Icons.assignment_return_outlined,
      ),
      _ => (l10n.accountLegal, Icons.gavel_outlined),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        title: title,
        message: l10n.legalComingSoonBody,
        icon: icon,
      ),
    );
  }
}
