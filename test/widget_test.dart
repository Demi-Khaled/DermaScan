import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dermascann_ai/main.dart';
import 'package:dermascann_ai/services/ai_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AiService>(create: (_) => AiService()),
        ],
        child: const DermaScannApp(hasSeenOnboarding: false),
      ),
    );

    // Verify that the app builds.
    expect(find.byType(DermaScannApp), findsOneWidget);
  });
}
