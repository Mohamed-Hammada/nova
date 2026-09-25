class Skill {
  const Skill({
    required this.id,
    required this.domains,
    required this.nameKey,
    required this.descriptionKey,
    required this.prerequisiteSkillIds,
    required this.evidenceBasis,
    required this.deepScope,
    required this.scope,
  });

  final String id;
  final List<String> domains;
  final String nameKey;
  final String descriptionKey;
  final List<String> prerequisiteSkillIds;
  final String evidenceBasis;
  final bool deepScope;
  final String scope;

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        domains: List<String>.from(json['domains'] as List),
        nameKey: json['name_key'] as String,
        descriptionKey: json['description_key'] as String,
        prerequisiteSkillIds: (json['prerequisites'] as List)
            .map((p) => (p as Map<String, dynamic>)['skill'] as String)
            .toList(),
        evidenceBasis: json['evidence_basis'] as String,
        deepScope: json['deep_scope'] as bool,
        scope: json['scope'] as String,
      );
}

class Rung {
  const Rung({required this.id, required this.values});
  final String id;
  final Map<String, int> values;

  factory Rung.fromJson(Map<String, dynamic> json) => Rung(
        id: json['id'] as String,
        values: Map<String, int>.from(json['values'] as Map),
      );
}

class Scaffolding {
  const Scaffolding({required this.hints, required this.adultPrompt});
  final List<String> hints;
  final String adultPrompt;

  factory Scaffolding.fromJson(Map<String, dynamic> json) => Scaffolding(
        hints: List<String>.from(json['hints'] as List),
        adultPrompt: json['adult_prompt'] as String,
      );
}

class TransferProbe {
  const TransferProbe({
    required this.id,
    required this.type,
    required this.delayed,
    required this.skillId,
    required this.mechanicId,
    required this.taskRef,
  });
  final String id;
  final String type; // 'cross_game' | 'cross_context'
  final bool delayed;
  final String skillId;
  final String mechanicId;
  final String taskRef;

  factory TransferProbe.fromJson(Map<String, dynamic> json) => TransferProbe(
        id: json['id'] as String,
        type: json['type'] as String,
        delayed: json['delayed'] as bool,
        skillId: json['skill'] as String,
        mechanicId: json['mechanic_id'] as String,
        taskRef: json['task_ref'] as String,
      );
}

class CharacterSpec {
  const CharacterSpec({
    required this.id,
    this.nameKey,
    this.defaultState = 'idle',
    this.states = const ['idle'],
  });

  final String id;
  final String? nameKey;
  final String defaultState;
  final List<String> states;

  factory CharacterSpec.fromJson(Map<String, dynamic> json) => CharacterSpec(
        id: json['id'] as String,
        nameKey: json['name_key'] as String?,
        defaultState: json['default_state'] as String? ?? 'idle',
        states: json['states'] != null ? List<String>.from(json['states'] as List) : const ['idle'],
      );
}

class TargetContainerSpec {
  const TargetContainerSpec({
    required this.id,
    this.labelKey,
    this.emptyLabelKey,
  });

  final String id;
  final String? labelKey;
  final String? emptyLabelKey;

  factory TargetContainerSpec.fromJson(Map<String, dynamic> json) => TargetContainerSpec(
        id: json['id'] as String,
        labelKey: json['label_key'] as String?,
        emptyLabelKey: json['empty_label_key'] as String?,
      );
}

class ItemVisualSpec {
  const ItemVisualSpec({
    required this.id,
    required this.labelKey,
    required this.onTargetLabelKey,
  });

  final String id;
  final String labelKey;
  final String onTargetLabelKey;

  factory ItemVisualSpec.fromJson(Map<String, dynamic> json) => ItemVisualSpec(
        id: json['id'] as String,
        labelKey: json['label_key'] as String,
        onTargetLabelKey: json['on_target_label_key'] as String,
      );
}

class GameItemsSpec {
  const GameItemsSpec({
    required this.primary,
    this.distractor,
  });

  final ItemVisualSpec primary;
  final ItemVisualSpec? distractor;

  factory GameItemsSpec.fromJson(Map<String, dynamic> json) => GameItemsSpec(
        primary: ItemVisualSpec.fromJson(json['primary'] as Map<String, dynamic>),
        distractor: json['distractor'] != null
            ? ItemVisualSpec.fromJson(json['distractor'] as Map<String, dynamic>)
            : null,
      );
}

class GamePresentation {
  const GamePresentation({
    this.theme = 'default',
    this.background = 'default',
    this.character,
    this.targetContainer,
    this.items,
    this.environmentElements = const [],
    this.feedbackEffects = const [],
  });

