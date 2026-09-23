import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/models.dart';

void main() {
  group('GamePresentation model', () {
    test('parses defaults gracefully when values are omitted', () {
      final presentation = GamePresentation.fromJson(const {});
      expect(presentation.theme, 'default');
      expect(presentation.background, 'default');
      expect(presentation.character, isNull);
      expect(presentation.targetContainer, isNull);
      expect(presentation.items, isNull);
      expect(presentation.environmentElements, isEmpty);
      expect(presentation.feedbackEffects, isEmpty);
    });

    test('parses full presentation structure', () {
      final json = {
        'theme': 'orchard_meadow',
        'background': 'orchard_meadow',
        'character': {
          'id': 'bear',
          'name_key': 'character.bear.name',
          'default_state': 'idle',
          'states': ['idle', 'happy', 'thinking', 'celebrate'],
        },
        'target_container': {
          'id': 'basket',
          'label_key': 'game.math.bear-apples.basket.label',
          'empty_label_key': 'game.math.bear-apples.basket.empty',
        },
        'items': {
          'primary': {
            'id': 'apple',
            'label_key': 'item.apple.label',
            'on_target_label_key': 'item.apple.on_target',
          },
          'distractor': {
            'id': 'pear',
            'label_key': 'item.pear.label',
            'on_target_label_key': 'item.pear.on_target',
          },
        },
        'environment_elements': ['tree_branch', 'blanket'],
        'feedback_effects': ['star_gold', 'sparkle'],
      };

      final pres = GamePresentation.fromJson(json);
      expect(pres.theme, 'orchard_meadow');
      expect(pres.background, 'orchard_meadow');

      expect(pres.character?.id, 'bear');
      expect(pres.character?.nameKey, 'character.bear.name');
      expect(pres.character?.defaultState, 'idle');
      expect(pres.character?.states, ['idle', 'happy', 'thinking', 'celebrate']);

      expect(pres.targetContainer?.id, 'basket');
      expect(pres.targetContainer?.labelKey, 'game.math.bear-apples.basket.label');
      expect(pres.targetContainer?.emptyLabelKey, 'game.math.bear-apples.basket.empty');

      expect(pres.items?.primary.id, 'apple');
      expect(pres.items?.primary.labelKey, 'item.apple.label');
      expect(pres.items?.distractor?.id, 'pear');

      expect(pres.environmentElements, ['tree_branch', 'blanket']);
      expect(pres.feedbackEffects, ['star_gold', 'sparkle']);
    });

    test('game model includes presentation if present', () {
      final gameJson = {
        'id': 'game.math.bear-apples',
        'name_key': 'game.math.bear-apples.name',
        'primary_skills': ['math.count.one-to-one-5'],
        'mechanic_id': 'drag-to-count',
        'difficulty': {
          'rungs': [
            {
              'id': 'r1',
              'values': {'item_complexity': 1},
            },
          ],
        },
        'scaffolding': {
          'hints': ['hint1'],
          'adult_prompt': 'prompt',
        },
        'signals': ['sig.game.trial-outcome'],
        'progression': {
          'advance_parameter': 'param.advance',
          'retreat_parameter': 'param.retreat',
        },
        'transfer_probes': [],
        'presentation': {
          'theme': 'orchard_meadow',
          'character': {'id': 'bear'},
        },
      };

      final game = Game.fromJson(gameJson);
      expect(game.presentation, isNotNull);
      expect(game.presentation!.theme, 'orchard_meadow');
      expect(game.presentation!.character!.id, 'bear');
    });
  });
}
