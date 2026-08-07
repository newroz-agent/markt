import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/app/app.dart';
import 'package:zerin_marketplace/core/config/app_environment.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  SupabaseClient? supabaseClient;

  if (AppEnvironment.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: kDebugMode,
    );
    supabaseClient = Supabase.instance.client;
  }

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
      child: const ZerinApp(),
    ),
  );
}
