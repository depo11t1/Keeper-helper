import 'package:flutter_test/flutter_test.dart';
import 'package:keeper/main.dart';

void main() {
  testWidgets('Keeper home screen renders spiders', (WidgetTester tester) async {
    await tester.pumpWidget(const KeeperApp());
    await tester.pumpAndSettle();

    expect(find.text('Keeper'), findsOneWidget);
    expect(find.text('Тора'), findsOneWidget);
    expect(find.text('Мока'), findsOneWidget);
  });
}
