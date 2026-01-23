import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:ox_common/login/account_path_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:chatcore/chat-core.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ox_common/utils/permission_utils.dart';
import 'package:ox_common/const/app_config.dart';
import 'package:ox_common/utils/compression_utils.dart';
import 'package:ox_common/utils/user_config_tool.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_chat/utils/chat_session_utils.dart';
import 'package:ox_common/widgets/common_scan_page.dart';
import 'package:flutter/services.dart';

import '../qr_code/user_qr_code_display.dart';
import 'qr_code_color_picker_page.dart';
import '../../utils/invite_link_manager.dart';
import 'package:ox_common/login/login_models.dart';

enum QRCodeStyle {
  defaultStyle, // Default
  classic,      // Classic
  dots,         // Dots
  gradient,     // Gradient
}

enum QRCodePageMode {
  code,  // Show QR code
  scan,  // Show scan page
}

class QRCodeDisplayPage extends StatefulWidget {
  const QRCodeDisplayPage({
    super.key,
    this.previousPageTitle,
    this.otherUser,
    this.inviteType = InviteType.keypackage,
    this.circle,
  });

  final String? previousPageTitle;
  final UserDBISAR? otherUser;
  final InviteType inviteType;
  final Circle? circle;

  @override
  State<QRCodeDisplayPage> createState() => _QRCodeDisplayPageState();
}

class _QRCodeDisplayPageState extends State<QRCodeDisplayPage> {
  late final UserDBISAR userNotifier;
  late final String userName;
  String? currentInviteLink;
  String currentQrCodeData = '';

  final GlobalKey qrWidgetKey = GlobalKey();

  // QR Code color
  Color selectedColor = const Color(0xFF2196F3); // Default blue

  double get horizontal => 32.px;

  // Invite link type (for keypackage invites)
  InviteLinkType? currentLinkType;

  // Discoverable by ID setting
  late final ValueNotifier<bool> discoverableByID$;

  // Page mode (Code or Scan)
  late final ValueNotifier<QRCodePageMode?> currentMode$;

  @override
  void initState() {
    super.initState();
    userNotifier = widget.otherUser ?? Account.sharedInstance.me!;
    userName = userNotifier.name ?? userNotifier.shortEncodedPubkey;

    // Initialize discoverable by ID setting
    // Check both saved setting and actual keypackage events in database
    discoverableByID$ = ValueNotifier<bool>(false);
    _initializeDiscoverableByID();

    // Initialize page mode
    currentMode$ = ValueNotifier<QRCodePageMode?>(QRCodePageMode.code);

    // Auto-generate invite link when page loads (only for current user)
    if (widget.otherUser == null) {
      _generateInviteLink();
    }
  }

  /// Initialize discoverable by ID state by checking database
  Future<void> _initializeDiscoverableByID() async {
    if (widget.otherUser != null) return; // Only for current user
    
    try {
      final ownerPubkey = Account.sharedInstance.currentPubkey;
      
      // Check if there are any permanent keypackages that are published
      List<KeyPackageDBISAR> permanentKeyPackages =
          await KeyPackageManager.getLocalKeyPackagesByType(
              ownerPubkey, KeyPackageType.permanent);
      
      // Check if any keypackage has been published (isPublished = true)
      // Use database state as the only source of truth
      bool isDiscoverable = permanentKeyPackages.any((kp) => kp.isPublished);
      
      discoverableByID$.value = isDiscoverable;
    } catch (e) {
      print('Failed to initialize discoverable by ID: $e');
      // Default to false on error
      discoverableByID$.value = false;
    }
  }


  @override
  void dispose() {
    discoverableByID$.dispose();
    currentMode$.dispose();
    super.dispose();
  }

