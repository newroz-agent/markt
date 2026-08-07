import 'package:flutter/material.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class CategoriesFoundationScreen extends StatelessWidget {
  const CategoriesFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: AppSpacing.page,
            child: AppTextField(
              hint: l10n.categoriesSearchHint,
              prefix: const Icon(Icons.search_rounded),
              readOnly: true,
            ),
          ),
          Expanded(
            child: AppEmptyState(
              title: l10n.foundationPreviewTitle,
              message: l10n.foundationPreviewBody,
              icon: Icons.category_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
