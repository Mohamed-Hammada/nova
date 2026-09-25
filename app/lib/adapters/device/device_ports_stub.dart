import 'package:nova_app/core/ports/face_sensor_port.dart';
import 'package:nova_app/core/ports/voice_input_port.dart';

VoiceInputPort createVoiceInput() => const NoVoiceInput();
FaceSensorPort createFaceSensor() => const NoFaceSensor();
