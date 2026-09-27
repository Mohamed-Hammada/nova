import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_rig.dart';
import '../characters/character_view.dart';
import '../design/nova_design.dart';
import '../game/stage3d/stage_capability.dart';
import '../l10n.dart';
import '../scene/world_backdrop.dart';
import '../theme/age_band.dart';
import '../theme/labels.dart';
import 'grown_up_settings.dart';

/// Settings, one tap from Home (the gear): sound, play, the child, the
/// language and graphics. Every change applies at once and is saved on the
/// device (SettingsSync). Detailed learning evidence stays in Progress.
///
/// Laid out for a grown-up with a child on their lap: big rows, big
/// switches, and nothing that depends on reading direction -- the same
/// screen works in Arabic (right to left) and English.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return NovaPage(
      title: Text(l10n.settingsTitle),
      maxWidth: 760,
      body: ListView(
        key: const ValueKey('settings.list'),
        padding: const EdgeInsets.symmetric(vertical: NovaSpace.lg),
        children: [
          Text(l10n.settingsIntro, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: NovaSpace.md),
          _Section(
            title: l10n.settingsSound,
            icon: Icons.volume_up_rounded,
            children: [
              _Toggle(
                key: const ValueKey('settings.music'),
                icon: Icons.music_note_rounded,
                title: l10n.music,
                description: l10n.musicDesc,
                provider: musicEnabledProvider,
              ),
              _Toggle(
                key: const ValueKey('settings.sfx'),
                icon: Icons.notifications_active_rounded,
                title: l10n.soundEffects,
                description: l10n.soundEffectsDesc,
                provider: soundEffectsEnabledProvider,
              ),
              _Toggle(
                key: const ValueKey('settings.voice'),
                icon: Icons.record_voice_over_rounded,
                title: l10n.voiceNarration,
                description: l10n.spokenPromptsDesc,
                provider: speechEnabledProvider,
              ),
              const _MissingVoice(),
            ],
          ),
          _Section(
            title: l10n.settingsPlay,
            icon: Icons.toys_rounded,
            children: [
              _Toggle(
                key: const ValueKey('settings.hints'),
                icon: Icons.lightbulb_rounded,
                title: l10n.hintButton,
                description: l10n.hintButtonDesc,
                provider: hintsEnabledProvider,
              ),
              _Toggle(
                key: const ValueKey('settings.motion'),
                icon: Icons.slow_motion_video_rounded,
                title: l10n.reducedMotion,
                description: l10n.reducedMotionDesc,
                provider: reducedMotionProvider,
              ),
            ],
          ),
          _Section(
            title: l10n.settingsChild,
            icon: Icons.child_care_rounded,
            children: const [_NameField(), SizedBox(height: NovaSpace.md), AgeSetting(), SizedBox(height: NovaSpace.md), _CompanionPicker(), SizedBox(height: NovaSpace.md), _WorldPicker()],
          ),
          _Section(title: l10n.languageLabel, icon: Icons.translate_rounded, children: const [_LanguagePicker()]),
          _Section(title: l10n.settingsGraphics, icon: Icons.auto_awesome_rounded, children: const [_GraphicsPicker()]),
          const SizedBox(height: NovaSpace.md),
          Center(
            child: NovaButton(
              key: const ValueKey('settings.done'),
              label: l10n.settingsDone,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NovaSpace.md),
      child: NovaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: NovaSpace.sm),
                Expanded(child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge))),
              ],
            ),
            const SizedBox(height: NovaSpace.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A big on/off row: the whole row toggles, not just the switch.
class _Toggle extends ConsumerWidget {
  const _Toggle({super.key, required this.icon, required this.title, required this.description, required this.provider});
  final IconData icon;
  final String title;
  final String description;
  final StateProvider<bool> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: theme.colorScheme.primary, size: 30),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(description),
        value: ref.watch(provider),
        onChanged: (on) => ref.read(provider.notifier).state = on,
      ),
    );
  }
}