  Future<void> _generateInviteLink() async {
    if (widget.otherUser != null) return; // Only for current user

    try {
      String inviteLink;
      
      if (widget.inviteType == InviteType.circle) {
        // Generate circle invite link
        if (widget.circle == null) {
          CommonToast.instance.show(context, 'Circle is required for circle invite');
          return;
        }
        
        final result = await InviteLinkManager.generateCircleInviteLink(
          circle: widget.circle!,
        );
        inviteLink = result['inviteLink'] as String;
        currentLinkType = InviteLinkType.permanent; // Circle invites are permanent
      } else {
        // Generate keypackage invite link (default to permanent)
        inviteLink = await InviteLinkManager.generateKeyPackageInviteLink(
          linkType: InviteLinkType.permanent,
          context: context,
        );
        currentLinkType = InviteLinkType.permanent;
      }

      // Update QR code data and invite link
      currentInviteLink = inviteLink;
      currentQrCodeData = inviteLink;

      setState(() {});
    } catch (e) {
      CommonToast.instance.show(context, e.toString());
      if (widget.inviteType == InviteType.circle) {
        // For circle invites, pop back on error
        OXNavigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: _buildSegmentControl(),
      ),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildMaterialAppBar() {
    return AppBar(
      backgroundColor: ColorToken.surface.of(context),
      elevation: 0,
      leading: Container(), // Remove default back button
      title: _buildSegmentControl(),
      centerTitle: true,
      actions: [
        // Close button (X)
        Padding(
          padding: EdgeInsets.only(right: 16.px),
          child: CLButton.icon(
            onTap: () => OXNavigator.pop(context),
            icon: Icons.close,
            iconSize: 24.px,
          ),
        ),
      ],
    );
  }

  CupertinoNavigationBar _buildCupertinoAppBar() {
    return CupertinoNavigationBar(
      middle: _buildSegmentControl(),
      leading: null,
      padding: EdgeInsetsDirectional.zero,
      trailing: CupertinoButton(
        padding: EdgeInsets.only(right: 16.px),
        onPressed: () => OXNavigator.pop(context),
        child: Text(Localized.text('ox_common.complete')),
      ),
    );
  }

  Widget _buildSegmentControl() {
    return CLSelector<QRCodePageMode>(
      items: [
        CLSelectorItem<QRCodePageMode>(
          value: QRCodePageMode.code,
          label: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.px),
            child: Text(Localized.text('ox_usercenter.code')),
          ),
        ),
        CLSelectorItem<QRCodePageMode>(
          value: QRCodePageMode.scan,
          label: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.px),
            child: Text(Localized.text('ox_usercenter.scan')),
          ),
        ),
      ],
      selectedValue$: currentMode$,
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<QRCodePageMode?>(
      valueListenable: currentMode$,
      builder: (context, currentMode, _) {
        if (currentMode == QRCodePageMode.scan) {
          return _buildScanPage();
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Column(
              children: [
                SizedBox(height: 24.px),

                // QR Code Card - Blue background with QR code
                RepaintBoundary(
                  key: qrWidgetKey,
                  child: UserQrCodeDisplay(
                    qrcodeValue: currentQrCodeData,
                    tintColor: selectedColor,
                    userName: widget.inviteType == InviteType.circle && widget.circle != null
                        ? widget.circle!.name
                        : userName,
                    canCopyName: true,
                  ),
                ),

                // Action buttons (Link, Share, Color)
                SizedBox(height: 32.px),
                _buildActionButtons(),

                // Warning text
                SizedBox(height: 32.px),
                CLText.bodySmall(
                  widget.inviteType == InviteType.circle
                      ? Localized.text('ox_usercenter.qr_code_share_warning_circle')
                      : Localized.text('ox_usercenter.qr_code_share_warning'),
                  textAlign: TextAlign.center,
                  colorToken: ColorToken.onSurfaceVariant,
                ),

                // Reset button (for both keypackage and circle invites)
                SizedBox(height: 32.px),
                CLButton.outlined(
                  text: Localized.text('ox_usercenter.reset'),
                  onTap: widget.otherUser == null && currentInviteLink != null
                      ? _showRegenerateConfirmDialog
                      : null,
                  expanded: true,
                ),

                SafeArea(child: SizedBox(height: 12.px))
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanPage() {
    return CommonScanPage();
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCircularActionButton(
          icon: Icons.link,
          label: Localized.text('ox_usercenter.link'),
          onTap: _copyLink,
        ),
        _buildCircularActionButton(
          icon: Icons.share,
          label: Localized.text('ox_usercenter.share'),
          onTap: _shareQRCodeImage,
        ),
        _buildCircularActionButton(
          icon: Icons.palette,
          label: Localized.text('ox_usercenter.color'),
          onTap: _showColorPicker,
        ),
      ],
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56.px,
            height: 56.px,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorToken.cardContainer.of(context),
            ),
            child: Icon(
              icon,
              size: 24.px,
              color: ColorToken.onSurface.of(context),
            ),
          ),
        ),
        SizedBox(height: 8.px),
        CLText.bodySmall(
          label,
          colorToken: ColorToken.onSurface,
        ),
      ],
    );
  }
  
  void changeQrColor(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  PrettyQrDecoration createDecoration(QRCodeStyle style, {Color? customColor}) {
    Color color = customColor ?? selectedColor;
    double roundFactor = 1;
    PrettyQrShape shape;

    switch (style) {
      case QRCodeStyle.defaultStyle:
        shape = PrettyQrSmoothSymbol(
          color: color,
          roundFactor: roundFactor,
        );
        break;

      case QRCodeStyle.classic:
        shape = PrettyQrSmoothSymbol(
          color: color,
          roundFactor: 0,
        );
        break;

      case QRCodeStyle.dots:
        shape = PrettyQrRoundedSymbol(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        );
        break;

      case QRCodeStyle.gradient:
        // For gradient style, use theme gradient if no custom color is provided
        // Otherwise, create a gradient from the custom color
        if (customColor != null) {
          shape = PrettyQrSmoothSymbol(
            color: PrettyQrBrush.gradient(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.6),
                ],
              ),
            ),
            roundFactor: roundFactor,
          );
        } else {
          shape = PrettyQrSmoothSymbol(
            color: PrettyQrBrush.gradient(
              gradient: CLThemeData.themeGradientOf(OXNavigator.rootContext),
            ),
            roundFactor: roundFactor, // Rounded
          );
        }
        break;
    }

    return PrettyQrDecoration(
      shape: shape,
    );
  }

  Future<void> _shareQRCodeImage() async {
    try {
      OXLoading.show();

      // Capture QR code widget as image
      final boundary = qrWidgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to capture QR code');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Create temporary file
      final tempFile =  await AccountPathManager.createTempFile(
        fileExt: 'png',
      );
      await tempFile.writeAsBytes(pngBytes);

      await OXLoading.dismiss();

      // Share the image file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: Localized.text('ox_usercenter.invite_to_chat'),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    } catch (e) {
      await OXLoading.dismiss();
      CommonToast.instance.show(
        context,
        '${Localized.text('ox_usercenter.share_failed')}: $e',
      );
    }
  }

  Future<void> _copyLink() async {
    if (currentInviteLink == null) return;
    
    // Show dialog with link information
    if (PlatformStyle.isUseMaterial) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(24.px, 20.px, 24.px, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description text
              CLText.bodyMedium(
                Localized.text('ox_usercenter.invite_link_description'),
                colorToken: ColorToken.onSurfaceVariant,
              ),
              SizedBox(height: 16.px),
              // Link URL
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: currentInviteLink!));
                  CommonToast.instance.show(context, Localized.text('ox_common.copied_to_clipboard'));
                },
                child: Container(
                  padding: EdgeInsets.all(12.px),
                  decoration: BoxDecoration(
                    color: ColorToken.surfaceContainerHigh.of(context),
                    borderRadius: BorderRadius.circular(8.px),
                  ),
                  child: Text(
                    currentInviteLink!,
                    style: TextStyle(
                      fontSize: 14.px,
                      color: ColorToken.onSurface.of(context),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: currentInviteLink!));
                CommonToast.instance.show(context, Localized.text('ox_common.copied_to_clipboard'));
              },
              icon: Icon(Icons.description_outlined, size: 20.px),
              label: Text(Localized.text('ox_usercenter.copy_link')),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Share.share(
                  currentInviteLink!,
                  subject: Localized.text('ox_usercenter.invite_to_chat'),
                );
              },
              icon: Icon(Icons.share, size: 20.px),
              label: Text(Localized.text('ox_usercenter.share')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(Localized.text('ox_common.cancel')),
            ),
          ],
        ),
      );
    } else {
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description text
              CLText.bodyMedium(
                Localized.text('ox_usercenter.invite_link_description'),
                colorToken: ColorToken.onSurfaceVariant,
              ),
              SizedBox(height: 16.px),
              // Link URL
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: currentInviteLink!));
                  CommonToast.instance.show(context, Localized.text('ox_common.copied_to_clipboard'));
                },
                child: Container(
                  padding: EdgeInsets.all(12.px),
                  decoration: BoxDecoration(
                    color: ColorToken.surfaceContainerHigh.of(context),
                    borderRadius: BorderRadius.circular(8.px),
                  ),
                  child: Text(
                    currentInviteLink!,
                    style: TextStyle(
                      fontSize: 14.px,
                      color: ColorToken.onSurface.of(context),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: currentInviteLink!));
                CommonToast.instance.show(context, Localized.text('ox_common.copied_to_clipboard'));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 18.px),
                  SizedBox(width: 6.px),
                  Text(Localized.text('ox_usercenter.copy_link')),
                ],
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await Share.share(
                  currentInviteLink!,
                  subject: Localized.text('ox_usercenter.invite_to_chat'),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share, size: 18.px),
                  SizedBox(width: 6.px),
                  Text(Localized.text('ox_usercenter.share')),
                ],
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(Localized.text('ox_common.cancel')),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showColorPicker() async {
    final displayName = widget.inviteType == InviteType.circle && widget.circle != null
        ? widget.circle!.name
        : userName;
    
    final Color? selectedColorResult = await OXNavigator.pushPage<Color>(
      context,
      (context) => QRCodeColorPickerPage(
        initialColor: selectedColor,
        qrcodeValue: currentQrCodeData,
        userName: displayName,
      ),
      type: OXPushPageType.present,
    );

    if (selectedColorResult != null) {
      changeQrColor(selectedColorResult);
    }
  }


  Future<void> _regenerateInviteLink() async {
    try {
      String inviteLink;
      
      if (widget.inviteType == InviteType.circle) {
        // Reset circle invitation code
        if (widget.circle == null) {
          CommonToast.instance.show(context, 'Circle is required for circle invite');
          return;
        }
        
        final result = await InviteLinkManager.regenerateCircleInviteLink(
          circle: widget.circle!,
        );
        inviteLink = result['inviteLink'] as String;
      } else {
        // Regenerate keypackage invite link
        inviteLink = await InviteLinkManager.regenerateKeyPackageInviteLink(
          context: context,
        );
      }

      // Update QR code data and invite link
      currentInviteLink = inviteLink;
      currentQrCodeData = inviteLink;

      setState(() {});

      CommonToast.instance.show(context, Localized.text('ox_usercenter.invite_link_regenerated'));
    } catch (e) {
      CommonToast.instance.show(context, e.toString());
    }
  }

  void _showRegenerateConfirmDialog() {
    final content = widget.inviteType == InviteType.circle
        ? Localized.text('ox_usercenter.reset_circle_invite_confirm')
        : Localized.text('ox_usercenter.regenerate_confirm_content');
    
    CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.regenerate_invite_link'),
      content: content,
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_common.confirm'),
          value: true,
          isDefaultAction: true,
        ),
      ],
    ).then((value) {
      if (value == true) {
        _regenerateInviteLink();
      }
    });
  }
}