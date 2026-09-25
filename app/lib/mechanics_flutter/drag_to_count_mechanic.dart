import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/primitives/interactive_object.dart';

// The mechanic's logic is plain Dart in core/; re-exported so existing
// imports of this file keep resolving DragToCountController.
export 'package:nova_app/core/mechanics/drag_to_count.dart';

/// One item on the table or the plate, as the view sees it.
class DragToCountItem {
  const DragToCountItem({required this.id, required this.isDistractor, required this.onPlate});
  final int id;
  final bool isDistractor;
  final bool onPlate;
}

/// Everything game-specific about how drag-to-count looks and reads: the
/// same view renders bear-and-apples today and could render
/// squirrel-and-acorns tomorrow without changing this file.
class DragToCountSkin {
  const DragToCountSkin({
    required this.itemBuilder,
    required this.plateBuilder,
    required this.itemLabel,
    required this.itemOnPlateLabel,
    required this.giveHint,
    required this.takeBackHint,
    required this.plateLabel,
    required this.plateEmptyLabel,
    required this.pileLabel,
    required this.formatNumber,
  });

  final Widget Function(BuildContext context, DragToCountItem item, double size) itemBuilder;
  final Widget Function(BuildContext context, bool highlighted, Widget contents) plateBuilder;
  final String Function(DragToCountItem item) itemLabel;
  final String Function(DragToCountItem item) itemOnPlateLabel;
  final String giveHint;
  final String takeBackHint;
  final String plateLabel;
  final String plateEmptyLabel;
  final String pileLabel;
  final String Function(int value) formatNumber;
}

/// The Flutter face of drag-to-count. Stateless: it renders [items] and
/// reports intents through [onPlace]/[onRemove]; the session's view model
/// owns the state and forwards each intent to DragToCountController.
///
/// Dragging is never the only way to act. Every item is also a button: a tap,
/// a click, or Enter/Space when it has keyboard focus moves it to the plate,
/// and the same on the plate takes it back -- so children who cannot yet
/// drag, switch-access users, screen-reader users and keyboard users can all
/// play. Items dropped anywhere but the other zone are not counted.
class DragToCountView extends StatelessWidget {
  const DragToCountView({
    super.key,
    required this.items,
    required this.skin,
    required this.onPlace,
    required this.onRemove,
    this.enabled = true,
    this.showCount = false,
    this.plateHeader,
  });

  final List<DragToCountItem> items;
  final DragToCountSkin skin;
  final ValueChanged<int> onPlace;
  final ValueChanged<int> onRemove;

  /// False while feedback is showing: the board is visible but frozen.
  final bool enabled;

  /// Numbers the target items on the plate (1, 2, 3...). Only on while a hint
  /// is active -- an always-visible count would do the counting for the
  /// child.
  final bool showCount;

  /// Shown above the plate (e.g. the bear making the request).
  final Widget? plateHeader;

  @override
  Widget build(BuildContext context) {
    final pile = items.where((i) => !i.onPlate).toList();
    final plate = items.where((i) => i.onPlate).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final itemSize = constraints.maxWidth < 380 ? NovaSize.childTouch : NovaSize.gameItem;
      final plateZone = _PlateZone(
        items: plate, skin: skin, itemSize: itemSize, enabled: enabled, showCount: showCount,
        header: plateHeader, onPlace: onPlace, onRemove: onRemove,
      );
      final pileZone = _PileZone(items: pile, skin: skin, itemSize: itemSize, enabled: enabled, onPlace: onPlace, onRemove: onRemove);

      // Wide: table and plate side by side (table on the reading-start side,
      // so the motion follows reading direction and mirrors under RTL).
      // Narrow: plate above table, so the bear and plate stay in view.
      return wide
          // Both zones as tall as the taller one, even inside a scroll view.
          ? IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: pileZone),
                const SizedBox(width: NovaSpace.lg),
                Expanded(child: plateZone),
              ]),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              plateZone,
              const SizedBox(height: NovaSpace.md),
              pileZone,
            ]);
    });
  }
}

