import 'package:flutter_test/flutter_test.dart';
import 'package:classpulse/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ClassPulseApp());
    expect(find.text('ClassPulse'), findsOneWidget);
  });
}
