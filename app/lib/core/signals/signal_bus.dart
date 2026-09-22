import 'dart:async';

import 'signal.dart';

abstract class SignalBus {
  Stream<LearningSignal> get learningSignals;
  Stream<EngagementSignal> get engagementSignals;
  void publish(Signal signal);
  void dispose();
}

class InMemorySignalBus implements SignalBus {
  final _learning = StreamController<LearningSignal>.broadcast();
  final _engagement = StreamController<EngagementSignal>.broadcast();

  @override
  Stream<LearningSignal> get learningSignals => _learning.stream;

  @override
  Stream<EngagementSignal> get engagementSignals => _engagement.stream;

  @override
  void publish(Signal signal) {
    switch (signal) {
      case LearningSignal s:
        _learning.add(s);
      case EngagementSignal s:
        _engagement.add(s);
    }
  }

  @override
  void dispose() {
    _learning.close();
    _engagement.close();
  }
}
