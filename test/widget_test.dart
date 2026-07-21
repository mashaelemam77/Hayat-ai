import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reports_mobile/main.dart';

void main() {
  testWidgets('app starts on welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Emergency Reporting System'), findsOneWidget);
  });
}
