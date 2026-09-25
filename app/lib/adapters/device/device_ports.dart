// Voice and face adapters exist only for Android and iOS, where speech and
// faces can be recognised on the device. The web build gets stubs, so the
// native-only plugins never enter it.
export 'device_ports_stub.dart' if (dart.library.io) 'device_ports_native.dart';