  final String theme;
  final String background;
  final CharacterSpec? character;
  final TargetContainerSpec? targetContainer;
  final GameItemsSpec? items;
  final List<String> environmentElements;
  final List<String> feedbackEffects;

  factory GamePresentation.fromJson(Map<String, dynamic> json) => GamePresentation(
        theme: json['theme'] as String? ?? 'default',
        background: json['background'] as String? ?? 'default',
        character: json['character'] != null
            ? CharacterSpec.fromJson(json['character'] as Map<String, dynamic>)
            : null,
        targetContainer: json['target_container'] != null
            ? TargetContainerSpec.fromJson(json['target_container'] as Map<String, dynamic>)
            : null,
        items: json['items'] != null
            ? GameItemsSpec.fromJson(json['items'] as Map<String, dynamic>)
            : null,
        environmentElements: json['environment_elements'] != null
            ? List<String>.from(json['environment_elements'] as List)
            : const [],
        feedbackEffects: json['feedback_effects'] != null
            ? List<String>.from(json['feedback_effects'] as List)
            : const [],
      );
}

class Game {
  const Game({
    required this.id,
    required this.nameKey,
    required this.primarySkillIds,
    required this.mechanicId,
    required this.rungIds,
    required this.rungsById,
    required this.scaffolding,
    required this.signalIds,
    required this.progressionAdvanceParameter,
    required this.progressionRetreatParameter,
    required this.transferProbes,
    this.ageRange = const [2, 8],
    this.languageDependencies = const [],
    this.presentation,
  });

  final String id;
  final String nameKey;

  /// [min, max] age in years the game is designed for.
  final List<int> ageRange;

  /// Language packs the game needs (literacy games); empty for universal games.
  final List<String> languageDependencies;
  final List<String> primarySkillIds;
  final String mechanicId;
  final List<String> rungIds;
  final Map<String, Rung> rungsById;
  final Scaffolding scaffolding;
  final List<String> signalIds;
  final String progressionAdvanceParameter;
  final String progressionRetreatParameter;
  final List<TransferProbe> transferProbes;
  final GamePresentation? presentation;

