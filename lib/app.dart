import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'core/notifications/push_notification_service.dart';

/// The root widget for the AIn't Real app.
class AintRealApp extends ConsumerStatefulWidget {
  const AintRealApp({super.key});

  /// Maximum width for the app content on larger screens.
  /// This keeps the mobile-first design looking good on desktop.
  static const double maxContentWidth = 500;

  @override
  ConsumerState<AintRealApp> createState() => _AintRealAppState();
}

class _AintRealAppState extends ConsumerState<AintRealApp> {
  @override
  void initState() {
    super.initState();

    // Set up notification tap handler (mobile only)
    if (!kIsWeb) {
      PushNotificationService.instance.onNotificationTap = _handleNotificationTap;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle notification data - navigate to game if gameCode is present
    final gameCode = data['gameCode'] as String?;
    if (gameCode != null && gameCode.isNotEmpty) {
      // Navigate to join screen with the game code
      final router = ref.read(routerProvider);
      router.go('/join/$gameCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: "AIn't Real",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        // Constrain width on larger screens (web/desktop)
        return Container(
          color: AppTheme.backgroundDark,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AintRealApp.maxContentWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
