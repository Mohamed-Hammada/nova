import 'package:flutter/material.dart';
import '../../l10n.dart';
import 'protocol/stage_messages.dart';

class A11yOverlay extends StatelessWidget {
  final List<StageLayoutItem> rects;
  final List<StageItem> items;
  final void Function(String id, DropZone targetZone) onItemActivated;
  final VoidCallback? onCharacterTapped;

  const A11yOverlay({
    super.key,
    required this.rects,
    this.items = const [],
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

  Widget _buildAccessibleTarget(BuildContext context, StageLayoutItem layoutItem) {
    final rect = layoutItem.rect;
    // Enforce 64dp minimum touch target
    final width = rect.width < 64 ? 64.0 : rect.width;
    final height = rect.height < 64 ? 64.0 : rect.height;
    final left = rect.left - (width - rect.width) / 2;
    final top = rect.top - (height - rect.height) / 2;

    final stageItem = items.cast<StageItem?>().firstWhere(
          (it) => it?.id == layoutItem.id,
          orElse: () => null,
        );
    final isOnPlate = stageItem?.onPlate ?? false;
    final isDistractor = stageItem?.kind == ItemKind.distractor;

    final String label;
    final String hint;
    final DropZone targetZone;

    if (isOnPlate) {
      label = isDistractor ? context.l10n.itemOnPlatePear : context.l10n.itemOnPlateApple;
      hint = context.l10n.itemTakeBackHint;
      targetZone = DropZone.pile;
    } else {
      label = isDistractor ? context.l10n.itemPear : context.l10n.itemApple;
      hint = context.l10n.itemGiveHint;
      targetZone = DropZone.plate;
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        label: label,
        hint: hint,
        button: true,
        onTap: () {
          onItemActivated(layoutItem.id, targetZone);
        },
        child: InkWell(
          key: ValueKey('a11y_target_${layoutItem.id}'),
          onTap: () {
            onItemActivated(layoutItem.id, targetZone);
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
