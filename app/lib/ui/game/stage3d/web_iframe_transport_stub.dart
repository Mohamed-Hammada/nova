import 'dart:async';
import 'package:flutter/widgets.dart';
import 'protocol/stage_messages.dart';
import 'stage3d_transport.dart';

class WebIframeTransport implements Stage3DTransport {
  WebIframeTransport({String? iframeSrc});

  @override
  Stream<StageMessage> get messages => const Stream.empty();

  @override
  void send(StageMessage message) {}

  @override
  Future<void> initialize() async {}

  @override
  Widget buildView(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void dispose() {}
}
