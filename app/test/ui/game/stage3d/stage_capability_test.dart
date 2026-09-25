import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/stage3d/protocol/stage_messages.dart';
import 'package:nova_app/ui/game/stage3d/stage_capability.dart';

void main() {
  group('StageCapability', () {
    test('shouldUse3D returns true for Web or Android with WebGL available', () {
      expect(
        StageCapability.shouldUse3D(
          signals: const DeviceSignals(isWeb: true, webGlAvailable: true),
        ),
        isTrue,
      );
      expect(
        StageCapability.shouldUse3D(
          signals: const DeviceSignals(isAndroid: true, webGlAvailable: true),
        ),
        isTrue,
      );
    });

    test('shouldUse3D falls back to 2D for 2D setting or unsupported platform', () {
      expect(
        StageCapability.shouldUse3D(
          signals: const DeviceSignals(isWeb: true, webGlAvailable: true),
          setting: GraphicsQualitySetting.twoDimensional,
        ),
        isFalse,
      );
      // Desktop / other platforms
      expect(
        StageCapability.shouldUse3D(
          signals: const DeviceSignals(isWeb: false, isAndroid: false, webGlAvailable: true),
        ),
        isFalse,
      );
    });

    test('shouldUse3D falls back to 2D if WebGL lost twice or low tier below floor', () {
      expect(
        StageCapability.shouldUse3D(
          signals: const DeviceSignals(isWeb: true, webGlAvailable: true),
          hadContextLossTwice: true,
        ),
        isFalse,
      );
      expect(
        StageCapability.shouldUse3D(
          signals: const DeviceSignals(isWeb: true, webGlAvailable: true),
          lowTierBelowFloor: true,
        ),
        isFalse,
      );
    });

    test('pickStartingTier respects parent override', () {
      const signals = DeviceSignals(isAndroid: true, ramMb: 8192);
      expect(
        StageCapability.pickStartingTier(
          signals: signals,
          setting: GraphicsQualitySetting.low,
        ),
        QualityTier.low,
      );
    });

    test('pickStartingTier selects Low for low-RAM or weak GPU', () {
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(isAndroid: true, ramMb: 2048),
        ),
        QualityTier.low,
      );
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(isAndroid: true, isLowRamDevice: true, ramMb: 6144),
        ),
        QualityTier.low,
      );
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(
            isAndroid: true,
            ramMb: 6144,
            gpuRenderer: 'ARM Mali-T720',
          ),
        ),
        QualityTier.low,
      );
    });

    test('pickStartingTier selects Medium for 4-6GB RAM and High for 8GB+ RAM', () {
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(isAndroid: true, ramMb: 4096),
        ),
        QualityTier.medium,
      );
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(isWeb: true, ramMb: 8192),
        ),
        QualityTier.high,
      );
    });

    test('pickStartingTier defaults to Medium if RAM is unknown', () {
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(isWeb: true),
        ),
        QualityTier.medium,
      );
    });

    test('pickStartingTier uses lastStableTier when present', () {
      expect(
        StageCapability.pickStartingTier(
          signals: const DeviceSignals(isWeb: true, ramMb: 8192),
          lastStableTier: QualityTier.medium,
        ),
        QualityTier.medium,
      );
    });
  });
}
