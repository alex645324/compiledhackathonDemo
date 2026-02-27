import 'package:flutter_test/flutter_test.dart';
import 'package:ui/main.dart';

void main() {
  testWidgets('Home screen renders input fields and button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Claim Stress Test'), findsOneWidget);
    expect(find.text('Run Stress Test'), findsOneWidget);
    expect(find.text('Control values'), findsOneWidget);
    expect(find.text('Treatment values'), findsOneWidget);
  });
}
