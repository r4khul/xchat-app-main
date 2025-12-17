import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';

/// A reusable circular control button for call UI.
class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.label,
    this.size = 64,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final String? label;
  final double size;
  final double? iconSize;

  /// Primary action button (e.g., hang up - red)
  factory CallControlButton.danger({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    double size = 64,
  }) {
    return CallControlButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: const Color(0xFFFF3B30),
      iconColor: Colors.white,
      label: label,
      size: size,
    );
  }

  /// Success action button (e.g., accept - green)
  factory CallControlButton.success({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    double size = 64,
  }) {
    return CallControlButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: const Color(0xFF34C759),
      iconColor: Colors.white,
      label: label,
      size: size,
    );
  }

  /// Active state button (white background)
  factory CallControlButton.active({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    double size = 64,
  }) {
    return CallControlButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: Colors.white,
      iconColor: Colors.black,
      label: label,
      size: size,
    );
  }

  /// Inactive state button (dark background)
  factory CallControlButton.inactive({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    double size = 64,
  }) {
    return CallControlButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: const Color(0xFF3A3A3C),
      iconColor: Colors.white,
      label: label,
      size: size,
    );
  }

  /// Small icon button (no background, for secondary actions)
  factory CallControlButton.icon({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    double size = 48,
  }) {
    return CallControlButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: Colors.transparent,
      iconColor: Colors.white,
      label: label,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.45);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size.px,
            height: size.px,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: effectiveIconSize.px,
            ),
          ),
          if (label != null) ...[
            SizedBox(height: 8.px),
            SizedBox(
              width: 80.px,
              child: CLText.bodySmall(
                label!,
                customColor: Colors.white.withValues(alpha: 0.8),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}