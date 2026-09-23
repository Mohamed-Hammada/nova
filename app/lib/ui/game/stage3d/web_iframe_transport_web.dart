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

  WebIframeTransport({String? iframeSrc})
      : _viewType = 'stage3d-iframe-${_nextViewId++}',
        _iframeSrc = iframeSrc ?? 'assets/assets/stage3d/index.html';

  @override
  Stream<StageMessage> get messages => _messageController.stream;

  @override
  Future<void> initialize() async {
    _iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
    _iframe!.src = _iframeSrc;
    _iframe!.style.border = 'none';
    _iframe!.style.width = '100%';
    _iframe!.style.height = '100%';
    _iframe!.style.overflow = 'hidden';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe!,
    );

    _messageSub = web.window.onMessage.listen((web.MessageEvent event) {
      final origin = event.origin;
      // Strict origin verification: must match current window origin
      if (origin.isNotEmpty && origin != web.window.location.origin) {
        return;
      }

      final data = event.data;
      if (data == null) return;

      try {
        final str = (data as JSString).toDart;
        final json = jsonDecode(str) as Map<String, dynamic>;
        final stageMsg = StageMessage.fromJson(json);
        _messageController.add(stageMsg);
      } catch (_) {
        // Ignore non-protocol messages
      }
    });
  }

  @override
  void send(StageMessage message) {
    if (_iframe?.contentWindow == null) return;
    final jsonStr = jsonEncode(message.toJson());
    _iframe!.contentWindow!.postMessage(
      jsonStr.toJS,
      web.window.location.origin.toJS,
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _messageController.close();
  }
}
