import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aintreal_app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AintRealApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the app title is shown
    expect(find.text("n't Real"), findsOneWidget);
    expect(find.text('Spot the AI'), findsOneWidget);
  });
}
