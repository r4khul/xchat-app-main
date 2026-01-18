import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';

class ChatIconWidget {
  static Widget selfAuthIcon(BuildContext context) => Icon(
    CupertinoIcons.checkmark_seal_fill,
    size: 16.px,
    color: ColorToken.primary.of(context),
  );
}