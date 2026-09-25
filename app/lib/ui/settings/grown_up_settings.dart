import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import '../design/nova_design.dart';
import '../game/stage3d/stage_capability.dart';
import '../l10n.dart';
import '../theme/labels.dart';
import 'capabilities.dart';

/// Called when a grown-up switches on the microphone or camera: asks the
/// device for permission (through the adapter that will use it) and checks
/// that the feature can really run on this device. Returns whether it can.
final permissionRequestProvider = Provider<Future<bool> Function(String what)>((ref) => (what) async {
      if (what == 'microphone') return ref.read(voiceInputProvider).prepare(language: ref.read(languageProvider));
      final face = ref.read(faceSensorProvider);
      final ok = await face.start();
      await face.stop();
      return ok;
    });

/// Settings only a grown-up changes: spoken instructions, microphone,
/// camera, and graphics quality (shared with the 3D stage).
class GrownUpSettings extends ConsumerWidget {
  const GrownUpSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final setting = ref.watch(graphicsSettingProvider);

    Future<void> toggle(StateProvider<bool> provider, bool on, String what) async {
      if (!on) {
        ref.read(provider.notifier).state = false;
        return;
      }
      final granted = await ref.read(permissionRequestProvider)(what);
      if (!granted) {
        if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l10n.permissionDenied)));
        return;
      }
      ref.read(provider.notifier).state = true;
    }

    Widget toggleRow(IconData icon, String title, String description, bool value, ValueChanged<bool>? onChanged) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(onChanged == null ? '$description ${l10n.notOnThisDevice}' : description),
          value: value,
          onChanged: onChanged,
        );

    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(l10n.settingsTitle, style: theme.textTheme.titleLarge)),
          const SizedBox(height: NovaSpace.xs),
          toggleRow(Icons.record_voice_over_rounded, l10n.spokenPrompts, l10n.spokenPromptsDesc, ref.watch(speechEnabledProvider),
              (on) => ref.read(speechEnabledProvider.notifier).state = on),
          toggleRow(Icons.mic_rounded, l10n.voiceAnswers, l10n.voiceAnswersDesc, ref.watch(voiceAnswersProvider) && voiceAnswersSupported,
              voiceAnswersSupported ? (on) => toggle(voiceAnswersProvider, on, 'microphone') : null),
          toggleRow(Icons.face_retouching_natural_rounded, l10n.cameraPlay, l10n.cameraPlayDesc, ref.watch(cameraPlayProvider) && facePlaySupported,
              facePlaySupported ? (on) => toggle(cameraPlayProvider, on, 'camera') : null),
          const SizedBox(height: NovaSpace.sm),
          Text(l10n.graphicsQuality, style: theme.textTheme.titleMedium),
          const SizedBox(height: NovaSpace.xs),
          Wrap(
            spacing: NovaSpace.xs,
            runSpacing: NovaSpace.xs,
            children: [
              for (final q in GraphicsQualitySetting.values)
                ChoiceChip(
                  label: Text(graphicsSettingLabel(context, q)),
                  selected: setting == q,
                  onSelected: (_) => ref.read(graphicsSettingProvider.notifier).state = q,
                ),
            ],
          ),
          const SizedBox(height: NovaSpace.xs),
          Text(graphicsSettingHelp(context, setting), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
