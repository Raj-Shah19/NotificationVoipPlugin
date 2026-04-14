import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import 'app/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationVoipPlugin.init(
    const NvpConfig(
      appName: 'NVP Example',
      channelId: 'nvp_demo',
      channelName: 'NVP Demo Channel',
    ),
  );
  runApp(const NvpExampleApp());
}

class NvpExampleApp extends StatelessWidget {
  const NvpExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NVP v2 Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
