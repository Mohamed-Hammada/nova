import 'package:flutter/material.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/trials.dart';

import '../art/pic_art.dart';
import '../theme/nova_theme.dart';
import 'visual_view.dart';

/// The illustration on a game's card, picked from what the game is about.
Widget gameArt(Game game, double w, String language) {
  Widget pics(List<Pic> list) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final p in list) PicArt(p, size: w * 0.28)]);
  Widget tokens(List<Token> list) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final t in list) TokenArt(t, size: w * 0.22)]);
  Widget letters(String text) => Text(text, style: novaText(w * 0.26, weight: 800, color: Colors.white).copyWith(shadows: const [Shadow(blurRadius: 6, color: Color(0x66000000))]));
  final id = game.id;
  final Widget art = switch (game.mechanicId) {
    'drag-to-count' => pics(id.contains('bunny') ? [Pic.carrot, Pic.bunny, Pic.carrot] : [Pic.apple, Pic.bear, Pic.apple]),
    'compare-quantities' => pics([Pic.apple, Pic.apple, Pic.apple]),
    'match-symbol-to-quantity' => Row(mainAxisAlignment: MainAxisAlignment.center, children: [NumeralBadge(numeral(3, language), size: w * 0.24), const SizedBox(width: 8), PicArt(Pic.star, size: w * 0.26)]),
    'catch-target' => id.contains('lit') ? Stack(alignment: Alignment.center, children: [PicArt(Pic.balloon, size: w * 0.4), letters(language == 'ar' ? 'ب' : 'a')]) : pics([Pic.balloon, Pic.balloon]),
    'pattern-continue' => id.contains('builder') ? VisualView(const TowersVisual([1, 2, 3], withGap: false), size: w * 0.4, language: language) : tokens(const [Token(Shape.circle, Hue.red), Token(Shape.circle, Hue.blue), Token(Shape.circle, Hue.red)]),
    'tap-to-count' => pics([Pic.star, Pic.star, Pic.star]),
    'join-separate' => pics(id.contains('space') ? [Pic.gem, Pic.robot, Pic.gem] : [Pic.bird, Pic.bird]),
    'number-line-place' => Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final n in [0, 5, 10]) Padding(padding: const EdgeInsets.all(4), child: NumeralBadge(numeral(n, language), size: w * 0.18))]),
    'sort-by-rule' || 'switch-sort-rule' => tokens(const [Token(Shape.star, Hue.red), Token(Shape.circle, Hue.blue)]),
    'match-pairs' => pics([Pic.fish, Pic.fish]),
    'sequence-recall' => tokens(const [Token(Shape.circle, Hue.red), Token(Shape.circle, Hue.yellow), Token(Shape.circle, Hue.green)]),
    'go-no-go' => pics([Pic.fish, Pic.shark]),
    'emotion-match' => Row(mainAxisAlignment: MainAxisAlignment.center, children: [FaceArt(Who.bunny, Emotion.happy, size: w * 0.34), FaceArt(Who.fox, Emotion.sad, size: w * 0.34)]),
    'story-choice' => id.contains('sel') ? FaceArt(Who.bear, Emotion.surprised, size: w * 0.45) : pics([Pic.book, Pic.bear]),
    'hear-and-point' => pics([Pic.ball, Pic.cup, Pic.sun]),
    'segment-sounds' => pics([Pic.drum]),
    'rhyme-select' => pics(language == 'ar' ? [Pic.cat, Pic.duck] : [Pic.cat, Pic.hat]),
    'print-follow' => pics([Pic.book]),
    'letter-match' => letters(language == 'ar' ? 'ب  بـ' : 'A  a'),
    'sound-match' => Row(mainAxisAlignment: MainAxisAlignment.center, children: [PicArt(Pic.sun, size: w * 0.3), letters(language == 'ar' ? 'ش' : 's')]),
    'build-word' => letters(language == 'ar' ? 'ق م ر' : 'c a t'),
    'blend-sounds' => letters(language == 'ar' ? 'قَ-مَر' : 'c-a-t'),
    'read-and-match' => Row(mainAxisAlignment: MainAxisAlignment.center, children: [letters(language == 'ar' ? 'شمس' : 'sun'), PicArt(Pic.sun, size: w * 0.26)]),
    _ => pics([Pic.star]),
  };
  return Center(child: FittedBox(child: art));
}
