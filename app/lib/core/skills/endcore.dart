import 'skill_profile.dart';

/// Where a communication skill sits in the ENDCORE model (Fujimoto & Daibo,
/// 2007, The Japanese Journal of Personality 15(3), 347-361): three basic
/// skills underneath three interpersonal ones, in three systems.
///
///                    Expressing        Understanding        Managing
///   With others      assertion         other-acceptance     relationships
///   Basic            expressivity      decoding             self-control
///
/// The model was built with adults' self-reports; Nova uses it only as a map
/// for its child skills (what each looks like at 2-8 follows Takahashi et al.,
/// 2008). It is never shown as a score.
enum EndcoreLevel { basic, interpersonal }

enum EndcoreSystem { expressing, understanding, managing }

enum EndcoreSkill {
  expressivity(EndcoreLevel.basic, EndcoreSystem.expressing, ['sel.comm.expressivity']),
  decoding(EndcoreLevel.basic, EndcoreSystem.understanding, ['sel.emotion.faces', 'sel.emotion.situations']),
  selfControl(EndcoreLevel.basic, EndcoreSystem.managing, ['sel.comm.self-control']),
  assertion(EndcoreLevel.interpersonal, EndcoreSystem.expressing, ['sel.comm.assertion']),
  otherAcceptance(EndcoreLevel.interpersonal, EndcoreSystem.understanding, ['sel.comm.other-acceptance']),
  relationships(EndcoreLevel.interpersonal, EndcoreSystem.managing, ['sel.comm.relationships']);

  const EndcoreSkill(this.level, this.system, this.skillIds);
  final EndcoreLevel level;
  final EndcoreSystem system;

  /// Nova's skills that show this one in children.
  final List<String> skillIds;

  /// The basic skill an interpersonal one builds on (same system).
  EndcoreSkill? get foundation => level == EndcoreLevel.basic ? null : EndcoreSkill.values.firstWhere((s) => s.level == EndcoreLevel.basic && s.system == system);

  static EndcoreSkill at(EndcoreLevel level, EndcoreSystem system) => values.firstWhere((s) => s.level == level && s.system == system);

  /// Which cell a Nova skill belongs to, if any.
  static EndcoreSkill? of(String skillId) {
    for (final s in values) {
      if (s.skillIds.contains(skillId)) return s;
    }
    return null;
  }
}

/// One cell of the grid for a child: the most advanced state shown by any of
/// its skills that has evidence (null: nothing played yet), and whether that
/// evidence is still thin. Descriptive, never a score.
class EndcoreCell {
  const EndcoreCell(this.skill, this.state, {this.sessions = 0});
  final EndcoreSkill skill;
  final SkillState? state;
  final int sessions;

  static EndcoreCell from(EndcoreSkill skill, Map<String, SkillProfile> profiles) {
    SkillState? best;
    var sessions = 0;
    for (final id in skill.skillIds) {
      final p = profiles[id];
      if (p == null || !p.hasEvidence) continue;
      sessions += p.sessions;
      if (best == null || p.state.index > best.index) best = p.state;
    }
    return EndcoreCell(skill, best, sessions: sessions);
  }
}
