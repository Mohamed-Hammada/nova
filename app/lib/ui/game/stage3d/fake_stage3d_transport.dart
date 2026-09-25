import 'dart:async';
import 'package:flutter/widgets.dart';
import 'protocol/stage_messages.dart';
import 'stage3d_transport.dart';

class FakeStage3DTransport implements Stage3DTransport {
  final _messageController = StreamController<StageMessage>.broadcast();
  final List<StageMessage> sentMessages = [];

  bool autoReplyReady;
  QualityTier readyTier;

  FakeStage3DTransport({
    this.autoReplyReady = true,
    this.readyTier = QualityTier.medium,
  });

  @override
  Stream<StageMessage> get messages => _messageController.stream;

  @override
  void send(StageMessage message) {
    sentMessages.add(message);
    if (message is InitMessage && autoReplyReady) {
      // Simulate stage sending ready
      _messageController.add(
        ReadyMessage(protocolVersion: 1, tier: readyTier),
      );
    }
  }

  /// Inject an inbound message from the fake 3D stage into Flutter
  void emit(StageMessage message) {
    _messageController.add(message);
  }

  @override
  Future<void> initialize() async {}

  @override
  Widget buildView(BuildContext context) {
    return const SizedBox.expand(
      key: ValueKey('fake_stage3d_view'),
    );
  }

  @override
  void dispose() {
    _messageController.close();
  }
}
