import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:nova_app/core/ports/face_sensor_port.dart';
import 'package:nova_app/core/ports/voice_input_port.dart';
import 'package:speech_to_text/speech_to_text.dart';

VoiceInputPort createVoiceInput() => (Platform.isAndroid || Platform.isIOS) ? SpeechVoiceInput() : const NoVoiceInput();
FaceSensorPort createFaceSensor() => (Platform.isAndroid || Platform.isIOS) ? MlKitFaceSensor() : const NoFaceSensor();

/// Speech recognition that is required to run on the device
/// (SpeechListenOptions.onDevice). If the device can only recognise speech
/// through a cloud service, listening fails and voice answers stay off.
class SpeechVoiceInput implements VoiceInputPort {
  final _stt = SpeechToText();
  bool _ready = false;

  String _locale(String language) => language == 'ar' ? 'ar-SA' : 'en-US';

  @override
  Future<bool> prepare({required String language}) async {
    try {
      _ready = _ready || await _stt.initialize();
      if (!_ready) return false;
      final locales = await _stt.locales();
      final prefix = language == 'ar' ? 'ar' : 'en';
      return locales.any((l) => l.localeId.toLowerCase().startsWith(prefix));
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> listen({required String language, Duration max = const Duration(seconds: 5)}) async {
    if (!_ready && !await prepare(language: language)) return null;
    final done = Completer<String?>();
    try {
      await _stt.listen(
        onResult: (r) {
          if (r.finalResult && !done.isCompleted) done.complete(r.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          onDevice: true,
          partialResults: false,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          listenFor: max,
          pauseFor: const Duration(seconds: 2),
          localeId: _locale(language),
        ),
      );
    } catch (_) {
      return null;
    }
    return done.future.timeout(
      max + const Duration(seconds: 2),
      onTimeout: () {
        _stt.stop();
        return _stt.lastRecognizedWords.isEmpty ? null : _stt.lastRecognizedWords;
      },
    );
  }

  @override
  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } catch (_) {}
  }
}

/// Front camera at low resolution, frames handed straight to ML Kit's
/// on-device face detector (bundled model). Frames are dropped as soon as
/// they are read; nothing is saved, shown or sent.
class MlKitFaceSensor implements FaceSensorPort {
  final _out = StreamController<FaceReading>.broadcast();
  final _detector = FaceDetector(options: FaceDetectorOptions(enableClassification: true, performanceMode: FaceDetectorMode.fast, minFaceSize: 0.2));
  CameraController? _camera;
  bool _busy = false;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Stream<FaceReading> get readings => _out.stream;

  @override
  Future<bool> start() async {
    if (_camera != null) return true;
    try {
      final cameras = await availableCameras();
      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull;
      if (front == null) return false;
      final camera = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await camera.initialize(); // asks for camera permission; throws if refused
      _camera = camera;
      await camera.startImageStream((image) => _onFrame(image, front));
      return true;
    } catch (e) {
      debugPrint('Face play unavailable: $e');
      await stop();
      return false;
    }
  }

  Future<void> _onFrame(CameraImage image, CameraDescription camera) async {
    // About six looks a second is plenty for a character to react.
    final now = DateTime.now();
    if (_busy || now.difference(_last).inMilliseconds < 160) return;
    _busy = true;
    _last = now;
    try {
      final input = _toInputImage(image, camera);
      if (input == null) return;
      final faces = await _detector.processImage(input);
      if (faces.isEmpty) {
        _out.add(FaceReading.absent);
        return;
      }
      final f = faces.reduce((a, b) => a.boundingBox.width > b.boundingBox.width ? a : b);
      final rotated = camera.sensorOrientation % 180 != 0;
      final w = (rotated ? image.height : image.width).toDouble();
      final h = (rotated ? image.width : image.height).toDouble();
      final c = f.boundingBox.center;
      _out.add(
        FaceReading(
          present: true,
          x: -((c.dx / w) * 2 - 1), // mirror the front camera
          y: (c.dy / h) * 2 - 1,
          smile: f.smilingProbability ?? 0,
          eyesOpen: ((f.leftEyeOpenProbability ?? 1) + (f.rightEyeOpenProbability ?? 1)) / 2,
        ),
      );
    } catch (_) {
      // Skip a bad frame.
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null || image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Future<void> stop() async {
    final camera = _camera;
    _camera = null;
    try {
      if (camera != null && camera.value.isStreamingImages) await camera.stopImageStream();
      await camera?.dispose();
    } catch (_) {}
  }
}
