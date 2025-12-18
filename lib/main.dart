import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:coop_digital_app/core/router/router_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/domain/user_role.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  
  // Load saved user session
  await CurrentUser.loadUser();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Initialization Failed: $e');
    // Continue running app even if Firebase fails (for UI/Demo purpose)
  }
  runApp(const ProviderScope(child: CoopDigitalApp()));
}

class CoopDigitalApp extends ConsumerWidget {
  const CoopDigitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Coop Digital',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('th', 'TH'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('th', 'TH'),
      ],
    );
  }
}
