import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('init completes without error', (WidgetTester tester) async {
    await NotificationVoipPlugin.init();
    // If we get here, init succeeded
  });
}
