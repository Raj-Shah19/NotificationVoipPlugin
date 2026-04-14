import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notification_voip_plugin_example/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NvpExampleApp());

    expect(find.text('NVP v2 Example'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text && widget.data!.startsWith('Status:'),
      ),
      findsOneWidget,
    );
  });
}
