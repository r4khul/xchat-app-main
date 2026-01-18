import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/color_extension.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../qr_code/user_qr_code_display.dart';

class QRCodeColorPickerPage extends StatefulWidget {
  const QRCodeColorPickerPage({
    super.key,
    required this.initialColor,
    required this.userName,
    required this.qrcodeValue,
  });

  final Color initialColor;
  final String userName;
  final String qrcodeValue;

  @override
  State<QRCodeColorPickerPage> createState() => _QRCodeColorPickerPageState();
}

class _QRCodeColorPickerPageState extends State<QRCodeColorPickerPage> {
  late Color selectedColor;

  // Define color palette
  final List<Color> colors = [
    const Color(0xFF2196F3), // Blue
    Colors.white,
    const Color(0xFF424242), // Dark gray
    const Color(0xFFA1887F), // Light brown
    const Color(0xFF8B9A5B), // Olive green
    const Color(0xFFFF9800), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFFBA68C8), // Light purple
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_usercenter.color'),
        leading: GestureDetector(
          onTap: () => OXNavigator.pop(context),
          child: Container(
            width: 40.px,
            height: 40.px,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorToken.surfaceContainer.of(context),
            ),
            child: Icon(
              Icons.close,
              size: 20.px,
              color: ColorToken.onSurface.of(context),
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => OXNavigator.pop(context, selectedColor),
            child: Container(
              width: 40.px,
              height: 40.px,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorToken.primary.of(context),
              ),
              child: Icon(
                Icons.check,
                size: 20.px,
                color: Color.lerp(ColorToken.primary.of(context), const Color(0xFFFFFFFF), 0.9),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 40.px),

            // QR Code Preview
            IntrinsicWidth(
              child: UserQrCodeDisplay(
                qrcodeValue: widget.qrcodeValue,
                tintColor: selectedColor,
                userName: widget.userName,
              ),
            ),

            SizedBox(height: 40.px),

            // Color Palette
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.px),
              child: Wrap(
                spacing: 20.px,
                runSpacing: 20.px,
                alignment: WrapAlignment.center,
                children: colors.map((color) {
                  final bool isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 60.px,
                      height: 60.px,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: isSelected ? 4.px : 0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16.px),
          ],
        ),
      ),
    );
  }
}

