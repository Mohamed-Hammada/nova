import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_view.dart';
import '../design/nova_design.dart';
import '../l10n.dart';
import '../scene/story_scene.dart';
import '../widgets/confetti.dart';
import '../world/activity_world.dart';

/// Shown when a child finishes a stage: the companion celebrates the
/// adventure just completed, then the next one appears and unlocks.
class StageCelebration extends ConsumerStatefulWidget {
  const StageCelebration({super.key, required this.completed, required this.next});
  final JourneyStage completed;

  /// The adventure it unlocked (null when the whole journey is finished).
  final JourneyStage? next;

  @override
  ConsumerState<StageCelebration> createState() => _StageCelebrationState();
}

class _StageCelebrationState extends ConsumerState<StageCelebration> {
  final _guide = CharacterController();
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _guide.setMood(CharacterMood.celebrating, hold: const Duration(milliseconds: 2400));
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _revealed = true);
      _guide.react(Reaction.surprise);
      _guide.setMood(CharacterMood.excited, hold: const Duration(milliseconds: 1800));
      final l10n = context.l10n;
      ref.read(speechPortProvider).speak(widget.next == null ? l10n.journeyAllDone : l10n.newAdventure, language: ref.read(languageProvider));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(speechPortProvider).speak(context.l10n.stageComplete, language: ref.read(languageProvider));
    });
  }

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final done = ActivityCategory.fromPlace(widget.completed.place);
    final next = widget.next == null ? null : ActivityCategory.fromPlace(widget.next!.place);
    final reveal = _revealed || NovaMotion.reduced(context);

    Widget island(ActivityCategory c, {required bool unlocked, required bool check}) => Stack(clipBehavior: Clip.none, children: [
          FloatingIsland(width: 150, grass: c.scene.ground, childHeight: 110, child: Center(child: CategoryLandmark(category: c, size: 100))),
          PositionedDirectional(
            top: 0,
            end: 6,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: check ? NovaStory.yes : (unlocked ? NovaStory.sunshine : NovaStory.inkSoft), boxShadow: NovaShadow.soft),
              child: Icon(check ? Icons.check_rounded : (unlocked ? Icons.lock_open_rounded : Icons.lock_rounded), color: Colors.white, size: 26),
            ),
          ),
        ]);

    return Scaffold(
      body: StoryScene(
        theme: (next ?? done).scene,
        child: Stack(children: [
          Positioned.fill(child: IgnorePointer(child: ConfettiBurst(play: reveal ? 2 : 1))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NovaSpace.lg),
                child: NovaPanel(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 150, height: 150, child: CharacterView(kind: ref.watch(companionProvider), controller: _guide)),
                    Semantics(liveRegion: true, child: Text(l10n.stageComplete, textAlign: TextAlign.center, style: NovaType.display(context, color: done.deep))),
                    const SizedBox(height: NovaSpace.xs),
                    Text(contentText(content, widget.completed.nameKey, lang), style: NovaType.title(context)),
                    const SizedBox(height: NovaSpace.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: NovaSpace.md,
                      runSpacing: NovaSpace.md,
                      children: [
                        island(done, unlocked: true, check: true),
                        if (next != null) ...[
                          Icon(Directionality.of(context) == TextDirection.rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 40, color: NovaStory.inkSoft),
                          AnimatedScale(
                            scale: reveal ? 1 : 0.85,
                            duration: NovaMotion.of(context, NovaMotion.long),
                            curve: Curves.easeOutBack,
                            child: AnimatedOpacity(
                              opacity: reveal ? 1 : 0.45,
                              duration: NovaMotion.of(context, NovaMotion.long),
                              child: island(next, unlocked: reveal, check: false),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: NovaSpace.md),
                    AnimatedOpacity(
                      opacity: reveal ? 1 : 0,
                      duration: NovaMotion.of(context, NovaMotion.medium),
                      child: Column(children: [
                        Text(widget.next == null ? l10n.journeyAllDone : l10n.newAdventure, textAlign: TextAlign.center, style: NovaType.title(context, color: NovaStory.plum)),
                        if (widget.next != null) Text(contentText(content, widget.next!.nameKey, lang), style: NovaType.body(context)),
                        const SizedBox(height: NovaSpace.md),
                        NovaPlayButton(label: l10n.letsGo, icon: Icons.explore_rounded, color: (next ?? done).color, onPressed: () => Navigator.of(context).pop()),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
