import 'package:flutter_test/flutter_test.dart';
import 'package:ui/main.dart';

void main() {
  testWidgets('Home screen renders title, upload area, and run button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Before You Invest\nLet\'s See If It Holds Up'), findsOneWidget);
    expect(find.text('Upload CSV / XLSX'), findsOneWidget);
    expect(find.text('Run Stress Test'), findsOneWidget);
  });
}
