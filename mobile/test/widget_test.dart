import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('DischargeIQ app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DischargeIQApp());

    expect(find.text('DischargeIQ'), findsWidgets);
  });
}