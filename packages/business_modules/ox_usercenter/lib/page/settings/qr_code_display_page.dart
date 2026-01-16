import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

enum QRCodeStyle {
  defaultStyle, // Default
  classic,      // Classic
  dots,         // Dots
  gradient,     // Gradient
}

enum InviteLinkType {
  oneTime,    // One-time invite link
  permanent,  // Permanent invite link
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
  });

  final String? previousPageTitle;
  final UserDBISAR? otherUser;

  @override
  State<QRCodeDisplayPage> createState() => _QRCodeDisplayPageState();
}

class _QRCodeDisplayPageState extends State<QRCodeDisplayPage> {
  late final UserDBISAR userNotifier;
  late final String userName;
  String? currentInviteLink;
  String? currentQrCodeData;

  // QR Code style options
  QRCodeStyle currentStyle = QRCodeStyle.gradient;
  final GlobalKey qrWidgetKey = GlobalKey();
  
  // QR Code color
  Color selectedColor = const Color(0xFF2196F3); // Default blue

  double get horizontal => 32.px;

  QrCode? qrCode;
  QrImage? qrImage;
  late PrettyQrDecoration previousDecoration;
  late PrettyQrDecoration currentDecoration;

  // Invite link type
  InviteLinkType currentLinkType = InviteLinkType.oneTime;

  // Discoverable by ID setting
  late final ValueNotifier<bool> discoverableByID$;

  // Page mode (Code or Scan)
  QRCodePageMode currentMode = QRCodePageMode.code;

