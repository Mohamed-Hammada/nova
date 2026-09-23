import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'protocol/stage_messages.dart';
import 'stage3d_transport.dart';

class WebIframeTransport implements Stage3DTransport {
  static int _nextViewId = 0;
  final String _viewType;
  final String _iframeSrc;
  final _messageController = StreamController<StageMessage>.broadcast();

  web.HTMLIFrameElement? _iframe;
  StreamSubscription<web.MessageEvent>? _messageSub;
  final List<StageMessage> _queued = [];
  Timer? _flushTimer;
  InitMessage? _initMessage;
  bool _initSent = false;

  WebIframeTransport({String? iframeSrc})
      : _viewType = 'stage3d-iframe-${_nextViewId++}',
        _iframeSrc = iframeSrc ?? 'assets/assets/stage3d/index.html';

  @override
  Stream<StageMessage> get messages => _messageController.stream;

  void _post(StageMessage msg) {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    final jsonStr = jsonEncode(msg.toJson());
    win.postMessage(jsonStr.toJS, '*'.toJS);
  }

  void _flush() {
    if (_iframe?.contentWindow == null) return;
    while (_queued.isNotEmpty) {
      _post(_queued.removeAt(0));
    }
  }

  void _sendInitIfNeeded() {
    if (!_initSent && _initMessage != null && _iframe?.contentWindow != null) {
      _initSent = true;
      _post(_initMessage!);
    }
  }

  @override
  Future<void> initialize() async {
    _iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
    _iframe!.src = _iframeSrc;
    _iframe!.style.border = 'none';
    _iframe!.style.width = '100%';
    _iframe!.style.height = '100%';
    _iframe!.style.overflow = 'hidden';

    _iframe!.addEventListener(
      'load',
      (web.Event e) {
        _sendInitIfNeeded();
        _flush();
      }.toJS,
    );

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe!,
    );

    _flushTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _sendInitIfNeeded();
      if (_queued.isNotEmpty) {
        _flush();
      }
    });

    _messageSub = web.window.onMessage.listen((web.MessageEvent event) {
      final origin = event.origin;
      // Strict origin verification: must match current window origin or empty/local
      if (origin.isNotEmpty && origin != 'null' && origin != web.window.location.origin) {
        return;
      }

      final data = event.data;
      if (data == null) return;

      try {
        final str = (data as JSString).toDart;
        final json = jsonDecode(str) as Map<String, dynamic>;
        if (json['type'] == 'stageLoaded') {
          _sendInitIfNeeded();
          _flush();
          return;
        }

        final stageMsg = StageMessage.fromJson(json);
        if (stageMsg is ReadyMessage) {
          _flushTimer?.cancel();
        }
        _messageController.add(stageMsg);
      } catch (_) {
        // Ignore non-protocol messages
      }
    });
  }

  @override
  void send(StageMessage message) {
    if (message is InitMessage) {
      _initMessage = message;
      _initSent = false;
      _sendInitIfNeeded();
      return;
    }
    if (_iframe?.contentWindow == null) {
      _queued.add(message);
      return;
    }
    _post(message);
  }

  @override
  Widget buildView(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _messageSub?.cancel();
    _messageController.close();
  }
}
