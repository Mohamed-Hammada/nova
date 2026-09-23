import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'a11y_overlay.dart';
import 'protocol/stage_messages.dart';
import 'stage3d_transport.dart';
import 'web_iframe_transport.dart';
import 'android_webview_transport.dart';

class Stage3DView extends StatefulWidget {
  final String sceneId;
  final String characterId;
  final QualityTier qualityTier;
  final List<StageItem> items;
  final CharacterVisualState characterState;
  final String? pointAt;
  final bool showHintCount;
  final bool isFrozen;

  final void Function(String id, DropZone zone) onItemDropped;
  final VoidCallback? onCharacterTapped;
  final void Function(String code, String message) onError;
  final void Function(QualityTier tier)? onTierChanged;
  final void Function(List<StageLayoutItem> rects)? onLayoutUpdated;

  final Stage3DTransport? transport;

  const Stage3DView({
    super.key,
    this.sceneId = 'forest_clearing',
    this.characterId = 'bear',
    this.qualityTier = QualityTier.medium,
    required this.items,
    this.characterState = CharacterVisualState.idle,
    this.pointAt,
    this.showHintCount = false,
    this.isFrozen = false,
    required this.onItemDropped,
    this.onCharacterTapped,
    required this.onError,
    this.onTierChanged,
    this.onLayoutUpdated,
    this.transport,
  });

  @override
  State<Stage3DView> createState() => Stage3DViewState();
}

class Stage3DViewState extends State<Stage3DView> {
  late final Stage3DTransport _transport;
  StreamSubscription<StageMessage>? _sub;
  Timer? _handshakeTimer;
  bool _isReady = false;
  List<StageLayoutItem> _layoutRects = [];

  bool get isReady => _isReady;
  List<StageLayoutItem> get layoutRects => _layoutRects;

  @override
  void initState() {
    super.initState();
    _transport = widget.transport ?? _createDefaultTransport();
    _initTransport();
  }

  Stage3DTransport _createDefaultTransport() {
    if (kIsWeb) {
      return WebIframeTransport();
    }
    return AndroidWebViewTransport();
  }

  Future<void> _initTransport() async {
    await _transport.initialize();

    _sub = _transport.messages.listen(
      _handleInboundMessage,
      onError: (err) {
        widget.onError('TRANSPORT_ERROR', err.toString());
      },
    );

    // Send init message
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final isRtl = locale.languageCode == 'ar';

    _transport.send(
      InitMessage(
        sceneId: widget.sceneId,
        characterId: widget.characterId,
        localeDir: isRtl ? 'rtl' : 'ltr',
        reducedMotion: WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations,
        qualityTier: widget.qualityTier,
      ),
    );

    // 8-second handshake timeout
    _handshakeTimer = Timer(const Duration(seconds: 8), () {
      if (!_isReady) {
        widget.onError('TIMEOUT', 'Stage3D handshake timed out after 8s');
      }
    });
  }

  void _handleInboundMessage(StageMessage msg) {
    if (msg is ReadyMessage) {
      _handshakeTimer?.cancel();
      setState(() {
        _isReady = true;
      });
      // Send current items upon becoming ready
      _transport.send(SetItemsMessage(items: widget.items));
      return;
    }

    if (msg is ItemDroppedMessage) {
      widget.onItemDropped(msg.id, msg.zone);
      return;
    }

    if (msg is CharacterTappedMessage) {
      widget.onCharacterTapped?.call();
      return;
    }

    if (msg is LayoutMessage) {
      setState(() {
        _layoutRects = msg.rects;
      });
      widget.onLayoutUpdated?.call(msg.rects);
      return;
    }

    if (msg is TierChangedMessage) {
      widget.onTierChanged?.call(msg.to);
      return;
    }

    if (msg is ErrorMessage) {
      widget.onError(msg.code, msg.message);
      return;
    }
  }

  @override
  void didUpdateWidget(covariant Stage3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReady) return;

    if (!listEquals(oldWidget.items, widget.items)) {
      _transport.send(SetItemsMessage(items: widget.items));
    }

    if (oldWidget.characterState != widget.characterState ||
        oldWidget.pointAt != widget.pointAt) {
      _transport.send(
        CharacterMessage(state: widget.characterState, pointAt: widget.pointAt),
      );
    }

    if (oldWidget.showHintCount != widget.showHintCount) {
      _transport.send(HintMessage(showCount: widget.showHintCount));
    }

    if (oldWidget.isFrozen != widget.isFrozen) {
      _transport.send(FreezeMessage(frozen: widget.isFrozen));
    }
  }

  /// Sends celebration burst message to stage
  void triggerCelebration() {
    _transport.send(const CelebrateMessage());
  }

  @override
  void dispose() {
    _handshakeTimer?.cancel();
    _sub?.cancel();
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _transport.buildView(context),
        if (_isReady)
          A11yOverlay(
            rects: _layoutRects,
            onItemActivated: (id, zone) => widget.onItemDropped(id, zone),
            onCharacterTapped: widget.onCharacterTapped,
          ),
      ],
    );
  }
}
