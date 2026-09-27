import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/ports/loop_audio_port.dart';
import 'package:nova_app/providers.dart';

/// Where the child is, as the background hears it: one music track and one
/// ambience bed per place of the Nova world, plus Home. The Journey decides
/// the place (a stage is set in one); the child never picks it.
class AudioScene {
  const AudioScene._(this.id);
  final String id;

  static const home = AudioScene._('home');

  /// The places stages are set in (data/journeys), each with its own sound.
  static const places = {'numbers', 'language', 'sounds', 'feelings', 'memory', 'discovery', 'movement'};

  /// The scene of a stage's place; an unknown place sounds like Home.
  static AudioScene forPlace(String? place) => places.contains(place) ? AudioScene._(place!) : home;

  String get music => 'assets/audio/music/$id.mp3';
  String get ambience => 'assets/audio/ambience/$id.mp3';

  @override
  bool operator ==(Object other) => other is AudioScene && other.id == id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => 'AudioScene($id)';
}

enum AudioLayer { music, ambience }

/// Plays the background: a looping music track and a looping ambience bed,
/// crossfading when the scene changes. Separate from sound effects and
/// narration, which have their own players.
///
/// - Never more than one player per layer, plus -- during a crossfade --
///   the one fading out; a new change finishes any old fade at once.
/// - A missing or undecodable asset leaves that layer silent.
/// - Nothing here blocks: loads and fades run on their own.
/// - During play the music is ducked (quieter) under the game's sounds.
/// - Switched off, every player is released; switched on, the current
///   scene starts again. Paused (app in the background), players are kept.
class BackgroundAudioService {
  BackgroundAudioService({
    required LoopPlayer Function() createPlayer,
    this.fade = const Duration(milliseconds: 1200),
    this.musicVolume = 0.32,
    this.ambienceVolume = 0.45,
    this.duckedMusicVolume = 0.1,
    this.duckedAmbienceVolume = 0.25,
  }) : _create = createPlayer;

  final LoopPlayer Function() _create;
  final Duration fade;
  final double musicVolume;
  final double ambienceVolume;
  final double duckedMusicVolume;
  final double duckedAmbienceVolume;

  final _layers = {for (final l in AudioLayer.values) l: _Layer()};
  AudioScene? _scene;
  bool _enabled = true;
  bool _paused = false;
  bool _ducked = false;
  bool _disposed = false;

  AudioScene? get scene => _scene;
  bool get enabled => _enabled;
  bool get paused => _paused;
  bool get ducked => _ducked;

  /// The asset a layer is playing (or loading) now; null when silent.
  String? track(AudioLayer layer) => _layers[layer]!.asset;

  /// Players alive right now, including one fading out.
  int get livePlayers => _layers.values.fold(0, (a, l) => a + (l.current == null ? 0 : 1) + (l.fadingOut == null ? 0 : 1));

  double _target(AudioLayer layer) => switch (layer) {
        AudioLayer.music => _ducked ? duckedMusicVolume : musicVolume,
        AudioLayer.ambience => _ducked ? duckedAmbienceVolume : ambienceVolume,
      };

  String _asset(AudioScene scene, AudioLayer layer) => layer == AudioLayer.music ? scene.music : scene.ambience;

  /// Moves to [scene] (crossfading), ducked for play or not.
  void setScene(AudioScene scene, {bool ducked = false}) {
    if (_disposed) return;
    final changed = scene != _scene;
    _scene = scene;
    final duckChanged = ducked != _ducked;
    _ducked = ducked;
    if (!_enabled) return;
    for (final layer in AudioLayer.values) {
      if (changed || _layers[layer]!.asset == null) {
        _switch(layer, _asset(scene, layer));
      } else if (duckChanged) {
        _ramp(layer);
      }
    }
  }

