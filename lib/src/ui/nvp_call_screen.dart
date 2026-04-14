import 'package:flutter/material.dart';

import '../models/nvp_call_event.dart';
import 'nvp_call_screen_controller.dart';

/// Default Flutter call screen widget.
class NvpCallScreen extends StatefulWidget {
  final NvpCallEvent event;
  final NvpCallScreenController controller;

  const NvpCallScreen({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  State<NvpCallScreen> createState() => _NvpCallScreenState();
}

class _NvpCallScreenState extends State<NvpCallScreen> {
  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final event = widget.event;
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade700,
              child: Text(
                (event.callerName ?? '?')[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              event.callerName ?? 'Unknown',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.isVideo ? 'Video Call' : 'Audio Call',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: ctrl.isMuted ? Icons.mic_off : Icons.mic,
                  label: 'Mute',
                  onPressed: () async {
                    await ctrl.toggleMute();
                    setState(() {});
                  },
                ),
                _ActionButton(
                  icon:
                      ctrl.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  label: 'Speaker',
                  onPressed: () async {
                    await ctrl.toggleSpeaker();
                    setState(() {});
                  },
                ),
                if (event.isVideo)
                  _ActionButton(
                    icon: ctrl.isCameraOn
                        ? Icons.videocam
                        : Icons.videocam_off,
                    label: 'Camera',
                    onPressed: () async {
                      await ctrl.toggleCamera();
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 32),
            if (event.action != NvpCallAction.incoming)
              FloatingActionButton.large(
                heroTag: 'end',
                backgroundColor: Colors.red,
                onPressed: () async {
                  await ctrl.end();
                  if (context.mounted) Navigator.of(context).maybePop();
                },
                child: const Icon(Icons.call_end, color: Colors.white),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'accept',
                    backgroundColor: Colors.green,
                    onPressed: () => ctrl.accept(),
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: 'reject',
                    backgroundColor: Colors.red,
                    onPressed: () async {
                      await ctrl.reject();
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ],
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
