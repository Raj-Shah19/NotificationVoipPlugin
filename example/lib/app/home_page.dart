import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import '../shared/log_controller.dart';
import '../features/permissions/permissions_section.dart';
import '../features/tokens/tokens_section.dart';
import '../features/notifications/notifications_section.dart';
import '../features/badge/badge_section.dart';
import '../features/calls/calls_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LogController _logController = LogController();
  int _selectedTab = 0;

  // Stream subscriptions
  StreamSubscription? _tapSub;
  StreamSubscription? _callSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _tokenSub;

  // Track last call ID for call controls
  String _lastCallId = '';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _tapSub = NotificationVoipPlugin.onNotificationTap.listen((n) {
      _logController.add(
        'notifications',
        'Tapped: ${n.title}',
        Icons.touch_app,
        Colors.blue,
      );
    });
    _callSub = NotificationVoipPlugin.onCallEvent.listen((e) {
      _logController.add(
        'calls',
        'Call: ${e.action} (${e.callId})',
        Icons.phone_callback,
        Colors.green,
      );
    });
    _stateSub = NotificationVoipPlugin.onCallStateChanged.listen((s) {
      _logController.add(
        'calls',
        'State: ${s.status.name} muted=${s.isMuted} speaker=${s.isSpeakerOn}',
        Icons.info_outline,
        Colors.orange,
      );
    });
    _tokenSub = NotificationVoipPlugin.onTokenRefresh.listen((t) {
      _logController.add(
        'tokens',
        'Token refreshed: $t',
        Icons.vpn_key,
        Colors.purple,
      );
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _callSub?.cancel();
    _stateSub?.cancel();
    _tokenSub?.cancel();
    _logController.dispose();
    NotificationVoipPlugin.dispose();
    super.dispose();
  }

  void _setLastCallId(String id) => _lastCallId = id;
  String get lastCallId => _lastCallId;

  @override
  Widget build(BuildContext context) {
    final tabs = <_TabDef>[
      _TabDef(0, 'Permissions', Icons.security),
      _TabDef(1, 'Tokens', Icons.vpn_key),
      _TabDef(2, 'Notifications', Icons.notifications),
      _TabDef(3, 'Badge', Icons.badge),
      _TabDef(4, 'Calls', Icons.call),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('NVP v2 Demo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear all logs',
                onPressed: _logController.clearAll,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: tabs
                    .map((t) => _buildChip(t.index, t.label, t.icon))
                    .toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _buildSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildChip(int index, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FilterChip(
        selected: _selectedTab == index,
        label: Text(label),
        avatar: Icon(icon, size: 18),
        onSelected: (_) => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildSection() {
    switch (_selectedTab) {
      case 0:
        return PermissionsSection(logController: _logController);
      case 1:
        return TokensSection(logController: _logController);
      case 2:
        return NotificationsSection(logController: _logController);
      case 3:
        return BadgeSection(logController: _logController);
      case 4:
        return CallsSection(
          logController: _logController,
          lastCallId: lastCallId,
          onCallIdChanged: _setLastCallId,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TabDef {
  final int index;
  final String label;
  final IconData icon;
  const _TabDef(this.index, this.label, this.icon);
}
