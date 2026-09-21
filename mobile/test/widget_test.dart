import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('BharatLedger Pro App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatLedgerApp());
    expect(find.byType(BharatLedgerApp), findsOneWidget);

    // Allow splash transition timer to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
