import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/signals/signal.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';

ContentRuntime _runtimeWithSignals() {
  return ContentRuntime(ContentBundle.fromJson({
    'schemaVersion': '1.0.0', 'contentVersion': 't', 'contentHash': 't',
    'skills': [], 'games': [], 'transfer_tasks': [], 'assessment_rules': [],
    'parameters': [], 'langpacks': [], 'mechanics': [],
    'signals': [
      {'id': 'accuracy', 'kind': 'learning', 'description': 'x'},
      {'id': 'completion', 'kind': 'engagement', 'description': 'x'},
    ],
    'i18n': {'en': {}, 'ar': {}}, 'audio': {'en': {}, 'ar': {}},
  }));
}

void main() {
  test('a learning-kind signal id is returned and published as a LearningSignal', () {
    final content = _runtimeWithSignals();
    final bus = InMemorySignalBus();
    final collector = SignalCollector(content, bus);
    final published = <LearningSignal>[];
    bus.learningSignals.listen(published.add);

    final signal = collector.collect(
      sessionId: 's1', skillId: 'math.count.one-to-one-5',
      signalDefId: 'accuracy', value: 1.0, at: DateTime(2026, 1, 1),
    );

    expect(signal, isA<LearningSignal>());
  });

  test('an engagement-kind signal id is returned and published as an EngagementSignal, never a LearningSignal', () async {
    final content = _runtimeWithSignals();
    final bus = InMemorySignalBus();
    final collector = SignalCollector(content, bus);
    final learning = <LearningSignal>[];
    final engagement = <EngagementSignal>[];
    bus.learningSignals.listen(learning.add);
    bus.engagementSignals.listen(engagement.add);

    final signal = collector.collect(
      sessionId: 's1', skillId: 'math.count.one-to-one-5',
      signalDefId: 'completion', value: 1.0, at: DateTime(2026, 1, 1),
    );

    expect(signal, isA<EngagementSignal>());
    await Future<void>.delayed(Duration.zero);
    expect(engagement, hasLength(1));
    expect(learning, isEmpty);
  });
}
