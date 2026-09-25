import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/journey/curriculum_engine.dart';

import '../../support/fixture_content.dart';

/// Journey copy is complete in both languages, kept apart from technical
/// ids, and child-facing Arabic never judges the child.
void main() {
  final content = loadRealBundle();
  final curriculum = Curriculum.fromContent(content);
  final arabicLetters = RegExp('[؀-ۿ]');

  test('every stage has an English and an Arabic name (and neither is a raw key)', () {
    expect(curriculum.stages, isNotEmpty);
    for (final stage in curriculum.stages) {
      final en = content.i18n(stage.nameKey, 'en');
      final ar = content.i18n(stage.nameKey, 'ar');
      expect(en, isNot(stage.nameKey), reason: '${stage.id} en');
      expect(ar, isNot(stage.nameKey), reason: '${stage.id} ar');
      expect(ar, contains(arabicLetters), reason: '${stage.id}: Arabic name is written in Arabic');
      expect(en, isNot(contains(arabicLetters)), reason: '${stage.id}: English name is written in English');
    }
  });

  test('technical ids never depend on wording: stage and activity ids are plain ASCII slugs', () {
    final slug = RegExp(r'^[a-z0-9._-]+$');
    for (final stage in curriculum.stages) {
      expect(stage.id, matches(slug));
      expect(stage.nameKey, matches(slug));
      for (final a in stage.activities) {
        expect(a.id, matches(slug));
      }
    }
  });

  Map<String, dynamic> arb(String lang) => jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

  test('every interface string exists in both English and Arabic', () {
    final en = arb('en').keys.where((k) => !k.startsWith('@')).toSet();
    final ar = arb('ar').keys.where((k) => !k.startsWith('@')).toSet();
    expect(ar.difference(en), isEmpty, reason: 'Arabic keys without English');
    expect(en.difference(ar), isEmpty, reason: 'English keys without Arabic');
  });

  test('child-facing Arabic never judges the child', () {
    const judging = ['فشل', 'خطأ', 'خاطئ', 'درجتك', 'لم تنجح', 'سيئ'];
    final ar = arb('ar');
    for (final MapEntry(:key, :value) in ar.entries) {
      if (key.startsWith('@') || value is! String) continue;
      for (final word in judging) {
        expect(value.contains(word), isFalse, reason: '$key: "$value" contains "$word"');
      }
    }
  });
}