  @override
  void initState() {
    super.initState();
    userNotifier = widget.otherUser ?? Account.sharedInstance.me!;
    userName = userNotifier.name ?? userNotifier.shortEncodedPubkey;

    currentDecoration = createDecoration(currentStyle);
    previousDecoration = currentDecoration;

    // Initialize discoverable by ID setting
    // Check both saved setting and actual keypackage events in database
    discoverableByID$ = ValueNotifier<bool>(false);
    _initializeDiscoverableByID();

    // Auto-generate permanent invite link when page loads (only for current user)
    if (widget.otherUser == null) {
      _generateInviteLink(InviteLinkType.permanent);
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
    super.dispose();
  }

  Future<void> _generateInviteLink(InviteLinkType linkType) async {
    if (widget.otherUser != null) return; // Only for current user

    try {
      OXLoading.show();

      KeyPackageEvent? keyPackageEvent;

      if (linkType == InviteLinkType.oneTime) {
        keyPackageEvent = await Groups.sharedInstance.createOneTimeKeyPackage();
      } else {
        keyPackageEvent = await Groups.sharedInstance.createPermanentKeyPackage(
          Account.sharedInstance.getCurrentCircleRelay(),
        );
      }

      if (keyPackageEvent == null) {
        await OXLoading.dismiss();
        // Check if it's a keypackage expiration issue
        // Show dialog asking if user wants to refresh their keypackage
        final shouldRefresh = await CLAlertDialog.show<bool>(
          context: context,
          title: Localized.text('ox_chat.key_package_expired'),
          content: Localized.text('ox_chat.key_package_may_expired'),
          actions: [
            CLAlertAction.cancel(),
            CLAlertAction<bool>(
              label: Localized.text('ox_chat.refresh'),
              value: true,
              isDefaultAction: true,
            ),
          ],
        );

        if (shouldRefresh == true) {
          // Refresh keypackage and retry
          await _generateInviteLink(linkType);
        }
        return;
      }

      // Get relay URL
      List<String> relays = Account.sharedInstance.getCurrentCircleRelay();
      String? relayUrl = relays.firstOrNull;
      if (relayUrl == null || relayUrl.isEmpty) {
        await OXLoading.dismiss();
        CommonToast.instance.show(context, 'Error circle info');
        OXNavigator.pop(context);
        return;
      }

      // Generate invite link with compression
      if (linkType == InviteLinkType.oneTime || linkType == InviteLinkType.permanent) {
        // For one-time invites, include sender's pubkey
        final senderPubkey = Account.sharedInstance.currentPubkey;

        // Try to compress the keypackage data
        String? compressedKeyPackage = await CompressionUtils.compressWithPrefix(keyPackageEvent.encoded_key_package);
        String keyPackageParam = compressedKeyPackage ?? keyPackageEvent.encoded_key_package;

        currentInviteLink = '${AppConfig.inviteBaseUrl}?keypackage=$keyPackageParam&pubkey=${Uri.encodeComponent(senderPubkey)}&relay=${Uri.encodeComponent(relayUrl)}';

        // Log compression results
        if (compressedKeyPackage != null) {
          double ratio = CompressionUtils.getCompressionRatio(keyPackageEvent.encoded_key_package, compressedKeyPackage);
          print('Keypackage compressed: ${(ratio * 100).toStringAsFixed(1)}% of original size');
        }
      } else {
        currentInviteLink = '${AppConfig.inviteBaseUrl}?eventid=${Uri.encodeComponent(keyPackageEvent.eventId)}&relay=${Uri.encodeComponent(relayUrl)}';
      }

      // Update QR code data and current link type
      currentQrCodeData = currentInviteLink;
      currentLinkType = linkType;

      // Initialize QR code and image with optimized settings for long URLs
      try {
        // Use lower error correction level for better readability with long URLs
        qrCode = QrCode.fromData(
          data: currentQrCodeData!,
          errorCorrectLevel: QrErrorCorrectLevel.L, // Use lowest error correction level
        );
        qrImage = QrImage(qrCode!);
      } catch (e) {
        print('QR code generation failed: $e');
        qrCode = null;
        qrImage = null;
        CommonToast.instance.show(context, Localized.text('ox_usercenter.qr_generation_failed'));
      }

      await OXLoading.dismiss();
      setState(() {});
    } catch (e) {
      await OXLoading.dismiss();
      
      // Handle KeyPackageError
      final handled = await ChatSessionUtils.handleKeyPackageError(
        context: context,
        error: e,
        onRetry: () async {
          // Retry generating invite link
          await _generateInviteLink(linkType);
        },
        onOtherError: (message) {
          CommonToast.instance.show(context, '${Localized.text('ox_usercenter.invite_link_generation_failed')}: $e');
        },
      );

      if (!handled) {
        // Other errors
        CommonToast.instance.show(context, '${Localized.text('ox_usercenter.invite_link_generation_failed')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformStyle.isUseMaterial) {
      return Scaffold(
        appBar: _buildMaterialAppBar(),
        body: _buildBody(),
        backgroundColor: ColorToken.surface.of(context),
      );
    } else {
      return CupertinoPageScaffold(
        navigationBar: _buildCupertinoAppBar(),
        child: SafeArea(
          bottom: false,
          child: _buildBody(),
        ),
      );
    }
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
    if (PlatformStyle.isUseMaterial) {
      // Material style segment control
      return Container(
        constraints: BoxConstraints(
          minWidth: 150.px,
          maxWidth: 200.px,
        ),
        decoration: BoxDecoration(
          color: ColorToken.surfaceContainerHigh.of(context),
          borderRadius: BorderRadius.circular(20.px),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _buildSegmentButton(
                mode: QRCodePageMode.code,
                label: Localized.text('ox_usercenter.code'),
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                mode: QRCodePageMode.scan,
                label: Localized.text('ox_usercenter.scan'),
              ),
            ),
          ],
        ),
      );
    } else {
      // Cupertino style segment control - use Center and IntrinsicWidth
      // to properly size the control in CupertinoNavigationBar's middle slot
      return Center(
        child: IntrinsicWidth(
          child: CupertinoSlidingSegmentedControl<QRCodePageMode>(
            children: {
              QRCodePageMode.code: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.px),
                child: Text(Localized.text('ox_usercenter.code')),
              ),
              QRCodePageMode.scan: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.px),
                child: Text(Localized.text('ox_usercenter.scan')),
              ),
            },
            groupValue: currentMode,
            onValueChanged: (QRCodePageMode? value) {
              if (value != null) {
                setState(() {
                  currentMode = value;
                });
              }
            },
          ),
        ),
      );
    }
  }

  Widget _buildSegmentButton({
    required QRCodePageMode mode,
    required String label,
  }) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentMode = mode;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.px),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorToken.surface.of(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.px),
        ),
        child: Center(
          child: CLText.bodyMedium(
            label,
            colorToken: isSelected
                ? ColorToken.onSurface
                : ColorToken.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (currentMode == QRCodePageMode.scan) {
      return _buildScanPage();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // QR Code Card - Blue background with QR code
          RepaintBoundary(
            key: qrWidgetKey,
            child: Padding(
              padding: EdgeInsets.only(
                left: horizontal,
                top: 20.px,
                right: horizontal,
              ),
              child: _buildQRCodeCard(),
            ),
          ),

          // Action buttons (Link, Share, Color)
          SizedBox(height: 24.px),
          _buildActionButtons(),

          // Warning text
          SizedBox(height: 24.px),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: CLText.bodySmall(
              Localized.text('ox_usercenter.qr_code_share_warning'),
              textAlign: TextAlign.center,
              colorToken: ColorToken.onSurfaceVariant,
            ),
          ),

          // Reset button
          SizedBox(height: 24.px),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: CLButton.outlined(
              text: Localized.text('ox_usercenter.reset'),
              onTap: widget.otherUser == null && currentInviteLink != null
                  ? _showRegenerateConfirmDialog
                  : null,
              expanded: true,
            ),
          ),

          SafeArea(child: SizedBox(height: 12.px))
        ],
      ),
    );
  }

  Widget _buildScanPage() {
    return CommonScanPage();
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
      ),
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
            color: ColorToken.surfaceContainerHigh.of(context),
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

  Widget _buildUserHeader() {
    return Row(
      children: [
        OXUserAvatar(
          imageUrl: userNotifier.picture ?? '',
          size: 56.px,
        ),
        SizedBox(width: 16.px),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CLText.titleMedium(
                userName,
                maxLines: 1,
                colorToken: ColorToken.onSurface,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.px),
              CLText.bodySmall(
                userNotifier.shortEncodedPubkey,
                colorToken: ColorToken.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.px, 40.px, 20.px, 20.px),
      decoration: BoxDecoration(
        color: selectedColor, // Selected color background
        borderRadius: BorderRadius.circular(16.px),
      ),
      child: Column(
        children: [
          // QR Code with center icon
          _buildQRCodeWithCenterIcon(),

          SizedBox(height: 16.px),

          // Username with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 16.px,
                color: Colors.white,
              ),
              SizedBox(width: 8.px),
              CLText.bodyMedium(
                userName,
                textAlign: TextAlign.center,
                colorToken: ColorToken.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverableByIDOption() {
    return Container(
      padding: EdgeInsets.all(16.px),
      decoration: BoxDecoration(
        color: ColorToken.cardContainer.of(context),
        borderRadius: BorderRadius.circular(12.px),
      ),
      child: Row(
        children: [
          // Icon
          ValueListenableBuilder<bool>(
            valueListenable: discoverableByID$,
            builder: (context, isDiscoverable, _) {
              return Container(
                width: 40.px,
                height: 40.px,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDiscoverable
                      ? const Color(0xFFE8F5E9) // Light green background
                      : ColorToken.surfaceContainer.of(context),
                ),
                child: Icon(
                  isDiscoverable
                      ? (PlatformStyle.isUseMaterial
                          ? Icons.public
                          : CupertinoIcons.globe)
                      : (PlatformStyle.isUseMaterial
                          ? Icons.lock_outline
                          : CupertinoIcons.lock),
                  size: 20.px,
                  color: isDiscoverable
                      ? const Color(0xFF2E7D32) // Dark green color for globe icon
                      : ColorToken.onSurfaceVariant.of(context),
                ),
              );
            },
          ),
          SizedBox(width: 12.px),
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CLText.titleMedium(
                  Localized.text('ox_usercenter.discoverable_by_id'),
                  colorToken: ColorToken.onSurface,
                ),
                SizedBox(height: 4.px),
                ValueListenableBuilder<bool>(
                  valueListenable: discoverableByID$,
                  builder: (context, isDiscoverable, _) {
                    return CLText.bodySmall(
                      Localized.text(isDiscoverable
                          ? 'ox_usercenter.discoverable_by_id_description_on'
                          : 'ox_usercenter.discoverable_by_id_description_off'),
                      colorToken: ColorToken.onSurfaceVariant,
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 12.px),
          // Switch
          ValueListenableBuilder<bool>(
            valueListenable: discoverableByID$,
            builder: (context, value, _) {
              return CLSwitch(
                value: value,
                onChanged: (newValue) async {
                  // Only allow toggle for current user
                  if (widget.otherUser != null) return;
                  
                  discoverableByID$.value = newValue;
                  await UserConfigTool.saveSetting('discoverable_by_id', newValue);
                  
                  // Show loading
                  OXLoading.show();
                  
                  try {
                    bool success = false;
                    
                    if (newValue) {
                      // Switch ON: Enable discoverable by ID
                      success = await Groups.sharedInstance.enableDiscoverableByID();
                      if (success) {
                        CommonToast.instance.show(context, Localized.text('ox_usercenter.discoverable_by_id_enabled'));
                      } else {
                        // Failed to enable, revert switch
                        discoverableByID$.value = false;
                        await UserConfigTool.saveSetting('discoverable_by_id', false);
                        CommonToast.instance.show(context, Localized.text('ox_usercenter.failed_to_enable_discoverable'));
                      }
                    } else {
                      // Switch OFF: Disable discoverable by ID
                      success = await Groups.sharedInstance.disableDiscoverableByID();
                      if (success) {
                        CommonToast.instance.show(context, Localized.text('ox_usercenter.discoverable_by_id_disabled'));
                      } else {
                        // Failed to disable, revert switch
                        discoverableByID$.value = true;
                        await UserConfigTool.saveSetting('discoverable_by_id', true);
                        CommonToast.instance.show(context, Localized.text('ox_usercenter.failed_to_toggle_discoverable'));
                      }
                    }
                  } catch (e) {
                    print('Failed to toggle discoverable by ID: $e');
                    // Revert switch on error
                    discoverableByID$.value = !newValue;
                    await UserConfigTool.saveSetting('discoverable_by_id', !newValue);
                    CommonToast.instance.show(context, Localized.text('ox_usercenter.failed_to_toggle_discoverable'));
                  } finally {
                    OXLoading.dismiss();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeWithCenterIcon() {
    final double containerPadding = 16.px;
    final double innerDefaultExtent = 220.px;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - (horizontal * 2);
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

        return Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(containerPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.px),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildStyledQRCode(qrCanvasSize),
                // Center icon overlay
                Container(
                  width: 48.px,
                  height: 48.px,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.px),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/icon_chat_settings_left.png',
                        package: 'ox_usercenter',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyledQRCode(double size) {
    final double qrPadding = 6.px;
    final double qrSide = math.max(0, size - (qrPadding * 2));

    if (size <= 0 || size.isNaN) {
      return const SizedBox.shrink();
    }

    if (qrImage == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 64.px,
                color: ColorToken.onSurfaceVariant.of(context),
              ),
              SizedBox(height: 16.px),
              CLText.bodyMedium(
                currentInviteLink == null
                    ? Localized.text('ox_usercenter.empty_invite_link')
                    : Localized.text('ox_usercenter.qr_generation_failed'),
                colorToken: ColorToken.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
          curve: Curves.ease,
          duration: const Duration(milliseconds: 300),
          builder: (context, decoration, child) {
            return PrettyQrView(
              qrImage: qrImage!,
              decoration: decoration,
            );
          },
        ),
      ),
    );
  }

  void changeQrStyle(QRCodeStyle style) {
    setState(() {
      currentStyle = style;
      previousDecoration = currentDecoration;
      currentDecoration = createDecoration(style);
    });
  }
  
  void changeQrColor(Color color) {
    setState(() {
      selectedColor = color;
      previousDecoration = currentDecoration;
      currentDecoration = createDecoration(currentStyle);
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
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/QRCode_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      await OXLoading.dismiss();

      // Share the image file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: Localized.text('ox_usercenter.invite_to_chat'),
      );

      // Clean up temporary file after a delay
      Future.delayed(const Duration(seconds: 5), () {
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

  void _showColorPicker() {
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
    
    Color tempSelectedColor = selectedColor;
    
    if (PlatformStyle.isUseMaterial) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 24.px),
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.px),
                        topRight: Radius.circular(16.px),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: CLText.titleMedium(
                              Localized.text('ox_usercenter.color'),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: ColorToken.primary.of(context)),
                          onPressed: () {
                            changeQrColor(tempSelectedColor);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  // QR Code Preview
                  Container(
                    margin: EdgeInsets.all(16.px),
                    padding: EdgeInsets.all(20.px),
                    decoration: BoxDecoration(
                      color: tempSelectedColor,
                      borderRadius: BorderRadius.circular(16.px),
                    ),
                    child: Column(
                      children: [
                        _buildQRCodePreview(tempSelectedColor),
                        SizedBox(height: 16.px),
                        CLText.bodyMedium(
                          userName,
                          colorToken: ColorToken.onPrimary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Color Palette
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 8.px),
                    child: Wrap(
                      spacing: 16.px,
                      runSpacing: 16.px,
                      alignment: WrapAlignment.center,
                      children: colors.map((color) {
                        final bool isSelected = color == tempSelectedColor;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              tempSelectedColor = color;
                            });
                          },
                          child: Container(
                            width: 48.px,
                            height: 48.px,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: isSelected ? 3.px : 0,
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
          ),
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 24.px),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: ColorToken.surface.of(context),
                borderRadius: BorderRadius.circular(16.px),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.xmark),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: CLText.titleMedium(
                              Localized.text('ox_usercenter.color'),
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.check_mark, color: ColorToken.primary.of(context)),
                          onPressed: () {
                            changeQrColor(tempSelectedColor);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  // QR Code Preview
                  Container(
                    margin: EdgeInsets.all(16.px),
                    padding: EdgeInsets.all(20.px),
                    decoration: BoxDecoration(
                      color: tempSelectedColor,
                      borderRadius: BorderRadius.circular(16.px),
                    ),
                    child: Column(
                      children: [
                        _buildQRCodePreview(tempSelectedColor),
                        SizedBox(height: 16.px),
                        CLText.bodyMedium(
                          userName,
                          colorToken: ColorToken.onPrimary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Color Palette
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 8.px),
                    child: Wrap(
                      spacing: 16.px,
                      runSpacing: 16.px,
                      alignment: WrapAlignment.center,
                      children: colors.map((color) {
                        final bool isSelected = color == tempSelectedColor;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              tempSelectedColor = color;
                            });
                          },
                          child: Container(
                            width: 48.px,
                            height: 48.px,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: isSelected ? 3.px : 0,
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
          ),
        ),
      );
    }
  }
  
  Widget _buildQRCodePreview(Color color) {
    if (qrImage == null) return SizedBox.shrink();
    
    final double containerPadding = 16.px;
    final decoration = createDecoration(currentStyle, customColor: color);
    
    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.px),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200.px,
            height: 200.px,
            child: TweenAnimationBuilder<PrettyQrDecoration>(
              tween: PrettyQrDecorationTween(
                begin: currentDecoration,
                end: decoration,
              ),
              curve: Curves.ease,
              duration: const Duration(milliseconds: 200),
              builder: (context, animatedDecoration, child) {
                return PrettyQrView(
                  qrImage: qrImage!,
                  decoration: animatedDecoration,
                );
              },
            ),
          ),
          // Center icon overlay
          Container(
            width: 48.px,
            height: 48.px,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Padding(
              padding: EdgeInsets.all(4.px),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/icon_chat_settings_left.png',
                  package: 'ox_usercenter',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




  Future<void> _regenerateInviteLink() async {
    try {
      OXLoading.show();

      // Recreate permanent keypackage
      KeyPackageEvent? keyPackageEvent = await Groups.sharedInstance.recreatePermanentKeyPackage(
        Account.sharedInstance.getCurrentCircleRelay(),
      );

      if (keyPackageEvent == null) {
        await OXLoading.dismiss();
        CommonToast.instance.show(context, Localized.text('ox_usercenter.invite_link_generation_failed'));
        return;
      }

      // Get relay URL
      List<String> relays = Account.sharedInstance.getCurrentCircleRelay();
      String relayUrl = relays.isNotEmpty ? relays.first : 'wss://relay.0xchat.com';

      // Generate new invite link
      currentInviteLink = '${AppConfig.inviteBaseUrl}?eventid=${Uri.encodeComponent(keyPackageEvent.eventId)}&relay=${Uri.encodeComponent(relayUrl)}';

      // Update QR code data
      currentQrCodeData = currentInviteLink;

      // Initialize QR code and image with optimized settings for long URLs
      try {
        // Use lower error correction level for better readability with long URLs
        qrCode = QrCode.fromData(
          data: currentQrCodeData!,
          errorCorrectLevel: QrErrorCorrectLevel.L, // Use lowest error correction level
        );
        qrImage = QrImage(qrCode!);
      } catch (e) {
        print('QR code generation failed: $e');
        qrCode = null;
        qrImage = null;
        CommonToast.instance.show(context, Localized.text('ox_usercenter.qr_generation_failed'));
      }

      await OXLoading.dismiss();
      setState(() {});

      CommonToast.instance.show(context, Localized.text('ox_usercenter.invite_link_regenerated'));
    } catch (e) {
      await OXLoading.dismiss();
      CommonToast.instance.show(context, '${Localized.text('ox_usercenter.invite_link_generation_failed')}: $e');
    }
  }

  void _showRegenerateConfirmDialog() {
    CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.regenerate_invite_link'),
      content: Localized.text('ox_usercenter.regenerate_confirm_content'),
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