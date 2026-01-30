import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aintreal_app/app.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/widgets/logo.dart';

void main() {
  setUp(() {
    // Set up mock SharedPreferences with a guest name
    SharedPreferences.setMockInitialValues({'guest_name': 'TestPlayer'});
  });

  testWidgets('App renders home screen', (WidgetTester tester) async {
    // Set a larger screen size to avoid overflow errors
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth service to null to prevent Firebase access
          authServiceProvider.overrideWithValue(null),
        ],
        child: const AintRealApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the logo widget is shown
    expect(find.byType(Logo), findsOneWidget);
    // Verify the tagline is shown
    expect(find.text('Spot the AI'), findsOneWidget);
  });
}
