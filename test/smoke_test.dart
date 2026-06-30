import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('app boots into tool console shell', (tester) async {
    await tester.pumpWidget(const AgentToolApp());
    await tester.pumpAndSettle();

    expect(find.text('Agent Tool Runtime Playground'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
  });
}
