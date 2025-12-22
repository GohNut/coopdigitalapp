import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'package:coop_digital_app/core/router/router_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/domain/user_role.dart';
import 'package:camera/camera.dart';
import 'core/providers/camera_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coop_digital_app/services/dynamic_deposit_api.dart';
import 'core/providers/token_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  
  // Load saved user session
  await CurrentUser.loadUser();
  
  // Initialize Cameras
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Failed to initialize cameras: $e');
  }

  // Create ProviderContainer early to use in SSO check
  final container = ProviderContainer(
    overrides: [
      cameraProvider.overrideWithValue(cameras),
    ],
  );

  // เช็ค Token จาก URL (Handoff สำหรับ Hybrid WebView) - แค่เก็บไว้สำหรับปุ่มกดย้อนกลับ
  final uri = Uri.base;
  final token = TokenNotifier.extractTokenFromUri(uri);
  if (token != null && token.isNotEmpty) {
    debugPrint('Found iLife token in URL: $token');
    // บันทึก token ลงในระบบผ่าน Provider
    await container.read(tokenProvider.notifier).setToken(token);
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const CoopDigitalApp(),
  ));
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
