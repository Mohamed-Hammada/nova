import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/play/voice_match.dart';

void main() {
  test('numbers are recognised as digits, English words, Arabic words and Eastern Arabic digits', () {
    const options = [NumeralVisual(2), NumeralVisual(3), NumeralVisual(5)];
    expect(matchSpoken('three', options, 'en'), 1);
    expect(matchSpoken('I think it is 5!', options, 'en'), 2);
    expect(matchSpoken('ثلاثة', options, 'ar'), 1);
    expect(matchSpoken('٥', options, 'ar'), 2);
    expect(matchSpoken('خمسة', options, 'ar'), 2);
    expect(matchSpokenNumber('twelve', [11, 12, 13], 'en'), 12);
  });

  test('pictures are recognised by their word, in the child\'s language', () {
    const options = [PicVisual(Pic.cat), PicVisual(Pic.sun), PicVisual(Pic.ball)];
    expect(matchSpoken('the sun', options, 'en'), 1);
    expect(matchSpoken('balls', options, 'en'), 2);
    expect(matchSpoken('شمس', options, 'ar'), 1);
    expect(matchSpoken('قطة', options, 'ar'), 0);
  });

  test('letters are recognised by their names', () {
    const en = [TextVisual('b', isLetter: true), TextVisual('d', isLetter: true)];
    expect(matchSpoken('bee', en, 'en'), 0);
    expect(matchSpoken('dee', en, 'en'), 1);
    const ar = [TextVisual('بـ', isLetter: true), TextVisual('تـ', isLetter: true)];
    expect(matchSpoken('باء', ar, 'ar'), 0);
  });

  test('feelings are recognised by name and everyday synonyms', () {
    const options = [FaceVisual(Who.fox, Emotion.happy), FaceVisual(Who.bear, Emotion.angry)];
    expect(matchSpoken('mad', options, 'en'), 1);
    expect(matchSpoken('فرحان', options, 'ar'), 0);
  });

  test('nothing heard, or an answer matching two options, is ignored so the child can tap', () {
    const options = [NumeralVisual(2), NumeralVisual(3)];
    expect(matchSpoken('', options, 'en'), isNull);
    expect(matchSpoken('banana', options, 'en'), isNull);
    expect(matchSpoken('two or three', options, 'en'), isNull);
  });

  test('rounds whose options cannot be named are not offered voice answers', () {
    expect(canAnswerByVoice(const [GroupVisual(Pic.apple, 3), GroupVisual(Pic.apple, 1)], 'en'), isFalse);
    expect(canAnswerByVoice(const [NumeralVisual(1), NumeralVisual(4)], 'en'), isTrue);
  });
}
