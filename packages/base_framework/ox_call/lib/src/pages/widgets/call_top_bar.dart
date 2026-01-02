import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'call_page_controller.dart';

/// Top bar for call page showing duration and minimize button.
class CallTopBar extends StatelessWidget {
  const CallTopBar({
    super.key,
    required this.controller,
    this.onMinimize,
  });

  final CallPageController controller;
  final VoidCallback? onMinimize;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
        child: Row(
          children: [
            // Minimize / PiP button
            _buildMinimizeButton(),
            const Spacer(),
            // Duration (only when connected)
            _buildDuration(),
            const Spacer(),
            // Placeholder for symmetry
            SizedBox(width: 40.px),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimizeButton() {
    return GestureDetector(
      onTap: onMinimize,
      child: Container(
        width: 40.px,
        height: 40.px,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.px),
        ),
        child: Icon(
          Icons.picture_in_picture_alt_outlined,
          color: Colors.white,
          size: 22.px,
        ),
      ),
    );
  }

  Widget _buildDuration() {
    return ValueListenableBuilder<Duration>(
      valueListenable: controller.duration$,
      builder: (context, duration, _) {
        if (duration.inSeconds < 1) {
          return const SizedBox.shrink();
        }
        return CLText.titleMedium(
          controller.formatDuration(duration),
          customColor: Colors.white,
        );
      },
    );
  }
}