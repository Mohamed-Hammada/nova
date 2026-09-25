import 'models.dart';

/// Read-only, in-memory index over a compiled ContentBundle. Every accessor
/// is a map lookup; nothing here parses YAML, validates a schema, or does
/// I/O (design doc 2026-09-22, section 4 and section 8.1).
class ContentRuntime {
  ContentRuntime(this._bundle)
      : _skillsById = {for (final s in _bundle.skills) s.id: s},
        _gamesById = {for (final g in _bundle.games) g.id: g},
        _tasksById = {for (final t in _bundle.transferTasks) t.id: t},
        _rulesBySkillId = {for (final r in _bundle.assessmentRules) r.skillId: r},
        _parametersById = {for (final p in _bundle.parameters) p.id: p},
        _mechanicsById = {for (final m in _bundle.mechanics) m.id: m},
        _signalsById = {for (final s in _bundle.signalDefs) s.id: s},
        _langpacksById = {for (final l in _bundle.langpacks) l.id: l};

  final ContentBundle _bundle;
  final Map<String, Skill> _skillsById;
  final Map<String, Game> _gamesById;
  final Map<String, TransferTask> _tasksById;
  final Map<String, AssessmentRule> _rulesBySkillId;
  final Map<String, Parameter> _parametersById;
  final Map<String, Mechanic> _mechanicsById;
  final Map<String, SignalDef> _signalsById;
  final Map<String, LangPack> _langpacksById;

  String get contentVersion => _bundle.contentVersion;
  String get schemaVersion => _bundle.schemaVersion;
  String get contentHash => _bundle.contentHash;

  /// Every game in the bundle, in bundle order.
  List<Game> get games => List.unmodifiable(_bundle.games);

  bool hasSkill(String id) => _skillsById.containsKey(id);

  Skill skill(String id) => _skillsById[id] ?? (throw ArgumentError('no such skill: $id'));
  List<Journey> get journeys => _bundle.journeys;

  /// The journey whose age range contains [age], if any.
  Journey? journeyForAge(int age) {
    for (final j in _bundle.journeys) {
      if (j.ageRange.first <= age && age <= j.ageRange.last) return j;
    }
    return null;
  }

  bool hasGame(String id) => _gamesById.containsKey(id);

  Game game(String id) => _gamesById[id] ?? (throw ArgumentError('no such game: $id'));
  TransferTask transferTask(String id) => _tasksById[id] ?? (throw ArgumentError('no such transfer task: $id'));

  /// A transfer probe's task_ref resolves against BOTH games and transfer
  /// tasks (confirmed against tools/validate/nova_validate/coverage_rules.py
  /// -- see the design doc, section 7's note). Callers switch on the
  /// runtime type of the result.
  Object probeTarget(String taskRef) {
    final game = _gamesById[taskRef];
    if (game != null) return game;
    final task = _tasksById[taskRef];
    if (task != null) return task;
    throw ArgumentError('task_ref resolves to neither a game nor a transfer task: $taskRef');
  }

  List<Game> gamesForSkill(String skillId) =>
      _bundle.games.where((g) => g.primarySkillIds.contains(skillId)).toList();

  AssessmentRule assessmentRuleFor(String skillId) =>
      _rulesBySkillId[skillId] ?? (throw ArgumentError('no assessment rule for skill: $skillId'));

  Parameter parameter(String id) => _parametersById[id] ?? (throw ArgumentError('no such parameter: $id'));
  Map<String, Parameter> allParameters() => _parametersById;

  Mechanic mechanic(String id) => _mechanicsById[id] ?? (throw ArgumentError('no such mechanic: $id'));
  SignalDef signalDef(String id) => _signalsById[id] ?? (throw ArgumentError('no such signal: $id'));
  LangPack langPack(String language) => _langpacksById[language] ?? (throw ArgumentError('no such langpack: $language'));

  String i18n(String key, String language) => _bundle.i18n[language]?[key] ?? key;
  String? audioAsset(String key, String language) => _bundle.audio[language]?[key];
}
