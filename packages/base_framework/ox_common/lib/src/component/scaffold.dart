
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/utils/adapt.dart';

import '../layout/layout_constant.dart';
import 'app_bar.dart';
import 'platform_style.dart';

class CLScaffold extends StatelessWidget {
  const CLScaffold({
    this.appBar,
    required this.body,
    bool? extendBody,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.bottomWidget,
    this.isSectionListPage = false,
  }) : extendBody = extendBody ?? appBar == null;

  final CLAppBar? appBar;
  final Widget body;
  final bool extendBody;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  final Widget? bottomWidget;

  final bool isSectionListPage;

  @override
  Widget build(BuildContext context) {
    final safeBody = extendBody ? body : SafeArea(bottom: false, child: body);
    
    // Get the background color to use for Stack
    final bgColor = backgroundColor ?? 
        (PlatformStyle.isUseMaterial 
            ? Theme.of(context).scaffoldBackgroundColor
            : CupertinoColors.systemGroupedBackground.resolveFrom(context));
    
    Widget scaffold;
    if (PlatformStyle.isUseMaterial) {
      scaffold = Scaffold(
        appBar: appBar?.buildMaterialAppBar(context),
        backgroundColor: backgroundColor,
        body: safeBody,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    } else {
      scaffold = CupertinoPageScaffold(
        navigationBar: appBar?.buildCupertinoAppBar(context),
        backgroundColor: backgroundColor ?? CupertinoColors.systemGroupedBackground.resolveFrom(context),
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        child: safeBody,
      );
    }
    
    if (bottomWidget != null) {
      return ColoredBox(
        color: bgColor,
        child: Stack(
          children: [
            scaffold,
            Positioned(
              left: CLLayout.horizontalPadding,
              right: CLLayout.horizontalPadding,
              bottom: 12.px,
              child: SafeArea(
                child: bottomWidget!,
              ),
            ),
          ],
        ),
      );
    }
    
    return scaffold;
  }

  static Color defaultPageBgColor(BuildContext context, bool isSectionListPage) {
    if (!PlatformStyle.isUseMaterial && isSectionListPage) {
      return CupertinoColors.systemGroupedBackground.resolveFrom(context);
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }
}