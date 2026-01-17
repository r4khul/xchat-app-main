import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class UserQrCodeDisplay extends StatefulWidget {
  const UserQrCodeDisplay({
    super.key,
    required this.qrcodeValue,
    required this.tintColor,
    this.userName = '',
    this.canCopyName = false,
  });

  final String qrcodeValue;
  final String userName;
  final Color tintColor;
  final bool canCopyName;

  @override
  State<StatefulWidget> createState() => UserQrCodeDisplayState();
}

class UserQrCodeDisplayState extends State<UserQrCodeDisplay> {
  late Color tintColor;
  QrImage? qrImage;
  late PrettyQrDecoration previousDecoration;
  late PrettyQrDecoration currentDecoration;
  Duration get switchDuration => const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    tintColor = widget.tintColor;

    try {
      qrImage = QrImage(QrCode.fromData(
        data: widget.qrcodeValue,
        errorCorrectLevel: QrErrorCorrectLevel.L, // Use lowest error correction level
      ));
    } catch (_) {}

    currentDecoration = createDecoration();
    previousDecoration = currentDecoration;
  }

  @override
  void didUpdateWidget(covariant UserQrCodeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tintColor != oldWidget.tintColor) {
      tintColor = widget.tintColor;
      previousDecoration = currentDecoration;
      currentDecoration = createDecoration();
    }
    if (widget.qrcodeValue != oldWidget.qrcodeValue) {
      try {
        qrImage = QrImage(QrCode.fromData(
          data: widget.qrcodeValue,
          errorCorrectLevel: QrErrorCorrectLevel.L, // Use lowest error correction level
        ));
      } catch (_) {}
    }
  }

  bool get _isWhiteColor {
    return tintColor == Colors.white ||
        (tintColor.r > 0.9 &&
            tintColor.g > 0.9 &&
            tintColor.b > 0.9 &&
            tintColor.a >0.9);
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.userName;
    final isWhite = _isWhiteColor;
    return AnimatedContainer(
      padding: EdgeInsets.all(30.px),
      duration: switchDuration,
      decoration: BoxDecoration(
        color: widget.tintColor, // Selected color background
        borderRadius: BorderRadius.circular(30.px),
      ),
      child: IntrinsicWidth(
        child: Column(
          children: [
            // QR Code with center icon
            SizedBox.square(
              dimension: 250.px,
              child: _buildQRCodeWithCenterIcon(),
            ),

            if (userName.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 16.px),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.canCopyName)
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.px),
                        child: Icon(
                          Icons.description_outlined,
                          size: 16.px,
                          color: isWhite ? Colors.black : Colors.white,
                        ),
                      ),
                    CLText.bodyMedium(
                      userName,
                      textAlign: TextAlign.center,
                      colorToken: isWhite ? ColorToken.black : ColorToken.white,
                      isBold: true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeWithCenterIcon() {
    final double containerPadding = 16.px;
    final double innerDefaultExtent = 220.px;
    final padding = 32.px;
    final isWhite = _isWhiteColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - (padding * 2);
        final double targetContainerSize =
            innerDefaultExtent + (containerPadding * 2);
        final double containerSize = math.max(
          0,
          math.min(maxWidth, targetContainerSize),
        );
        final double qrCanvasSize = math.max(
          0,
          containerSize - (containerPadding * 2),
        );

        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: ColorToken.white.of(context),
            borderRadius: BorderRadius.circular(16.px),
            border: Border.all(
              color: isWhite
                  ? ColorToken.black.of(context).withValues(alpha: 0.5)
                  : ColorToken.white.of(context),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildStyledQRCode(qrCanvasSize),
              _buildLogoWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoWidget() {
    final isWhite = _isWhiteColor;
    return Container(
      width: 48.px,
      height: 48.px,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorToken.white.of(context),
      ),
      padding: EdgeInsets.all(4.px),
      child: AnimatedContainer(
        duration: switchDuration,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isWhite ? Colors.black : tintColor,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/icon_x_logo.png',
          package: 'ox_common',
          fit: BoxFit.contain,
          width: 18.px,
          height: 18.px,
        ),
      ),
    );
  }

  Widget _buildStyledQRCode(double size) {
    if (size <= 0 || size.isNaN ) return const SizedBox.shrink();

    final qrImage = this.qrImage;
    if (qrImage == null) return const SizedBox.shrink();

    final double qrPadding = 6.px;
    final double qrSide = math.max(0, size - (qrPadding * 2));

    return Padding(
      padding: EdgeInsets.all(qrPadding),
      child: SizedBox(
        width: qrSide,
        height: qrSide,
        child: TweenAnimationBuilder<PrettyQrDecoration>(
          tween: PrettyQrDecorationTween(
            begin: previousDecoration,
            end: currentDecoration,
          ),
          duration: switchDuration,
          builder: (context, decoration, child) {
            return PrettyQrView(
              qrImage: qrImage,
              decoration: decoration,
            );
          },
        ),
      ),
    );
  }

  PrettyQrDecoration createDecoration() {
    final isWhite = _isWhiteColor;
    Color color = isWhite ? Colors.black : widget.tintColor;
    return PrettyQrDecoration(
      shape: PrettyQrSmoothSymbol(
        color: PrettyQrBrush.gradient(
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }
}