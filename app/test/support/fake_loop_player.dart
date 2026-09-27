import 'package:nova_app/core/ports/loop_audio_port.dart';

/// Records what the background audio service does with its players.
class FakeLoopPlayers {
  FakeLoopPlayers({this.missing = const {}});

  /// Assets that fail to load (as if not bundled).
  final Set<String> missing;
  final created = <FakeLoopPlayer>[];

  LoopPlayer call() {
    final p = FakeLoopPlayer(this);
    created.add(p);
    return p;
  }

  /// Players not yet disposed.
  List<FakeLoopPlayer> get alive => [for (final p in created) if (!p.disposed) p];

  /// Players alive and playing (not paused), with a loaded asset.
  List<FakeLoopPlayer> get playing => [for (final p in alive) if (p.playing && p.asset != null) p];

  List<FakeLoopPlayer> playingAsset(String asset) => [for (final p in playing) if (p.asset == asset) p];
}

class FakeLoopPlayer implements LoopPlayer {
  FakeLoopPlayer(this._owner);
  final FakeLoopPlayers _owner;
  String? asset;
  bool playing = false;
  bool disposed = false;
  double volume = 1;

  @override
  Future<bool> load(String assetPath) async {
    if (_owner.missing.contains(assetPath)) return false;
    asset = assetPath;
    return true;
  }

  @override
  void play() => playing = true;

  @override
  void pause() => playing = false;

  @override
  void setVolume(double v) => volume = v;

  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
  }
}