/// When the device has no voice for the language the child plays in, the
/// questions cannot be read aloud: say so, and how to add one.
class _MissingVoice extends ConsumerWidget {
  const _MissingVoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final available = ref.watch(voiceAvailableProvider(lang)).value ?? true;
    if (available || !ref.watch(speechEnabledProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final name = lang == 'ar' ? l10n.languageNameArabic : l10n.languageNameEnglish;
    return Padding(
      key: const ValueKey('settings.voice.missing'),
      padding: const EdgeInsets.only(top: NovaSpace.xs),
      child: NovaFeedbackBanner(kind: NovaFeedbackKind.info, message: '${l10n.voiceMissing(name)} ${l10n.voiceMissingHow(name)}'),
    );
  }
}

class _NameField extends ConsumerStatefulWidget {
  const _NameField();

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final _controller = TextEditingController(text: ref.read(childNameProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      key: const ValueKey('settings.name'),
      controller: _controller,
      maxLength: 20,
      textCapitalization: TextCapitalization.words,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(labelText: l10n.myName, hintText: l10n.typeName, counterText: '', prefixIcon: const Icon(Icons.edit_rounded)),
      onChanged: (v) => ref.read(childNameProvider.notifier).state = v.trim(),
    );
  }
}

/// A big, labelled choice with a picture.
class _PictureChoice extends StatelessWidget {
  const _PictureChoice({super.key, required this.label, required this.selected, required this.onTap, required this.picture});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget picture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NovaRadius.lg),
        child: Container(
          width: 112,
          padding: const EdgeInsets.all(NovaSpace.xs),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(NovaRadius.lg),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 3 : 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 76, width: 96, child: ExcludeSemantics(child: picture)),
              const SizedBox(height: NovaSpace.xxs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
                  if (selected) const SizedBox(width: 4),
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionPicker extends ConsumerWidget {
  const _CompanionPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final choice = ref.watch(companionChoiceProvider);
    final band = ref.watch(ageBandProvider);
    void set(CharacterKind? c) => ref.read(companionChoiceProvider.notifier).state = c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.myFriend, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: NovaSpace.xs),
        Wrap(
          spacing: NovaSpace.xs,
          runSpacing: NovaSpace.xs,
          children: [
            _PictureChoice(key: const ValueKey('settings.companion.auto'), label: l10n.automatic, selected: choice == null, onTap: () => set(null), picture: CharacterView(kind: band.character)),
            for (final c in CharacterKind.values)
              _PictureChoice(
                key: ValueKey('settings.companion.${c.name}'),
                label: lang == 'ar' ? c.displayNameAr : c.displayName,
                selected: choice == c,
                onTap: () => set(c),
                picture: CharacterView(kind: c),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorldPicker extends ConsumerWidget {
  const _WorldPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(worldChoiceProvider);
    final band = ref.watch(ageBandProvider);
    void set(WorldKind? w) => ref.read(worldChoiceProvider.notifier).state = w;
    Widget picture(WorldKind w) => ClipRRect(borderRadius: BorderRadius.circular(NovaRadius.md), child: WorldBackdrop(world: w, groundLevel: 0.6));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.myWorld, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: NovaSpace.xs),
        Wrap(
          spacing: NovaSpace.xs,
          runSpacing: NovaSpace.xs,
          children: [
            _PictureChoice(key: const ValueKey('settings.world.auto'), label: l10n.automatic, selected: choice == null, onTap: () => set(null), picture: picture(band.world)),
            for (final w in WorldKind.values)
              _PictureChoice(key: ValueKey('settings.world.${w.name}'), label: worldName(context, w), selected: choice == w, onTap: () => set(w), picture: picture(w)),
          ],
        ),
      ],
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    Widget option(String code, String name) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NovaSpace.xxs),
            child: _BigChoice(
              key: ValueKey('settings.language.$code'),
              label: name,
              selected: lang == code,
              onTap: () => ref.read(localeProvider.notifier).state = Locale(code),
            ),
          ),
        );
    return Row(children: [option('ar', l10n.languageNameArabic), option('en', l10n.languageNameEnglish)]);
  }
}

class _GraphicsPicker extends ConsumerWidget {
  const _GraphicsPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(graphicsSettingProvider);
    const shown = [GraphicsQualitySetting.auto, GraphicsQualitySetting.low, GraphicsQualitySetting.medium, GraphicsQualitySetting.high];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: NovaSpace.xs,
          runSpacing: NovaSpace.xs,
          children: [
            for (final q in shown)
              SizedBox(
                width: 150,
                child: _BigChoice(
                  key: ValueKey('settings.graphics.${q.name}'),
                  label: graphicsSettingLabel(context, q),
                  selected: setting == q,
                  onTap: () => ref.read(graphicsSettingProvider.notifier).state = q,
                ),
              ),
          ],
        ),
        const SizedBox(height: NovaSpace.xs),
        Text(graphicsSettingHelp(context, setting), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// A big, pill-shaped choice button with a check when selected.
class _BigChoice extends StatelessWidget {
  const _BigChoice({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NovaRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xs),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(NovaRadius.pill),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 3 : 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[Icon(Icons.check_circle_rounded, color: scheme.primary), const SizedBox(width: NovaSpace.xs)],
              Flexible(child: Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
        ),
      ),
    );
  }
}
