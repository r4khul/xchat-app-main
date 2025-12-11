
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform_style.dart';
import '../theme_data.dart';

class CLCircularProgressIndicator extends StatelessWidget {
  const CLCircularProgressIndicator({
    super.key,
    this.progress,
    this.size,
    this.color,
    this.useMaterialStyle,
  });

  final double? progress;
  final double? size;
  final Color? color;
  final bool? useMaterialStyle;

  double get defaultSize => 40; // _CircularProgressIndicatorDefaultsM3.constraints
  bool get _isMaterialStyle => useMaterialStyle ?? PlatformStyle.isUseMaterial;

  @override
  Widget build(BuildContext context) {
    if (_isMaterialStyle) {
      return _buildMaterialIndicator(context);
    } else {
      return _buildCupertinoIndicator(context);
    }
  }

  Widget _buildMaterialIndicator(BuildContext context) {
    final size = this.size ?? defaultSize;
    // _CircularProgressIndicatorDefaultsM3Year2023.strokeWidth = 4.0
    final strokeWidth = 4.0 * size / defaultSize;
    return SizedBox(
      height: size + strokeWidth * 2,
      width: size + strokeWidth * 2,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: strokeWidth,
        color: color,
        year2023: false,
      ),
    );
  }

  Widget _buildCupertinoIndicator(BuildContext context) {
    final size = this.size ?? defaultSize;
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      child: progress == null ?
      CupertinoActivityIndicator(radius: size / 2, color: color,) :
      _buildCircularProgressIndicatorForCupertino(context, size),
    );
  }

  Widget _buildCircularProgressIndicatorForCupertino(BuildContext context, double size) {
    final trackColor = CupertinoTrackColorEx.of(context);
    final strokeWidth = 6.0;
    final halfStroke = strokeWidth / 2;
    final effectivePad = EdgeInsets.all(halfStroke);
    return Container(
      height: size,
      width: size,
      padding: effectivePad,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        backgroundColor: trackColor,
        color: color,
      ),
    );
  }
}