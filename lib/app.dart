import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

/// The root widget for the AIn't Real app.
class AintRealApp extends ConsumerWidget {
  const AintRealApp({super.key});

  /// Maximum width for the app content on larger screens.
  /// This keeps the mobile-first design looking good on desktop.
  static const double maxContentWidth = 500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