  /// The grown-up's Music switch: off releases every player, on restarts the
  /// current scene.
  void setEnabled(bool on) {
    if (_disposed || on == _enabled) return;
    _enabled = on;
    if (!on) {
      for (final layer in AudioLayer.values) {
        _switch(layer, null);
      }
    } else if (_scene != null) {
      final scene = _scene!;
      _scene = null;
      setScene(scene, ducked: _ducked);
    }
  }

  /// The app went to the background: hold everything where it is.
  void pause() {
    if (_paused) return;
    _paused = true;
    for (final l in _layers.values) {
      l.current?.pause();
      l.fadingOut?.pause();
    }
  }

  /// Back in the foreground: carry on, if music is on.
  void resume() {
    if (!_paused) return;
    _paused = false;
    if (!_enabled) return;
    for (final l in _layers.values) {
      if (l.ready) l.current?.play();
    }
  }

  /// Asks the players to play again: on the web a browser refuses sound
  /// until the first tap, so every tap is a chance to start.
  void nudge() {
    if (_disposed || _paused || !_enabled) return;
    for (final l in _layers.values) {
      if (l.ready) l.current?.play();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final l in _layers.values) {
      l.timer?.cancel();
      await l.fadingOut?.dispose();
      await l.current?.dispose();
      l.current = l.fadingOut = null;
    }
  }

  void _switch(AudioLayer layer, String? asset) {
    final l = _layers[layer]!;
    if (asset != null && asset == l.asset && l.current != null) {
      _ramp(layer);
      return;
    }
    final generation = ++l.generation;
    // Only one fade at a time: an older one finishes now.
    l.timer?.cancel();
    l.timer = null;
    final stale = l.fadingOut;
    l.fadingOut = null;
    stale?.dispose();

    l.fadingOut = l.current;
    l.fadingVolume = l.volume;
    l.current = null;
    l.ready = false;
    l.asset = asset;
    l.volume = 0;
    if (asset == null) {
      _crossfade(layer, generation);
      return;
    }
    final player = _create();
    l.current = player;
    player.load(asset).then((ok) {
      if (_disposed || generation != l.generation) {
        player.dispose();
        return;
      }
      if (!ok) {
        // Missing asset: silent layer, but the old one still fades away.
        l.current = null;
        player.dispose();
        _crossfade(layer, generation);
        return;
      }
      l.ready = true;
      player.setVolume(0);
      if (!_paused && _enabled) player.play();
      _crossfade(layer, generation);
    });
  }

  /// Fades the new player in and the old one out, then releases the old.
  void _crossfade(AudioLayer layer, int generation) {
    final l = _layers[layer]!;
    final target = l.current == null ? 0.0 : _target(layer);
    _fade(l, from: l.volume, to: target, outFrom: l.fadingOut == null ? null : l.fadingVolume, generation: generation);
  }

  /// A new volume for the current player (ducking), no track change.
  void _ramp(AudioLayer layer) {
    final l = _layers[layer]!;
    if (l.current == null || !l.ready) return;
    _fade(l, from: l.volume, to: _target(layer), outFrom: null, generation: l.generation);
  }

  void _fade(_Layer l, {required double from, required double to, required double? outFrom, required int generation}) {
    l.timer?.cancel();
    void finish() {
      l.timer = null;
      l.volume = to;
      l.current?.setVolume(to);
      final old = l.fadingOut;
      l.fadingOut = null;
      old?.dispose();
    }

    if (fade == Duration.zero || (l.current == null && l.fadingOut == null)) {
      finish();
      return;
    }
    const tick = Duration(milliseconds: 50);
    final steps = (fade.inMilliseconds / tick.inMilliseconds).ceil().clamp(1, 1000);
    var i = 0;
    l.timer = Timer.periodic(tick, (t) {
      if (_disposed || generation != l.generation) {
        t.cancel();
        return;
      }
      i++;
      final k = i / steps;
      l.volume = from + (to - from) * k;
      l.current?.setVolume(l.volume);
      if (outFrom != null) l.fadingOut?.setVolume(outFrom * (1 - k));
      if (i >= steps) {
        t.cancel();
        finish();
      }
    });
  }
}

