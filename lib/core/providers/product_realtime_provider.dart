import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';

final productRealtimeChangesProvider = StreamProvider<int>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream<int>.value(0);

  late final StreamController<int> controller;
  RealtimeChannel? channel;
  var revision = 0;
  controller = StreamController<int>(
    onListen: () {
      channel = client
          .channel('products-${DateTime.now().microsecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            callback: (_) => controller.add(++revision),
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              controller.add(revision);
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              controller.addError(
                AppException(AppFailureCode.network, cause: error),
              );
            }
          });
    },
    onCancel: () async {
      if (channel != null) await client.removeChannel(channel!);
    },
  );
  return controller.stream;
});
