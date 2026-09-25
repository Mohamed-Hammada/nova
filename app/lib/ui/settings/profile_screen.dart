import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_rig.dart';
import '../characters/character_view.dart';
import '../play/visual_view.dart';
import '../scene/world_backdrop.dart';
import '../theme/age_band.dart';
import '../theme/nova_theme.dart';
import '../l10n.dart';
import '../theme/labels.dart';
import '../widgets/jelly_button.dart';
import 'settings_sync.dart';

/// "About me": the child sets their name, age, friend, world and language.
/// Everything is optional and changes the app immediately.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final _name = TextEditingController(text: ref.read(childNameProvider));

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l10n = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final band = ref.watch(ageBandProvider);
    final age = ref.watch(childAgeProvider);
    final p = ref.watch(paletteProvider);
    final companionChoice = ref.watch(companionChoiceProvider);
    final worldChoice = ref.watch(worldChoiceProvider);
    final ink = p.isNight ? Colors.white : const Color(0xFF2E2440);

    Widget section(String title, Widget body) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: p.isNight ? 0.1 : 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: novaText(24, weight: 800, color: ink)),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );

    return Scaffold(
      body: WorldBackdrop(
        world: ref.watch(worldProvider),
        groundLevel: 0.9,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    JellyButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      color: p.accent,
                      circle: true,
                      size: 48,
                      child: Icon(rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.aboutMe, style: novaText(30, weight: 800, color: ink)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        section(
                          l10n.myName,
                          TextField(
                            controller: _name,
                            maxLength: 20,
                            textCapitalization: TextCapitalization.words,
                            style: novaText(26, weight: 700, color: const Color(0xFF2E2440)),
                            decoration: InputDecoration(
                              hintText: l10n.typeName,
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.edit_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                            ),
                            onChanged: (v) => ref.read(childNameProvider.notifier).state = v.trim(),
                          ),
                        ),
                        section(
                          l10n.howOld,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (var a = 2; a <= 8; a++)
                                    _Bubble(
                                      selected: age == a,
                                      color: p.accent,
                                      onTap: () {
                                        ref.read(childAgeProvider.notifier).state = a;
                                        ref.read(ageBandProvider.notifier).state = bandForAge(a);
                                      },
                                      child: Text(numeral(a, lang), style: novaText(34, weight: 800, color: age == a ? Colors.white : const Color(0xFF2E2440))),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('${bandTitle(context, band)} · ${ageYears(context, band)}', style: novaText(18, weight: 700, color: ink.withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                        section(
                          l10n.myFriend,
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _Choice(
                                selected: companionChoice == null,
                                color: p.accent,
                                label: l10n.automatic,
                                onTap: () => ref.read(companionChoiceProvider.notifier).state = null,
                                child: CharacterView(kind: band.character, rimColor: p.glow),
                              ),
                              for (final c in CharacterKind.values)
                                _Choice(
                                  selected: companionChoice == c,
                                  color: p.accent,
                                  label: lang == 'ar' ? c.displayNameAr : c.displayName,
                                  onTap: () => ref.read(companionChoiceProvider.notifier).state = c,
                                  child: CharacterView(kind: c, rimColor: p.glow),
                                ),
                            ],
                          ),
                        ),
                        section(
                          l10n.myWorld,
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _Choice(
                                selected: worldChoice == null,
                                color: p.accent,
                                label: l10n.automatic,
                                onTap: () => ref.read(worldChoiceProvider.notifier).state = null,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: WorldBackdrop(world: band.world, groundLevel: 0.6),
                                ),
                              ),
                              for (final w in WorldKind.values)
                                _Choice(
                                  selected: worldChoice == w,
                                  color: p.accent,
                                  label: worldName(context, w),
                                  onTap: () => ref.read(worldChoiceProvider.notifier).state = w,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: WorldBackdrop(world: w, groundLevel: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        section(
                          l10n.languageLabel,
                          Wrap(
                            spacing: 12,
                            children: [
                              for (final (code, label) in [('en', l10n.languageNameEnglish), ('ar', l10n.languageNameArabic)])
                                _Bubble(
                                  wide: true,
                                  selected: lang == code,
                                  color: p.accent,
                                  onTap: () => ref.read(localeProvider.notifier).state = Locale(code),
                                  child: Text(label, style: novaText(24, weight: 800, color: lang == code ? Colors.white : const Color(0xFF2E2440))),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.selected, required this.color, required this.onTap, required this.child, this.wide = false});
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: wide ? 170 : 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: selected ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(color, 0.25), color]) : null,
        color: selected ? null : Colors.white,
        border: Border.all(color: selected ? Colors.white : const Color(0xFFE2DCEC), width: 3),
        boxShadow: [
          BoxShadow(
            color: (selected ? color : Colors.black).withValues(alpha: selected ? 0.5 : 0.08),
            blurRadius: selected ? 16 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.selected, required this.color, required this.label, required this.onTap, required this.child});
  final bool selected;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? color : const Color(0xFFE2DCEC), width: selected ? 5 : 2),
        boxShadow: [
          BoxShadow(
            color: (selected ? color : Colors.black).withValues(alpha: selected ? 0.45 : 0.08),
            blurRadius: selected ? 18 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 110, child: child),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
              if (selected) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: novaText(17, weight: 800, color: const Color(0xFF2E2440)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
