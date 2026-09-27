import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/play/social_stories.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/skills/endcore.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_graph.dart';
import 'package:nova_app/core/skills/skill_profile.dart';

import '../../support/fixture_content.dart';

/// The communication skills, organised by the ENDCORE model (Fujimoto &
/// Daibo, 2007) and grounded for young children in Takahashi et al. (2008).
void main() {
  final content = loadRealBundle();
  final graph = SkillGraph.fromContent(content);

  test('every social-emotional skill sits in exactly one ENDCORE cell, and every cell has a skill and a game', () {
    final sel = [for (final g in content.games) ...g.primarySkillIds].where((s) => s.startsWith('sel.')).toSet();
    for (final s in sel) {
      expect(EndcoreSkill.of(s), isNotNull, reason: s);
    }
    for (final cell in EndcoreSkill.values) {
      expect(cell.skillIds.where(content.hasSkill), isNotEmpty, reason: '$cell');
      expect(cell.skillIds.any((s) => content.gamesForSkill(s).isNotEmpty), isTrue, reason: '$cell has a game');
    }
    expect(EndcoreSkill.values.map((s) => (s.level, s.system)).toSet(), hasLength(6), reason: 'a full 2x3 grid');
  });

  test('the hierarchy is in the skill graph: each skill for getting on with others builds on its basic skill', () {
    for (final s in EndcoreSkill.values.where((s) => s.level == EndcoreLevel.interpersonal)) {
      final foundation = s.foundation!;
      for (final id in s.skillIds) {
        expect(graph.ancestorsOf(id).intersection(foundation.skillIds.toSet()), isNotEmpty, reason: '$id builds on $foundation');
      }
    }
  });

  test('every new game cites the Japanese research it is based on', () {
    final bundle = jsonDecode(File('assets/content/content_bundle.json').readAsStringSync()) as Map<String, dynamic>;
    final games = {for (final g in bundle['games'] as List) (g as Map)['id']: g};
    final evidence = {for (final e in bundle['evidence'] as List) (e as Map)['id']: e};
    for (final id in ['game.sel.show-my-feeling', 'game.sel.kind-words', 'game.sel.help-a-friend', 'game.sel.calm-down', 'game.sel.fair-play']) {
      final refs = List<String>.from(games[id]!['evidence_refs'] as List);
      expect(refs, containsAll(['ev.sel.fujimoto-daibo-2007', 'ev.sel.takahashi-2008']), reason: id);
      for (final ref in refs.where((r) => r.startsWith('ev.sel.'))) {
        expect(evidence[ref]!['verified'], isTrue, reason: ref);
        expect(evidence[ref]!['research_origin'], contains('JP'), reason: ref);
      }
    }
  });

  group('the games build real rounds in both languages', () {
    const factory = TrialFactory();
    for (final id in ['game.sel.show-my-feeling', 'game.sel.kind-words', 'game.sel.help-a-friend', 'game.sel.calm-down', 'game.sel.fair-play']) {
      for (final lang in ['en', 'ar']) {
        test('$id ($lang)', () {
          final game = content.game(id);
          expect(factory.canPlayGame(game), isTrue);
          for (final (i, rungId) in game.rungIds.indexed) {
            final trials = factory.build(game: game, rung: game.rungsById[rungId]!, language: lang, seed: 7);
            expect(trials, hasLength(trialsPerSession));
            for (final t in trials.cast<ChoiceTrial>()) {
              expect(t.options, hasLength(i == 0 ? 2 : 3), reason: 'more ways to choose from on the higher rung');
              expect(t.errorsFor(t.answer), isEmpty);
              for (var o = 0; o < t.options.length; o++) {
                if (o == t.answer) continue;
                final errors = t.errorsFor(o);
                expect(errors, hasLength(1));
                expect(ErrorType.isMistake(errors.single), isTrue);
              }
              expect(t.speak, isNotEmpty, reason: 'everything is read aloud for children who do not read yet');
              expect(t.promptArgs['story'], isNotEmpty);
            }
          }
        });
      }
    }
  });

  test('each social moment has one good way and wrong ways that say what they mean', () {
    for (final list in [kindWordsMoments, helpFriendMoments, calmDownMoments, fairPlayMoments]) {
      expect(list.length, greaterThanOrEqualTo(trialsPerSession));
      for (final m in list) {
        expect(m.good.error, isNull);
        expect(m.others, hasLength(2));
        for (final o in m.others) {
          expect(o.error, isNotNull);
        }
      }
    }
  });

  test('the Arabic lines never judge the child', () {
    const judging = ['فشل', 'خطأ', 'خاطئ', 'درجتك', 'لم تنجح', 'سيئ'];
    final lines = [
      for (final m in feelingMoments) m.ar,
      for (final list in [kindWordsMoments, helpFriendMoments, calmDownMoments, fairPlayMoments])
        for (final m in list) ...[m.ar, m.good.ar, for (final o in m.others) o.ar],
    ];
    for (final line in lines) {
      for (final w in judging) {
        expect(line.contains(w), isFalse, reason: line);
      }
    }
  });

  test('a cell shows the most advanced state its skills have evidence for', () {
    final profiles = {
      'sel.emotion.faces': const SkillProfile(skillId: 'sel.emotion.faces', state: SkillState.secure, sessions: 3),
      'sel.emotion.situations': const SkillProfile(skillId: 'sel.emotion.situations', state: SkillState.emerging, sessions: 1),
    };
    final decoding = EndcoreCell.from(EndcoreSkill.decoding, profiles);
    expect(decoding.state, SkillState.secure);
    expect(decoding.sessions, 4);
    expect(EndcoreCell.from(EndcoreSkill.assertion, profiles).state, isNull);
  });
}
