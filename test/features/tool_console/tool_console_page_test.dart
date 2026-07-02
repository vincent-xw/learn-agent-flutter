import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('tool console renders protocol demo entry', (tester) async {
    await tester.pumpWidget(const AgentToolApp());
    await tester.pumpAndSettle();

    expect(find.text('Protocol Demo'), findsOneWidget);
  });
}
