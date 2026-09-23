import 'package:flutter/material.dart';
import '../../l10n.dart';
import 'protocol/stage_messages.dart';

class A11yOverlay extends StatelessWidget {
  final List<StageLayoutItem> rects;
  final void Function(String id, DropZone targetZone) onItemActivated;
  final VoidCallback? onCharacterTapped;

  const A11yOverlay({
    super.key,
    required this.rects,
    required this.onItemActivated,
    this.onCharacterTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final item in rects) _buildAccessibleTarget(context, item),
      ],
    );
  }

  Widget _buildAccessibleTarget(BuildContext context, StageLayoutItem item) {
    final rect = item.rect;
    // Enforce 64dp minimum touch target
    final width = rect.width < 64 ? 64.0 : rect.width;
    final height = rect.height < 64 ? 64.0 : rect.height;
    final left = rect.left - (width - rect.width) / 2;
    final top = rect.top - (height - rect.height) / 2;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        label: context.l10n.itemApple,
        hint: context.l10n.itemGiveHint,
        button: true,
        onTap: () {
          // Default accessible action: drop onto plate
          onItemActivated(item.id, DropZone.plate);
        },
        child: InkWell(
          key: ValueKey('a11y_target_${item.id}'),
          onTap: () {
            onItemActivated(item.id, DropZone.plate);
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
