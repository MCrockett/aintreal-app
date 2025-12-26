import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aintreal_app/app.dart';
import 'package:aintreal_app/widgets/logo.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AintRealApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the logo widget is shown
    expect(find.byType(Logo), findsOneWidget);
    // Verify the tagline is shown
    expect(find.text('Spot the AI'), findsOneWidget);
  });
}
