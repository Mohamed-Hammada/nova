import 'package:nova_app/core/content/content_runtime.dart';

import 'skill_profile.dart';

/// The curriculum's skill prerequisites as a dependency graph: an internal
/// intelligence layer for the recommendation engine. It never opens
/// anything -- the child still follows the journey, and curriculum
/// eligibility always comes first.
///
///     math.count.one-to-one-5
///        -> math.count.cardinality -> math.add-sub.within-10 -> ...
///        -> math.compare.more-fewer
class SkillGraph {
  SkillGraph(Map<String, List<String>> prerequisites)
      : _prerequisites = {for (final e in prerequisites.entries) e.key: List.unmodifiable(e.value)},
        _dependents = _invert(prerequisites);

  factory SkillGraph.fromContent(ContentRuntime content) {
    final ids = {for (final g in content.games) ...g.primarySkillIds};
    final map = <String, List<String>>{};
    final queue = [...ids];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (map.containsKey(id) || !content.hasSkill(id)) continue;
      final prereqs = content.skill(id).prerequisiteSkillIds;
      map[id] = prereqs;
      queue.addAll(prereqs);
    }
    return SkillGraph(map);
  }

  /// No skills, no prerequisites (a bundle without skill data, or tests).
  static final empty = SkillGraph(const {});

  final Map<String, List<String>> _prerequisites;
  final Map<String, List<String>> _dependents;

  static Map<String, List<String>> _invert(Map<String, List<String>> prerequisites) {
    final out = <String, List<String>>{};
    for (final e in prerequisites.entries) {
      for (final p in e.value) {
        out.putIfAbsent(p, () => []).add(e.key);
      }
    }
    return out;
  }

  Iterable<String> get skills => _prerequisites.keys;

  List<String> prerequisitesOf(String skill) => _prerequisites[skill] ?? const [];
  List<String> dependentsOf(String skill) => _dependents[skill] ?? const [];

  /// Every skill [skill] builds on, directly or not.
  Set<String> ancestorsOf(String skill) {
    final out = <String>{};
    final queue = [...prerequisitesOf(skill)];
    while (queue.isNotEmpty) {
      final s = queue.removeLast();
      if (out.add(s)) queue.addAll(prerequisitesOf(s));
    }
    return out;
  }

  /// Direct prerequisites without the evidence the skill needs to build on:
  /// played, and at least Developing. A prerequisite never played is
  /// "missing evidence" rather than a failure.
  List<String> missingPrerequisites(String skill, Map<String, SkillProfile> profiles) => [
        for (final p in prerequisitesOf(skill))
          if (!((profiles[p]?.state ?? SkillState.notYet) >= SkillState.developing)) p,
      ];

  /// Prerequisites the child has played and found hard: evidence that the
  /// skill on top is being built on sand.
  List<String> weakPrerequisites(String skill, Map<String, SkillProfile> profiles) => [
        for (final p in prerequisitesOf(skill))
          if (profiles[p] case final profile? when profile.hasEvidence && profile.needsPractice) p,
      ];

  bool isReady(String skill, Map<String, SkillProfile> profiles) => missingPrerequisites(skill, profiles).isEmpty;

  /// Skills not yet secure whose prerequisites are all in place: where the
  /// child can grow next.
  List<String> nextSkills(Map<String, SkillProfile> profiles) => [
        for (final s in skills)
          if (((profiles[s]?.state ?? SkillState.notYet) < SkillState.secure) && isReady(s, profiles)) s,
      ];

  /// Skills worth reinforcing for [skill]: its prerequisites (all the way
  /// down) that the child has played and still needs practice in.
  List<String> reinforcementFor(String skill, Map<String, SkillProfile> profiles) => [
        for (final p in ancestorsOf(skill))
          if (profiles[p] case final profile? when profile.hasEvidence && profile.needsPractice) p,
      ];

  /// Skills in dependency order: every skill after its prerequisites.
  List<String> ordered() {
    final out = <String>[];
    final seen = <String>{};
    void visit(String s) {
      if (!seen.add(s)) return;
      for (final p in prerequisitesOf(s)) {
        visit(p);
      }
      out.add(s);
    }

    for (final s in [..._prerequisites.keys]..sort()) {
      visit(s);
    }
    return out;
  }
}
