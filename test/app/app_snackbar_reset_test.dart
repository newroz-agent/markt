import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerin_marketplace/app/app.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';

const _alice = AuthUser(id: 'alice', email: 'alice@example.invalid');
const _bob = AuthUser(id: 'bob', email: 'bob@example.invalid');
const _message = 'Nachricht nur für dieses Konto';

void main() {
  testWidgets('snackbars are cleared on sign-in, account switch and sign-out, '
      'but survive a same-account refresh', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final auth = StreamController<AuthUser?>();
    addTearDown(auth.close);
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => AppSnackBar.show(context, message: _message),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          appRouterProvider.overrideWithValue(router),
          authStateProvider.overrideWith((ref) => auth.stream),
        ],
        child: const ZerinApp(),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> showMessage() async {
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text(_message), findsOneWidget);
    }

    Future<void> emit(AuthUser? user) async {
      auth.add(user);
      await tester.pumpAndSettle();
    }

    await showMessage();
    await emit(_alice);
    expect(find.text(_message), findsNothing, reason: 'sign-in clears');

    await showMessage();
    await emit(_alice);
    expect(
      find.text(_message),
      findsOneWidget,
      reason: 'a refresh of the same account keeps the message',
    );

    await emit(_bob);
    expect(find.text(_message), findsNothing, reason: 'account switch clears');

    await showMessage();
    await emit(null);
    expect(find.text(_message), findsNothing, reason: 'sign-out clears');
  });
}
