import 'package:nova_app/core/content/content_runtime.dart';

import 'signal.dart';
import 'signal_bus.dart';

/// Converts a raw gameplay value into a canonical, correctly-typed Signal,
/// looking up its kind from the compiled signal vocabulary. This is the one
/// place a signal's `learning`/`engagement` kind is decided; every consumer
/// downstream gets the type-level guarantee for free.
class SignalCollector {
  SignalCollector(this._content, this._bus);

  final ContentRuntime _content;
  final SignalBus _bus;
  int _counter = 0;

  Signal collect({
    required String sessionId,
    required String skillId,
    required String signalDefId,
    required num value,
    required DateTime at,
  }) {
    final def = _content.signalDef(signalDefId);
    final id = '$sessionId:$signalDefId:${_counter++}';
    final signal = def.kind == 'learning'
        ? LearningSignal(id: id, sessionId: sessionId, skillId: skillId, signalDefId: signalDefId, value: value, at: at)
        : EngagementSignal(id: id, sessionId: sessionId, skillId: skillId, signalDefId: signalDefId, value: value, at: at);
    _bus.publish(signal);
    return signal;
  }
}
