import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/theme.dart';

/// The root widget for the AIn't Real app.
class AintRealApp extends StatelessWidget {
  const AintRealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "AIn't Real",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
