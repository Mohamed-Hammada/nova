import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/criterion_parameters.dart';
import 'package:nova_app/core/content/models.dart';

void main() {
  const params = {
    'p.min-trials': Parameter(id: 'p.min-trials', value: 6),
    'p.long-min-trials': Parameter(id: 'p.long-min-trials', value: 10),
    'p.secure-accuracy': Parameter(id: 'p.secure-accuracy', value: 0.85),
  };

  Criterion criterion(List<String> ids) => Criterion(description: 'x', parameterIds: ids, requiresDimensions: const []);

  test('resolves a parameter by its naming-convention marker', () {
    expect(criterionParameter(criterion(['p.min-trials', 'p.secure-accuracy']), params, 'accuracy'), 0.85);
  });

  test('returns null when the criterion lists no matching or no existing parameter', () {
    expect(criterionParameter(criterion(['p.secure-accuracy']), params, 'min-trials'), isNull);
    expect(criterionParameter(criterion(['p.missing-min-trials']), params, 'min-trials'), isNull);
  });

  test('minTrialsFor takes the largest min-trials across all state criteria', () {
    final rule = AssessmentRule(id: 'r', skillId: 's', stateCriteria: {
      'emerging': criterion(['p.min-trials']),
      'secure': criterion(['p.long-min-trials', 'p.secure-accuracy']),
    });
    expect(minTrialsFor(rule, params), 10);
  });

  test('minTrialsFor is null for a rule without any min-trials parameter', () {
    final rule = AssessmentRule(id: 'r', skillId: 's', stateCriteria: {'secure': criterion(['p.secure-accuracy'])});
    expect(minTrialsFor(rule, params), isNull);
  });
}