class _Layer {
  LoopPlayer? current;
  LoopPlayer? fadingOut;
  String? asset;
  bool ready = false;
  double volume = 0;
  double fadingVolume = 0;
  int generation = 0;
  Timer? timer;
}

/// The one background audio service for the app's lifetime.
final backgroundAudioProvider = Provider<BackgroundAudioService>((ref) {
  final create = ref.watch(loopPlayerFactoryProvider) ?? () => const SilentLoopPlayer();
  final service = BackgroundAudioService(createPlayer: create);
  ref.onDispose(service.dispose);
  return service;
});

/// Follows the screens: each screen that has a sound of its own marks it
/// (AudioSceneMarker), and the innermost marked screen still on the
/// navigation stack decides the scene. Also pauses with the app, resumes
/// with it, follows the Music switch, and -- on the web -- starts sound on
/// the first tap.
class BackgroundAudioDirector extends ConsumerStatefulWidget {
  const BackgroundAudioDirector({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BackgroundAudioDirector> createState() => _BackgroundAudioDirectorState();
}

class _SceneEntry {
  _SceneEntry(this.scene, this.ducked);
  AudioScene scene;
  bool ducked;
}

class _BackgroundAudioDirectorState extends ConsumerState<BackgroundAudioDirector> {
  final _stack = <_SceneEntry>[];
  late final AppLifecycleListener _lifecycle;
  late final BackgroundAudioService _service = ref.read(backgroundAudioProvider);

  @override
  void initState() {
    super.initState();
    _service.setEnabled(ref.read(musicEnabledProvider));
    _lifecycle = AppLifecycleListener(onStateChange: (state) {
      switch (state) {
        case AppLifecycleState.resumed:
          _service.resume();
        case AppLifecycleState.inactive || AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
          _service.pause();
      }
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Object push(AudioScene scene, bool ducked) {
    final entry = _SceneEntry(scene, ducked);
    _stack.add(entry);
    _apply();
    return entry;
  }

  void update(Object token, AudioScene scene, bool ducked) {
    final entry = token as _SceneEntry;
    entry
      ..scene = scene
      ..ducked = ducked;
    _apply();
  }

  void pop(Object token) {
    _stack.remove(token);
    _apply();
  }

  void _apply() {
    if (_stack.isEmpty) return;
    final top = _stack.last;
    _service.setScene(top.scene, ducked: top.ducked);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(musicEnabledProvider, (_, on) => _service.setEnabled(on));
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _service.nudge(),
      child: _DirectorScope(state: this, child: widget.child),
    );
  }
}

class _DirectorScope extends InheritedWidget {
  const _DirectorScope({required this.state, required super.child});
  final _BackgroundAudioDirectorState state;
  @override
  bool updateShouldNotify(_DirectorScope old) => old.state != state;
}

/// Marks a screen's sound: its scene, and whether it is play (music ducked
/// under the game). The newest marked screen still mounted wins; when it
/// closes, the one below takes over again.
class AudioSceneMarker extends StatefulWidget {
  const AudioSceneMarker({super.key, required this.scene, this.ducked = false, required this.child});
  final AudioScene scene;
  final bool ducked;
  final Widget child;

  @override
  State<AudioSceneMarker> createState() => _AudioSceneMarkerState();
}

class _AudioSceneMarkerState extends State<AudioSceneMarker> {
  _BackgroundAudioDirectorState? _director;
  Object? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final director = context.getInheritedWidgetOfExactType<_DirectorScope>()?.state;
    if (director != _director) {
      if (_token != null) _director?.pop(_token!);
      _director = director;
      _token = director?.push(widget.scene, widget.ducked);
    }
  }

  @override
  void didUpdateWidget(AudioSceneMarker old) {
    super.didUpdateWidget(old);
    if ((old.scene != widget.scene || old.ducked != widget.ducked) && _token != null) _director?.update(_token!, widget.scene, widget.ducked);
  }

  @override
  void dispose() {
    if (_token != null) _director?.pop(_token!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
