import 'package:flutter/foundation.dart';

/// Voice answers and face play run only where they can run on the device
/// itself. On the web, speech recognition would send audio to a cloud
/// service and there is no on-device face detector, so both stay off there.
bool get voiceAnswersSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

bool get facePlaySupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
