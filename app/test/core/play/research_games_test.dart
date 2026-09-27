import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_graph.dart';

import '../../support/fixture_content.dart';

/// Make Ten, Frog Hops and Story Time: each is built from published research
/// (docs/product/math-and-language-research.md) and builds real rounds.
void main() {
  final content = loadRealBundle();
  const factory = TrialFactory();

  List<ChoiceTrial> build(String gameId, String rung, {String lang = 'en', int seed = 3}) {
    final game = content.game(gameId);
    expect(factory.canPlayGame(game), isTrue);
    return factory.build(game: game, rung: game.rungsById[rung]!, language: lang, seed: seed).cast<ChoiceTrial>();
  }

  test('every new game cites verified research, in the bundle', () {
    final bundle = jsonDecode(File('assets/content/content_bundle.json').readAsStringSync()) as Map<String, dynamic>;
    final games = {for (final g in bundle['games'] as List) (g as Map)['id']: g};
    final evidence = {for (final e in bundle['evidence'] as List) (e as Map)['id']: e};
    for (final id in ['game.math.make-ten', 'game.math.number-path', 'game.lit.en.story-time', 'game.lit.ar.story-time']) {
      final refs = List<String>.from(games[id]!['evidence_refs'] as List);
      expect(refs.any((r) => evidence[r]!['verified'] == true && evidence[r]!['evidence_type'] != 'design_inference'), isTrue, reason: id);
    }
    // The Japanese sources behind the math games.
    expect(List<String>.from(games['game.math.make-ten']!['evidence_refs'] as List), contains('ev.math.murata-2004'));
    expect(List<String>.from(games['game.math.number-path']!['evidence_refs'] as List), contains('ev.math.urakami-sugimura-2017'));
  });

  test('teen sums build on the parts of ten, as in the Japanese sequence', () {
    final graph = SkillGraph.fromContent(content);
    expect(graph.prerequisitesOf('math.add-sub.within-20'), contains('math.number.parts-of-ten'));
    expect(graph.prerequisitesOf('math.number.parts-of-ten'), contains('math.count.cardinality'));
  });

  group('Make Ten', () {
    for (final (rung, total, dots) in [('r1', 5, true), ('r2', 10, true), ('r3', 10, false)]) {
      test('$rung: make $total${dots ? ' with dots' : ', numbers only'}', () {
        final trials = build('game.math.make-ten', rung);
        expect(trials, hasLength(trialsPerSession));
        for (final t in trials) {
          final frame = t.question! as FrameVisual;
          expect(frame.slots, total);
          expect(frame.showDots, dots);
          final answer = (t.options[t.answer] as NumeralVisual).value;
          expect(frame.filled + answer, total);
          for (var i = 0; i < t.options.length; i++) {
            if (i == t.answer) continue;
            final v = (t.options[i] as NumeralVisual).value;
            expect(t.errorsFor(i), [v > answer ? ErrorType.overCount : ErrorType.underCount]);
          }
        }
      });
    }
  });

  group('Frog Hops', () {
    for (final (rung, length, maxHop) in [('r1', 5, 2), ('r2', 10, 3)]) {
      test('$rung: a path of $length, hops up to $maxHop', () {
        for (final t in build('game.math.number-path', rung)) {
          final path = t.question! as PathVisual;
          expect(path.length, length);
          expect(path.hops, inInclusiveRange(1, maxHop));
          final land = (t.options[t.answer] as NumeralVisual).value;
          expect(land, path.at + path.hops);
          expect(land, lessThanOrEqualTo(length));
          expect(t.options.map((o) => (o as NumeralVisual).value).toSet(), hasLength(t.options.length), reason: 'no duplicate answers');
        }
      });
    }
  });

  group('Story Time', () {
    for (final lang in ['en', 'ar']) {
      test('$lang: questions after each page, answered with a picture the scene does not give away', () {
        for (final (rung, choices) in [('r1', 2), ('r2', 3)]) {
          final trials = build('game.lit.$lang.story-time', rung, lang: lang);
          expect(trials, hasLength(trialsPerSession));
          for (final t in trials) {
            expect(t.options, hasLength(choices));
            expect(t.promptArgs['page'], isNotEmpty);
            expect(t.promptArgs['ask'], isNotEmpty);
            expect(t.speak, contains(t.promptArgs['ask']));
            expect((t.question! as SceneVisual).prop, isNull);
            if (lang == 'ar') expect(RegExp(r'[؀-ۿ]').hasMatch(t.speak!), isTrue);
          }
        }
      });
    }
  });
}
