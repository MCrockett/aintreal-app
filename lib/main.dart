import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, FlutterError, PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/analytics/analytics_service.dart';
import 'core/audio/sound_service.dart';
import 'core/purchases/purchase_service.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock to portrait mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Firebase (mobile only - web version doesn't need auth)
    if (!kIsWeb) {
      await Firebase.initializeApp();

      // Initialize Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Initialize Analytics
      await AnalyticsService.instance.init();

      // Initialize AdMob
      await AdService.instance.init();

      // Initialize In-App Purchases (after AdService so restore can update it)
      await PurchaseService.instance.init();
    }

    // Initialize sound service
    await SoundService.instance.init();

    runApp(
      const ProviderScope(
        child: AintRealApp(),
      ),
    );
  }, (error, stack) {
    // Catch errors outside of Flutter framework
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}
