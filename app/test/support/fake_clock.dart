import 'package:nova_app/core/ports/clock_port.dart';

class FakeClock implements ClockPort {
  FakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}
