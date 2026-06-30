import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('tool console renders core panes', (tester) async {
    await tester.pumpWidget(const AgentToolApp());
    await tester.pumpAndSettle();

    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
  });
}
