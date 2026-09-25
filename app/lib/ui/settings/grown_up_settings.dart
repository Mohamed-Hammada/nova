import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import '../theme/graphics.dart';
import '../theme/nova_theme.dart';
import '../theme/strings.dart';
import 'capabilities.dart';

/// Called when a grown-up switches on the microphone or camera. Returns
/// whether the device permission was granted. Replaced by the real permission
/// flow in the voice and face adapters; tests leave it granting.
final permissionRequestProvider = Provider<Future<bool> Function(String what)>((ref) => (what) async => true);

/// Settings only a grown-up changes: sound, microphone, camera, graphics.
class GrownUpSettings extends ConsumerWidget {
  const GrownUpSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = UiStrings.of(ref.watch(languageProvider));
    final accent = ref.watch(paletteProvider).accent;
    const ink = Color(0xFF3A2A4A);
    final quality = ref.watch(graphicsProvider);

    Future<void> toggle(StateProvider<bool> provider, bool on, String what) async {
      if (!on) {
        ref.read(provider.notifier).state = false;
        return;
      }
      final granted = await ref.read(permissionRequestProvider)(what);
      if (!granted) {
        if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(s.permissionDenied)));
        return;
      }
      ref.read(provider.notifier).state = true;
    }

    Widget row(IconData icon, String title, String sub, bool value, ValueChanged<bool>? onChanged) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: shade(accent, -0.3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: novaText(18, weight: 800, color: ink)),
                    Text(onChanged == null ? '$sub ${s.notOnThisDevice}' : sub, style: novaText(14, weight: 500, color: ink.withValues(alpha: 0.7), height: 1.25)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged, activeThumbColor: accent),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x332A1640), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.settings, style: novaText(22, weight: 800, color: ink)),
          const SizedBox(height: 6),
          row(Icons.record_voice_over_rounded, s.spokenPrompts, s.spokenPromptsSub, ref.watch(speechEnabledProvider),
              (on) => ref.read(speechEnabledProvider.notifier).state = on),
          row(Icons.mic_rounded, s.voiceAnswers, s.voiceAnswersSub, ref.watch(voiceAnswersProvider) && voiceAnswersSupported,
              voiceAnswersSupported ? (on) => toggle(voiceAnswersProvider, on, 'microphone') : null),
          row(Icons.face_retouching_natural_rounded, s.cameraPlay, s.cameraPlaySub, ref.watch(cameraPlayProvider) && facePlaySupported,
              facePlaySupported ? (on) => toggle(cameraPlayProvider, on, 'camera') : null),
          const SizedBox(height: 10),
          Text(s.graphics, style: novaText(18, weight: 800, color: ink)),
          const SizedBox(height: 8),
          SegmentedButton<GraphicsQuality>(
            segments: [for (final q in GraphicsQuality.values) ButtonSegment(value: q, label: Text(s.graphicsName(q.name), style: novaText(15, weight: 700)))],
            selected: {quality},
            onSelectionChanged: (v) => ref.read(graphicsProvider.notifier).state = v.first,
          ),
          const SizedBox(height: 6),
          Text(s.graphicsHelp(quality.name), style: novaText(14, weight: 500, color: ink.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
