import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_login/page/private_relay_upgrade_page.dart';

class SubscriptionDetailPage extends StatefulWidget {
  const SubscriptionDetailPage({
    super.key,
    this.previousPageTitle,
  });

  final String? previousPageTitle;

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  // Mock data - TODO: Load from actual subscription service
  String _planName = 'Family';
  String _planFullName = 'Family Plan';
  String _price = '\$5.99';
  String _period = '/mo';
  bool _isActive = true;
  bool _isCancelled = false;
  String _expiryDate = 'Dec 31, 2025';

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        previousPageTitle: widget.previousPageTitle,
        title: Localized.text('ox_usercenter.subscription'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubscriptionCard(),
            SizedBox(height: 24.px),
            _buildRenewButton(),
            SizedBox(height: 24.px),
            _buildCancelSubscriptionLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: EdgeInsets.all(20.px),
      decoration: BoxDecoration(
        color: ColorToken.surface.of(context),
        borderRadius: BorderRadius.circular(12.px),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon and name
          Row(
            children: [
              Container(
                width: 60.px,
                height: 60.px,
                decoration: BoxDecoration(
                  color: ColorToken.onSurface.of(context),
                  borderRadius: BorderRadius.circular(12.px),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: const Color(0xFFFFC107), // Yellow crown
                  size: 32.px,
                ),
              ),
              SizedBox(width: 16.px),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  CLText.titleLarge(
                    _planName,
                    colorToken: ColorToken.onSurface,
                    isBold: true,
                  ),
                  SizedBox(height: 4.px),
                  CLText.bodyMedium(
                    _planFullName,
                    colorToken: ColorToken.onSurface,
                  ),
                ]),
              ),
            ],
          ),
          SizedBox(height: 16.px),
          // Plan details with view all plans link
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CLText.bodyMedium(
                      '$_planFullName (${Localized.text('ox_login.monthly')})',
                      colorToken: ColorToken.onSurface,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  OXNavigator.pushPage(
                    context,
                    (context) => PrivateRelayUpgradePage(),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CLText.bodySmall(
                      Localized.text('ox_usercenter.view_all_plans'),
                      customColor: ColorToken.xChat.of(context),
                    ),
                    SizedBox(width: 4.px),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14.px,
                      color: ColorToken.xChat.of(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.px),
          // Status
          if (_isCancelled) ...[
            CLText.bodyMedium(
              Localized.text('ox_usercenter.subscription_cancelled'),
              customColor: ColorToken.error.of(context),
            ),
            SizedBox(height: 4.px),
            CLText.bodySmall(
              Localized.text('ox_usercenter.subscription_expired_on').replaceAll('{date}', _expiryDate),
              colorToken: ColorToken.onSurface,
            ),
          ] else if (_isActive) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.px,
                    vertical: 4.px,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.px),
                  ),
                  child: CLText.labelSmall(
                    Localized.text('ox_usercenter.active'),
                    customColor: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 12.px),
                Expanded(
                  child: CLText.bodySmall(
                    Localized.text('ox_usercenter.renews_on').replaceAll('{date}', _expiryDate),
                    colorToken: ColorToken.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRenewButton() {
    if (!_isCancelled) return const SizedBox.shrink();

    return CLButton.filled(
      text: '${Localized.text('ox_usercenter.renew')}: $_price$_period',
      onTap: () {
        // TODO: Implement renew subscription
        CommonToast.instance.show(context, 'Renew feature coming soon');
      },
      expanded: true,
      height: 50.px,
    );
  }

  Widget _buildCancelSubscriptionLink() {
    if (_isCancelled) return const SizedBox.shrink();

    return Center(
      child: GestureDetector(
        onTap: () {
          _showCancelSubscriptionDialog(context);
        },
        child: CLText.bodySmall(
          Localized.text('ox_usercenter.cancel_subscription'),
          customColor: ColorToken.error.of(context),
        ),
      ),
    );
  }

  Future<void> _showCancelSubscriptionDialog(BuildContext context) async {
    CLAlertDialog.show<bool>(
      context: context,
      title: Localized.text('ox_usercenter.cancel_subscription_title'),
      content: Localized.text('ox_usercenter.cancel_subscription_content'),
      actions: [
        CLAlertAction.cancel(),
        CLAlertAction<bool>(
          label: Localized.text('ox_usercenter.cancel_subscription'),
          value: true,
          isDestructiveAction: true,
        ),
      ],
    ).then((confirmed) {
      if (confirmed == true) {
        // TODO: Implement cancel subscription logic
        setState(() {
          _isCancelled = true;
          _isActive = false;
        });
        CommonToast.instance.show(context, 'Subscription cancelled successfully');
      }
    });
  }
}

