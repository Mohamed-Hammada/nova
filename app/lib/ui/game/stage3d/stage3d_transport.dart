import 'package:flutter/widgets.dart';
import 'protocol/stage_messages.dart';

abstract class Stage3DTransport {
  Stream<StageMessage> get messages;

  void send(StageMessage message);

  Future<void> initialize();

  Widget buildView(BuildContext context);

  void dispose();
}