class _PileZone extends StatelessWidget {
  const _PileZone({required this.items, required this.skin, required this.itemSize, required this.enabled, required this.onPlace, required this.onRemove});
  final List<DragToCountItem> items;
  final DragToCountSkin skin;
  final double itemSize;
  final bool enabled;
  final ValueChanged<int> onPlace;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    // Accepts items dragged back off the plate.
    return DragTarget<int>(
      key: const ValueKey('drag-to-count.pile'),
      onWillAcceptWithDetails: (d) => enabled && _isOnPlate(d.data),
      onAcceptWithDetails: (d) => onRemove(d.data),
      builder: (context, candidates, _) => Semantics(
        container: true,
        label: skin.pileLabel,
        child: Container(
          decoration: BoxDecoration(
            color: NovaPalette.table,
            borderRadius: BorderRadius.circular(NovaRadius.lg),
            border: Border.all(
              color: candidates.isNotEmpty ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(NovaSpace.md),
          alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: NovaSpace.sm,
            runSpacing: NovaSpace.sm,
            children: [
              for (final item in items)
                _ItemButton(
                  key: ValueKey('drag-to-count.item.${item.id}'),
                  item: item, skin: skin, size: itemSize, enabled: enabled,
                  label: skin.itemLabel(item), hint: skin.giveHint,
                  onActivate: () => onPlace(item.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOnPlate(int id) => !items.any((i) => i.id == id);
}

class _PlateZone extends StatelessWidget {
  const _PlateZone({
    required this.items, required this.skin, required this.itemSize, required this.enabled,
    required this.showCount, required this.header, required this.onPlace, required this.onRemove,
  });
  final List<DragToCountItem> items;
  final DragToCountSkin skin;
  final double itemSize;
  final bool enabled;
  final bool showCount;
  final Widget? header;
  final ValueChanged<int> onPlace;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    var targetNumber = 0;
    final contents = items.isEmpty
        ? SizedBox(
            height: itemSize,
            child: Center(child: Text(skin.plateEmptyLabel, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: NovaPalette.inkMuted))),
          )
        : Wrap(
            alignment: WrapAlignment.center,
            spacing: NovaSpace.xs,
            runSpacing: NovaSpace.xs,
            children: [
              for (final item in items)
                _ItemButton(
                  key: ValueKey('drag-to-count.plate-item.${item.id}'),
                  item: item, skin: skin, size: itemSize, enabled: enabled,
                  label: skin.itemOnPlateLabel(item), hint: skin.takeBackHint,
                  badge: showCount && !item.isDistractor ? skin.formatNumber(++targetNumber) : null,
                  onActivate: () => onRemove(item.id),
                ),
            ],
          );

    // Placing only counts when the drop lands on this target: DragTarget
    // acceptance, not Draggable.onDragEnd (which fires wherever a drag ends).
    return DragTarget<int>(
      key: const ValueKey('drag-to-count.plate'),
      onWillAcceptWithDetails: (d) => enabled && !items.any((i) => i.id == d.data),
      onAcceptWithDetails: (d) => onPlace(d.data),
      builder: (context, candidates, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?header,
          Semantics(
            container: true,
            label: skin.plateLabel,
            // A steady minimum size, so the plate does not shrink and jump
            // as items arrive (it still grows when many are on it).
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: itemSize * 4 + NovaSpace.xl),
              child: skin.plateBuilder(context, candidates.isNotEmpty, contents),
            ),
          ),
        ],
      ),
    );
  }
}

/// A game item that is both draggable and a button.
class _ItemButton extends StatelessWidget {
  const _ItemButton({
    super.key,
    required this.item,
    required this.skin,
    required this.size,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.onActivate,
    this.badge,
  });

  final DragToCountItem item;
  final DragToCountSkin skin;
  final double size;
  final bool enabled;
  final String label;
  final String hint;
  final VoidCallback onActivate;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InteractiveObject(
      id: item.id,
      objectId: item.isDistractor ? 'pear' : 'apple',
      enabled: enabled,
      label: label,
      actionHint: hint,
      onActivate: onActivate,
      size: size,
      badge: badge,
      visual: skin.itemBuilder(context, item, size),
      onPlate: item.onPlate,
    );
  }
}

