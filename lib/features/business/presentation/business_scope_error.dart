import 'package:flutter/material.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Fails closed when an owner route has no canonical business seller UUID.
/// It never falls back to an active/local identity or calls an unscoped RPC.
class BusinessScopeErrorScreen extends StatelessWidget {
  const BusinessScopeErrorScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: AppErrorState(
      title: context.l10n.stateErrorTitle,
      message: context.l10n.stateErrorMessage,
    ),
  );
}
