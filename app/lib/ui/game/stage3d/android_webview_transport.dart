import 'dart:async';
import 'package:flutter/widgets.dart';
import 'protocol/stage_messages.dart';
import 'stage3d_transport.dart';

class AndroidWebViewTransport implements Stage3DTransport {
  final _messageController = StreamController<StageMessage>.broadcast();

  @override
  Stream<StageMessage> get messages => _messageController.stream;

  @override
  void send(StageMessage message) {
    // Forward to Android JavaScript channel when active
  }

  @override
  Future<void> initialize() async {}

  @override
  Widget buildView(BuildContext context) {
    return const SizedBox.expand(
      key: ValueKey('android_webview_stage3d'),
    );
  }

  @override
  void dispose() {
    _messageController.close();
  }
}
