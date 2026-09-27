import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/skills/skill_graph.dart';
import 'package:nova_app/core/skills/skill_profile.dart';

import '../../support/fixture_content.dart';

void main() {
  final graph = SkillGraph.fromContent(loadRealBundle());
  SkillProfile p(String id, SkillState state, {int sessions = 1}) => SkillProfile(skillId: id, state: state, sessions: sessions);

  test('the graph is built from the curriculum\'s skill prerequisites', () {
    expect(graph.prerequisitesOf('math.count.cardinality'), ['math.count.one-to-one-5']);
    expect(graph.prerequisitesOf('math.compare.more-fewer'), ['math.count.one-to-one-5']);
    expect(graph.dependentsOf('math.count.one-to-one-5'), containsAll(['math.count.cardinality', 'math.compare.more-fewer']));
    expect(graph.ancestorsOf('math.add-sub.within-20'), containsAll(['math.add-sub.within-10', 'math.count.cardinality', 'math.count.one-to-one-5']));
  });

  test('dependency order puts every skill after its prerequisites', () {
    final order = graph.ordered();
    for (final s in order) {
      for (final pre in graph.prerequisitesOf(s)) {
        expect(order.indexOf(pre), lessThan(order.indexOf(s)), reason: '$pre before $s');
      }
    }
  });

  test('missing prerequisite evidence, readiness, and the next skills', () {
    const cardinality = 'math.count.cardinality';
    expect(graph.missingPrerequisites(cardinality, const {}), ['math.count.one-to-one-5']);
    expect(graph.isReady(cardinality, {'math.count.one-to-one-5': p('math.count.one-to-one-5', SkillState.developing)}), isTrue);
    final next = graph.nextSkills({'math.count.one-to-one-5': p('math.count.one-to-one-5', SkillState.secure)});
    expect(next, containsAll([cardinality, 'math.compare.more-fewer']));
    expect(next, isNot(contains('math.count.one-to-one-5')), reason: 'already secure');
    expect(next, isNot(contains('math.add-sub.within-10')), reason: 'its prerequisite has no evidence yet');
  });

  test('reinforcement: a hard skill points back to the prerequisites the child finds hard', () {
    final profiles = {
      'math.count.one-to-one-5': p('math.count.one-to-one-5', SkillState.emerging),
      'math.compare.more-fewer': p('math.compare.more-fewer', SkillState.emerging),
    };
    expect(graph.reinforcementFor('math.compare.more-fewer', profiles), ['math.count.one-to-one-5']);
    expect(graph.weakPrerequisites('math.compare.more-fewer', profiles), ['math.count.one-to-one-5']);
    // A prerequisite never played is missing evidence, not a weakness.
    expect(graph.weakPrerequisites('math.compare.more-fewer', const {}), isEmpty);
  });
}
