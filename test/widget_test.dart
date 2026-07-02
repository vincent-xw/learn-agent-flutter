import 'package:flutter_test/flutter_test.dart';

import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('generated widget test uses project app shell', (tester) async {
    await tester.pumpWidget(const AgentToolApp());
    await tester.pumpAndSettle();

    expect(find.text('Agent Tool Runtime Playground'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
  });
}
