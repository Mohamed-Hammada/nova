import 'raw_events.dart';

/// The contract every reusable mechanic implements. Deliberately free of
/// any rendering concern: the Flutter/Flame-facing view lives in
/// app/lib/mechanics_flutter/ (Task 13), never here, so this contract is
/// what makes a mechanic reusable across games and skills (design doc
/// 2026-09-22, section 8.5 and section 9.1).
abstract class GameMechanic {
  String get mechanicId;
  Stream<RawMechanicEvent> get rawEvents;
  void start({required int rngSeed});
  void dispose();
}
