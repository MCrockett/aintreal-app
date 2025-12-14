import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/audio/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sound service
  await SoundService.instance.init();

  runApp(
    const ProviderScope(
      child: AintRealApp(),
    ),
  );
}
