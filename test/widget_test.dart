import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_marketplace_app/main.dart';

void main() {
  testWidgets('Splash screen shows brand text', (tester) async {
    await tester.pumpWidget(const PharmacyApp());

    expect(find.text('MEDONE'), findsOneWidget);
  });
}
