import 'package:flutter/material.dart';
import '../../l10n.dart';
import 'stage_capability.dart';

class GraphicsQualityDialog extends StatelessWidget {
  final GraphicsQualitySetting currentSetting;
  final ValueChanged<GraphicsQualitySetting> onSettingChanged;

  const GraphicsQualityDialog({
    super.key,
    required this.currentSetting,
    required this.onSettingChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required GraphicsQualitySetting currentSetting,
    required ValueChanged<GraphicsQualitySetting> onSettingChanged,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => GraphicsQualityDialog(
        currentSetting: currentSetting,
        onSettingChanged: onSettingChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.graphicsQuality),
      content: SingleChildScrollView(
        child: RadioGroup<GraphicsQualitySetting>(
          groupValue: currentSetting,
          onChanged: (val) {
            if (val != null) {
              onSettingChanged(val);
              Navigator.of(context).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadio(
                context,
                title: l10n.graphicsAuto,
                subtitle: l10n.graphicsAutoDesc,
                value: GraphicsQualitySetting.auto,
              ),
              _buildRadio(
                context,
                title: l10n.graphicsHigh,
                subtitle: l10n.graphicsHighDesc,
                value: GraphicsQualitySetting.high,
              ),
              _buildRadio(
                context,
                title: l10n.graphicsMedium,
                subtitle: l10n.graphicsMediumDesc,
                value: GraphicsQualitySetting.medium,
              ),
              _buildRadio(
                context,
                title: l10n.graphicsLow,
                subtitle: l10n.graphicsLowDesc,
                value: GraphicsQualitySetting.low,
              ),
              _buildRadio(
                context,
                title: l10n.graphics2D,
                subtitle: l10n.graphics2DDesc,
                value: GraphicsQualitySetting.twoDimensional,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _buildRadio(
    BuildContext context, {
    required String title,
    required String subtitle,
    required GraphicsQualitySetting value,
  }) {
    return RadioListTile<GraphicsQualitySetting>(
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
    );
  }
}
