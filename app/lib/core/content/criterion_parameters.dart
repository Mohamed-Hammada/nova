import 'models.dart';

/// Resolves the value of the parameter a Criterion lists whose id contains
/// [marker] -- the documented naming convention (`min-trials`, `accuracy`,
/// `hints-per-trial`, `adult-assist-per-trial`) that lets one engine read
/// every skill's thresholds from compiled data instead of hardcoding them.
/// Returns null when the criterion lists no such parameter.
num? criterionParameter(Criterion criterion, Map<String, Parameter> parameters, String marker) {
  for (final id in criterion.parameterIds) {
    if (id.contains(marker)) {
      final parameter = parameters[id];
      if (parameter != null) return parameter.value as num;
    }
  }
  return null;
}

/// The largest `min-trials` any of [rule]'s state criteria require, or null
/// when none lists one. A session that gathers at least this many trials
/// gives the Mastery Engine enough evidence to evaluate every state.
int? minTrialsFor(AssessmentRule rule, Map<String, Parameter> parameters) {
  int? result;
  for (final criterion in rule.stateCriteria.values) {
    final value = criterionParameter(criterion, parameters, 'min-trials');
    if (value != null && (result == null || value > result)) result = value.ceil();
  }
  return result;
}
