import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/journey/curriculum_engine.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/journey/journey_recorder.dart';
import 'package:nova_app/providers.dart';

import '../settings/settings_sync.dart';

/// The whole curriculum, from the content bundle.
final curriculumProvider = Provider<Curriculum>((ref) => Curriculum.fromContent(ref.watch(contentRuntimeProvider)));

final curriculumEngineProvider = Provider<CurriculumEngine>((ref) => CurriculumEngine(ref.watch(curriculumProvider)));

final journeyRecorderProvider = Provider<JourneyRecorder>(
  (ref) => JourneyRecorder(ref.watch(playerStatePortProvider), ref.watch(curriculumProvider), now: ref.watch(clockPortProvider).now),
);

/// Best stars per journey level (the child's reward shelf).
final levelStarsProvider = FutureProvider<Map<String, int>>((ref) => ref.watch(playerStatePortProvider).levelStars(childId: currentChildId));

/// The child's activity records, by activity id. Invalidate after a play.
final activityRecordsProvider = FutureProvider<Map<String, ActivityRecord>>((ref) async {
  final records = await ref.watch(playerStatePortProvider).activityRecords(childId: currentChildId);
  return {for (final r in records) r.activityId: r};
});

/// The Mastery Engine's state for every skill in the curriculum, read
/// through GameRuntime (never PersistencePort directly). Invalidate after
/// a play.
final childEvidenceProvider = FutureProvider<ChildEvidence>((ref) async {
  final runtime = ref.watch(gameRuntimeProvider);
  final skills = {for (final a in ref.watch(curriculumProvider).activities) ...a.skills};
  final mastery = <String, String?>{};
  for (final skill in skills) {
    final record = await runtime.currentMastery(childId: currentChildId, skillId: skill);
    if (record != null) mastery[skill] = record.state;
  }
  return ChildEvidence(masteryBySkill: mastery);
});

/// The child's profile, once they have told Nova their age (null before
/// onboarding).
final childProfileProvider = Provider<ChildProfile?>((ref) {
  final age = ref.watch(childAgeProvider);
  if (age == null) return null;
  return ChildProfile(id: currentChildId, name: ref.watch(childNameProvider).trim(), age: age);
});

/// The journey as the curriculum engine sees it right now (null before
/// onboarding, while records load, or when the bundle has no curriculum).
final journeyProgressProvider = Provider<JourneyProgress?>((ref) {
  final profile = ref.watch(childProfileProvider);
  final curriculum = ref.watch(curriculumProvider);
  final records = ref.watch(activityRecordsProvider).value;
  if (profile == null || records == null || curriculum.isEmpty) return null;
  // The one source of truth for "what next": Home, the map and the stage
  // screens all read this.
  final evidence = ref.watch(childEvidenceProvider).value ?? const ChildEvidence();
  return ref.watch(curriculumEngineProvider).evaluate(profile, records, evidence: evidence);
});

/// Sets the child's chronological age (onboarding, "About me", or a
/// grown-up in settings). Only this changes the age; journey progress
/// never does. Records are untouched, so the journey re-positions from
/// the same history.
void setChildAge(WidgetRef ref, int age) {
  ref.read(childAgeProvider.notifier).state = age;
  ref.read(ageBandProvider.notifier).state = bandForAge(age);
}
