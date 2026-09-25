import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_rig.dart';
import '../characters/character_view.dart';
import '../design/nova_design.dart';
import '../l10n.dart';
import '../play/visual_view.dart';
import '../scene/story_scene.dart';
import '../settings/settings_sync.dart';
import '../shell/language_menu.dart';
import '../world/activity_world.dart';
import 'journey_providers.dart';

/// First launch: the companion introduces themself, asks the child's name
/// and age, and shows the first stop of their journey. Three big, simple
/// steps -- the start of an adventure, not a form.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _guide = CharacterController();
  final _name = TextEditingController();
  int _step = 0;
  int? _age;

  static const ages = [2, 3, 4, 5, 6, 7, 8];

  @override
  void dispose() {
    _guide.dispose();
    _name.dispose();
    super.dispose();
  }

  void _go(int step) {
    setState(() => _step = step);
    _guide.react(step == 2 ? Reaction.cheer : Reaction.happy);
    if (step == 2) _guide.setMood(CharacterMood.excited, hold: const Duration(milliseconds: 2000));
  }

  void _finish() {
    ref.read(childNameProvider.notifier).state = _name.text.trim();
    setChildAge(ref, _age!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    // The companion that fits the chosen age, from the moment it is chosen.
    final companion = _age == null ? CharacterKind.fox : ref.watch(companionChoiceProvider) ?? bandForAge(_age!).character;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final friend = rtl ? companion.displayNameAr : companion.displayName;
    final name = _name.text.trim();

    final String say;
    final Widget body;
    switch (_step) {
      case 0:
        say = '${l10n.onboardingHello(friend)} ${l10n.onboardingAskName}';
        body = Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            key: const ValueKey('onboarding.name'),
            controller: _name,
            autofocus: false,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.next,
            maxLength: 24,
            style: NovaType.of(context, 26, weight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: l10n.onboardingNameHint,
              counterText: '',
              filled: true,
              fillColor: NovaStory.cream,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(NovaRadius.lg), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: NovaSpace.md, horizontal: NovaSpace.lg),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _go(1),
          ),
          const SizedBox(height: NovaSpace.lg),
          NovaPlayButton(label: l10n.onboardingNext, icon: Icons.arrow_forward_rounded, color: NovaStory.plum, onPressed: () => _go(1)),
        ]);
      case 1:
        say = l10n.onboardingAskAge;
        body = Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: NovaSpace.sm,
            runSpacing: NovaSpace.sm,
            children: [
              for (final a in ages)
                Semantics(
                  button: true,
                  selected: _age == a,
                  label: '${numeral(a, lang)} ${l10n.yearsOld}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('onboarding.age.$a'),
                    onTap: () {
                      setState(() => _age = a);
                      _guide.react(Reaction.happy);
                    },
                    child: AnimatedContainer(
                      duration: NovaMotion.of(context, NovaMotion.short),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _age == a ? NovaStory.sunshine : NovaStory.cream,
                        border: Border.all(color: _age == a ? NovaStory.honey : const Color(0xFFE9DFF5), width: 4),
                        boxShadow: _age == a ? NovaShadow.glow(NovaStory.sunshine, strength: 0.5) : NovaShadow.contact,
                      ),
                      child: Center(child: Text(numeral(a, lang), style: NovaType.of(context, 32, weight: FontWeight.w900))),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: NovaSpace.lg),
          Wrap(spacing: NovaSpace.sm, runSpacing: NovaSpace.sm, alignment: WrapAlignment.center, children: [
            TextButton(onPressed: () => _go(0), child: Text(l10n.onboardingBack, style: NovaType.label(context, color: NovaStory.plum))),
            NovaPlayButton(label: l10n.onboardingNext, icon: Icons.arrow_forward_rounded, color: NovaStory.plum, onPressed: _age == null ? null : () => _go(2)),
          ]),
        ]);
      default:
        final engine = ref.watch(curriculumEngineProvider);
        final curriculum = ref.watch(curriculumProvider);
        final JourneyStage? first = curriculum.isEmpty ? null : curriculum.stages[engine.entryIndexFor(_age!)];
        final content = ref.watch(contentRuntimeProvider);
        say = name.isEmpty ? l10n.onboardingReadyNoName : l10n.onboardingReady(name);
        body = Column(mainAxisSize: MainAxisSize.min, children: [
          if (first != null) ...[
            NovaPopIn(
              child: FloatingIsland(
                width: 170,
                grass: ActivityCategory.fromPlace(first.place).scene.ground,
                childHeight: 120,
                child: Center(child: CategoryLandmark(category: ActivityCategory.fromPlace(first.place), size: 110)),
              ),
            ),
            const SizedBox(height: NovaSpace.sm),
            Text(l10n.onboardingFirstStop(contentText(content, first.nameKey, lang)), textAlign: TextAlign.center, style: NovaType.title(context)),
            const SizedBox(height: NovaSpace.lg),
          ],
          Wrap(spacing: NovaSpace.sm, runSpacing: NovaSpace.sm, alignment: WrapAlignment.center, children: [
            TextButton(onPressed: () => _go(1), child: Text(l10n.onboardingBack, style: NovaType.label(context, color: NovaStory.plum))),
            NovaPlayButton(key: const ValueKey('onboarding.start'), label: l10n.letsGo, icon: Icons.explore_rounded, onPressed: _finish),
          ]),
        ]);
    }

    return Scaffold(
      body: StoryScene(
        theme: SceneTheme.meadow,
        horizon: 0.55,
        child: SafeArea(
          child: Stack(children: [
            const PositionedDirectional(
              top: NovaSpace.sm,
              end: NovaSpace.md,
              child: DecoratedBox(
                decoration: BoxDecoration(color: NovaStory.cloud, shape: BoxShape.circle, boxShadow: NovaShadow.soft),
                child: SizedBox(width: 52, height: 52, child: Center(child: LanguageMenuButton(iconOnly: true))),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(NovaSpace.md, 72, NovaSpace.md, NovaSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      SizedBox(
                        width: 150,
                        height: 170,
                        child: ExcludeSemantics(child: CharacterView(key: ValueKey(companion), kind: companion, controller: _guide, entrance: Reaction.wave)),
                      ),
                      Flexible(child: NovaSpeechBubble(text: say, size: 19)),
                    ]),
                    const SizedBox(height: NovaSpace.md),
                    NovaPanel(child: AnimatedSwitcher(duration: NovaMotion.of(context, NovaMotion.medium), child: KeyedSubtree(key: ValueKey(_step), child: body))),
                    const SizedBox(height: NovaSpace.md),
                    // Where we are in the three steps.
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _step ? 28 : 12,
                          height: 12,
                          decoration: BoxDecoration(color: i <= _step ? NovaStory.plum : NovaStory.cloud, borderRadius: BorderRadius.circular(NovaRadius.pill)),
                        ),
                    ]),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

}
