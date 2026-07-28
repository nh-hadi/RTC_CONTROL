import 'package:flutter_test/flutter_test.dart';
import 'package:uirtc/main.dart';

void main() {
  testWidgets('App smoke test - RtcApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const RtcApp());
    expect(find.byType(RtcApp), findsOneWidget);
  });
}