  factory Game.fromJson(Map<String, dynamic> json) {
    final rungs = (json['difficulty']['rungs'] as List)
        .map((r) => Rung.fromJson(r as Map<String, dynamic>))
        .toList();
    return Game(
      id: json['id'] as String,
      nameKey: json['name_key'] as String,
      primarySkillIds: List<String>.from(json['primary_skills'] as List),
      mechanicId: json['mechanic_id'] as String,
      rungIds: rungs.map((r) => r.id).toList(),
      rungsById: {for (final r in rungs) r.id: r},
      scaffolding: Scaffolding.fromJson(json['scaffolding'] as Map<String, dynamic>),
      signalIds: List<String>.from(json['signals'] as List),
      progressionAdvanceParameter: json['progression']['advance_parameter'] as String,
      progressionRetreatParameter: json['progression']['retreat_parameter'] as String,
      transferProbes: (json['transfer_probes'] as List)
          .map((p) => TransferProbe.fromJson(p as Map<String, dynamic>))
          .toList(),
      ageRange: json['age_range'] == null ? const [2, 8] : List<int>.from(json['age_range'] as List),
      languageDependencies: List<String>.from((json['language_dependencies'] as List?) ?? const []),
      presentation: json['presentation'] != null
          ? GamePresentation.fromJson(json['presentation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TransferTask {
  const TransferTask({required this.id, required this.nameKey, required this.skillIds, required this.mechanicId});
  final String id;
  final String nameKey;
  final List<String> skillIds;
  final String mechanicId;

  factory TransferTask.fromJson(Map<String, dynamic> json) => TransferTask(
        id: json['id'] as String,
        nameKey: json['name_key'] as String,
        skillIds: List<String>.from(json['skills'] as List),
        mechanicId: json['mechanic_id'] as String,
      );
}

class Criterion {
  const Criterion({required this.description, required this.parameterIds, required this.requiresDimensions});
  final String description;
  final List<String> parameterIds;
  final List<String> requiresDimensions;

  factory Criterion.fromJson(Map<String, dynamic> json) => Criterion(
        description: json['description'] as String,
        parameterIds: List<String>.from(json['parameters'] as List),
        requiresDimensions: List<String>.from(json['requires_dimensions'] as List),
      );
}

class AssessmentRule {
  const AssessmentRule({required this.id, required this.skillId, required this.stateCriteria});
  final String id;
  final String skillId;
  final Map<String, Criterion> stateCriteria;

  factory AssessmentRule.fromJson(Map<String, dynamic> json) => AssessmentRule(
        id: json['id'] as String,
        skillId: json['skill'] as String,
        stateCriteria: (json['state_criteria'] as Map<String, dynamic>).map(
          (state, criterion) => MapEntry(state, Criterion.fromJson(criterion as Map<String, dynamic>)),
        ),
      );
}

class Parameter {
  const Parameter({required this.id, required this.value});
  final String id;
  final dynamic value;

  factory Parameter.fromJson(Map<String, dynamic> json) => Parameter(id: json['id'] as String, value: json['value']);
}

class Mechanic {
  const Mechanic({required this.id, required this.description});
  final String id;
  final String description;

  factory Mechanic.fromJson(Map<String, dynamic> json) => Mechanic(id: json['id'] as String, description: json['description'] as String);
}

class SignalDef {
  const SignalDef({required this.id, required this.kind, required this.description});
  final String id;
  final String kind; // 'learning' | 'engagement'
  final String description;

  factory SignalDef.fromJson(Map<String, dynamic> json) => SignalDef(
        id: json['id'] as String,
        kind: json['kind'] as String,
        description: json['description'] as String,
      );
}

class LangPack {
  const LangPack({required this.id, required this.direction});
  final String id;
  final String direction; // 'ltr' | 'rtl'

  factory LangPack.fromJson(Map<String, dynamic> json) => LangPack(
        id: json['id'] as String,
        direction: (json['script'] as Map<String, dynamic>)['direction'] as String,
      );
}

class ContentBundle {
  const ContentBundle({
    required this.schemaVersion,
    required this.contentVersion,
    required this.contentHash,
    required this.skills,
    required this.games,
    required this.transferTasks,
    required this.assessmentRules,
    required this.parameters,
    required this.langpacks,
    required this.mechanics,
    required this.signalDefs,
    required this.i18n,
    required this.audio,
    this.journeys = const [],
  });

  final String schemaVersion;
  final String contentVersion;
  final String contentHash;
  final List<Skill> skills;
  final List<Game> games;
  final List<TransferTask> transferTasks;
  final List<AssessmentRule> assessmentRules;
  final List<Parameter> parameters;
  final List<LangPack> langpacks;
  final List<Mechanic> mechanics;
  final List<SignalDef> signalDefs;
  final Map<String, Map<String, String>> i18n;
  final Map<String, Map<String, String>> audio;
  final List<Journey> journeys;

  factory ContentBundle.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
        (json[key] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    Map<String, Map<String, String>> stringTable(String key) =>
        (json[key] as Map<String, dynamic>).map(
          (language, table) => MapEntry(language, Map<String, String>.from(table as Map)),
        );

    return ContentBundle(
      schemaVersion: json['schemaVersion'] as String,
      contentVersion: json['contentVersion'] as String,
      contentHash: json['contentHash'] as String,
      skills: list('skills', Skill.fromJson),
      games: list('games', Game.fromJson),
      transferTasks: list('transfer_tasks', TransferTask.fromJson),
      assessmentRules: list('assessment_rules', AssessmentRule.fromJson),
      parameters: list('parameters', Parameter.fromJson),
      langpacks: list('langpacks', LangPack.fromJson),
      mechanics: list('mechanics', Mechanic.fromJson),
      signalDefs: list('signals', SignalDef.fromJson),
      i18n: stringTable('i18n'),
      audio: stringTable('audio'),
      journeys: json['journeys'] == null ? const [] : list('journeys', Journey.fromJson),
    );
  }
}

/// The level map for one age group (data/journeys). A level picks a game --
/// per language for literacy -- and, for counting games, a picture skin. It
/// never sets difficulty: the Adaptive Engine still chooses the rung.
class Journey {
  const Journey({required this.id, required this.nameKey, required this.ageRange, required this.levels});

  final String id;
  final String nameKey;
  final List<int> ageRange;
  final List<JourneyLevel> levels;

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
        id: json['id'] as String,
        nameKey: json['name_key'] as String,
        ageRange: List<int>.from((json['age_range'] as List).map((v) => (v as num).toInt())),
        levels: (json['levels'] as List).map((l) => JourneyLevel.fromJson(l as Map<String, dynamic>)).toList(),
      );
}

class JourneyLevel {
  const JourneyLevel({required this.id, this.gameId, this.gamesByLanguage = const {}, this.skin});

  final String id;
  final String? gameId;
  final Map<String, String> gamesByLanguage;
  final String? skin;

  /// The game this level plays for a child using [language].
  String gameFor(String language) => gameId ?? gamesByLanguage[language] ?? gamesByLanguage.values.first;

  factory JourneyLevel.fromJson(Map<String, dynamic> json) => JourneyLevel(
        id: json['id'] as String,
        gameId: json['game'] as String?,
        gamesByLanguage: json['games_by_language'] == null ? const {} : Map<String, String>.from(json['games_by_language'] as Map),
        skin: json['skin'] as String?,
      );
}
