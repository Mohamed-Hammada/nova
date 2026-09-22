import 'package:nova_app/core/ports/clock_port.dart';

class SystemClock implements ClockPort {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}
