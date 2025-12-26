import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/audio/sound_service.dart';
import 'core/notifications/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (mobile only - web version doesn't need auth)
  if (!kIsWeb) {
    await Firebase.initializeApp();

    // Initialize push notifications after Firebase
    await PushNotificationService.instance.init();

    // Initialize AdMob
    await AdService.instance.init();
  }

  // Initialize sound service
  await SoundService.instance.init();

  runApp(
    const ProviderScope(
      child: AintRealApp(),
    ),
  );
}
