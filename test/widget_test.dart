import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:money_saver/app.dart';

void main() {
  testWidgets('Home screen renders welcome message', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneySaverApp()));
    await tester.pumpAndSettle();

    expect(find.text('Money Saver'), findsOneWidget);
    expect(find.textContaining('Welcome'), findsOneWidget);
  });
}
