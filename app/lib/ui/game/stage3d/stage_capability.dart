import 'protocol/stage_messages.dart';

enum GraphicsQualitySetting {
  auto,
  low,
  medium,
  high,
  twoDimensional;

  static GraphicsQualitySetting fromString(String val) {
    switch (val.toLowerCase()) {
      case 'low':
        return GraphicsQualitySetting.low;
      case 'medium':
        return GraphicsQualitySetting.medium;
      case 'high':
        return GraphicsQualitySetting.high;
      case '2d':
      case 'twodimensional':
        return GraphicsQualitySetting.twoDimensional;
      case 'auto':
      default:
        return GraphicsQualitySetting.auto;
    }
  }

  String toJson() {
    switch (this) {
      case GraphicsQualitySetting.twoDimensional:
        return '2d';
      default:
        return name;
    }
  }
}

class DeviceSignals {
  final int? ramMb;
  final bool isLowRamDevice;
  final bool isWeb;
  final bool isAndroid;
  final bool webGlAvailable;
  final String? gpuRenderer;

  const DeviceSignals({
    this.ramMb,
    this.isLowRamDevice = false,
    this.isWeb = false,
    this.isAndroid = false,
    this.webGlAvailable = true,
    this.gpuRenderer,
  });
}

class StageCapability {
  static const Set<String> _weakGpuKeywords = {
    'mali-400',
    'mali-450',
    'mali-t720',
    'mali-t820',
    'powervr sgx544',
    'powervr ge8300',
    'powervr ge8320',
    'adreno 304',
    'adreno 306',
    'adreno 308',
    'adreno 505',
    'adreno 506',
  };

  /// Decides if 3D should be used or if the app should fall back to 2D immediately.
  static bool shouldUse3D({
    required DeviceSignals signals,
    GraphicsQualitySetting setting = GraphicsQualitySetting.auto,
    bool hadContextLossTwice = false,
    bool lowTierBelowFloor = false,
  }) {
    if (setting == GraphicsQualitySetting.twoDimensional) {
      return false;
    }
    if (!signals.webGlAvailable || hadContextLossTwice || lowTierBelowFloor) {
      return false;
    }
    // Phase 1 target platforms are Web and Android. Other platforms fall back to 2D.
    if (!signals.isWeb && !signals.isAndroid) {
      return false;
    }
    return true;
  }

  /// Picks the starting quality tier.
  static QualityTier pickStartingTier({
    required DeviceSignals signals,
    GraphicsQualitySetting setting = GraphicsQualitySetting.auto,
    QualityTier? lastStableTier,
  }) {
    // 1. Explicit parent tier override
    switch (setting) {
      case GraphicsQualitySetting.low:
        return QualityTier.low;
      case GraphicsQualitySetting.medium:
        return QualityTier.medium;
      case GraphicsQualitySetting.high:
        return QualityTier.high;
      default:
        break;
    }

    // 2. Check GPU denylist
    if (signals.gpuRenderer != null) {
      final rendererLower = signals.gpuRenderer!.toLowerCase();
      for (final kw in _weakGpuKeywords) {
        if (rendererLower.contains(kw)) {
          return QualityTier.low;
        }
      }
    }

    // 3. Last remembered stable tier
    if (lastStableTier != null) {
      return lastStableTier;
    }

    // 4. Device hardware signals
    if (signals.isLowRamDevice) {
      return QualityTier.low;
    }

    final ram = signals.ramMb;
    if (ram != null) {
      if (ram <= 3072) {
        return QualityTier.low;
      }
      if (ram <= 6144) {
        return QualityTier.medium;
      }
      return QualityTier.high;
    }

    // 5. Default starting tier if RAM is not exposed (e.g. Safari web)
    return QualityTier.medium;
  }
}
