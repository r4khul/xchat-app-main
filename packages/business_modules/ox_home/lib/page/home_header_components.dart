import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_common/network/ping_helper.dart';
import 'package:ox_common/utils/relay_latency_handler.dart';

class CircleItem {
  CircleItem({
    required this.id,
    required this.name,
    this.iconUrl = '',
    required this.relayUrl,
    required this.type,
  });

  final String id;
  final String name;
  final String iconUrl;
  final String relayUrl;
  final CircleType type;
}

class HomeHeaderComponents {
  HomeHeaderComponents({
    required this.circles,
    required this.selectedCircle$,
    this.onCircleSelected,
    required this.relayStatus$,
    this.avatarOnTap,
    this.nameOnTap,
    this.addOnTap,
    this.joinOnTap,
    this.paidOnTap,
    required this.isShowExtendBody$,
    required this.extendBodyDuration,
    required RelayLatencyHandler latencyHandler,
  }) {
    _latencyHandler = latencyHandler;
    _setupLatency();
  }

  /// List of circle items for the sub-bar
  final List<CircleItem> circles;
  /// Currently selected circle value
  final ValueNotifier<CircleItem?> selectedCircle$;
  /// Called when a circle is selected
  final ValueChanged<CircleItem>? onCircleSelected;

  final ValueNotifier<ConnectStatus> relayStatus$;

  GestureTapCallback? avatarOnTap;
  GestureTapCallback? nameOnTap;
  GestureTapCallback? addOnTap;
  GestureTapCallback? joinOnTap;
  GestureTapCallback? paidOnTap;

  ValueNotifier<bool> isShowExtendBody$;
  Duration extendBodyDuration;

  late final RelayLatencyHandler _latencyHandler;

  void _setupLatency() {
    selectedCircle$.addListener(selectedCircleChangedHandler);

    final initUrl = selectedCircle$.value?.relayUrl;
    if (initUrl != null) _latencyHandler.switchRelay(initUrl);
  }

  void selectedCircleChangedHandler() {
    final url = selectedCircle$.value?.relayUrl;
    if (url != null) _latencyHandler.switchRelay(url);
  }

  void dispose() {
    selectedCircle$.removeListener(selectedCircleChangedHandler);
  }

  AppBar buildAppBar(BuildContext ctx) => AppBar(
    leadingWidth: 280.px,
    leading: _buildLeading(),
    actions: [
      // if (PlatformStyle.isUseMaterial)
      //   CLButton.icon(
      //     iconName: 'icon_common_search.png',
      //     package: 'ox_common',
      //     iconSize: 24.px,
      //     onTap: onSearchTap,
      //   ),

      ValueListenableBuilder(
        valueListenable: selectedCircle$,
        builder: (context, selectedCircle, _) {
          return Visibility(
            visible: selectedCircle?.type != CircleType.bitchat,
            child: CLButton.icon(
              iconName: PlatformStyle.isUseMaterial
                  ? 'icon_common_add.png'
                  : 'icon_common_add_cupertino.png',
              package: 'ox_common',
              iconSize: 24.px,
              onTap: addOnTap,
            ).setPaddingOnly(right: 4.px),
          );
        },
      ),
    ],
    backgroundColor: ColorToken.surface.of(ctx),
  );

  Widget _buildLeading() {
    return ValueListenableBuilder(
      valueListenable: LoginManager.instance.state$,
      builder: (_, __, ___) {
        return Row(
          children: [
            _buildAvatar(),
            Expanded(child: _buildCircleName()),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Close circle list when avatar is tapped
        isShowExtendBody$.value = false;
        avatarOnTap?.call();
      },
      child: Padding(
        padding: EdgeInsets.all(12.px),
        child: ValueListenableBuilder(
          valueListenable: LoginUserNotifier.instance.userInfo$,
          builder: (_, userInfo, __) {
            return OXUserAvatar(
              user: userInfo,
              size: 32.px,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircleName() {
    return ValueListenableBuilder(
      valueListenable: selectedCircle$,
      builder: (_, selectedCircle, __) {
        return ValueListenableBuilder(
          valueListenable: relayStatus$,
          builder: (context, status, __) {
            return GestureDetector(
              onTap: circles.isNotEmpty ? nameOnTap : null,
              child: Row(
                children: [
                  Flexible(
                    child: _buildCircleTitleContent(context, selectedCircle, status),
                  ),
                  if (circles.isNotEmpty)
                    ValueListenableBuilder(
                      valueListenable: isShowExtendBody$,
                      builder: (context, isShowExtendBody, _) {
                        return AnimatedRotation(
                          turns: isShowExtendBody ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.arrow_drop_down,
                            color: ColorToken.onSurface.of(context),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircleTitleContent(BuildContext context, CircleItem? selectedCircle, ConnectStatus status) {
    final isConnected = status == ConnectStatus.open;
    if (isConnected) {
      return CLText.titleLarge(
        selectedCircle?.name ?? '',
        maxLines: 1,
      );
    }

    final statusText = CLText.titleMedium(
      _statusText(status),
      maxLines: 1,
      colorToken: ColorToken.onSurface,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (status == ConnectStatus.connecting)
          ...[
            CLProgressIndicator.circular(
              size: 20.px,
              color: ColorToken.onSurfaceVariant.of(context),
              useMaterialStyle: true, // force Android style for consistent size
            ),
            SizedBox(width: 6.px),
          ],
        Flexible(child: statusText),
      ],
    );
  }

  String _statusText(ConnectStatus status) {
    switch (status) {
      case ConnectStatus.connecting:
        return Localized.text('ox_home.circle_status_connecting')
            .replaceAll('\${circle}', '');
      case ConnectStatus.closing:
        return Localized.text('ox_home.circle_status_disconnecting');
      case ConnectStatus.closed:
        return Localized.text('ox_home.circle_status_disconnected');
      default:
        return Localized.text('ox_home.circle_status_unknown');
    }
  }

  Widget buildCircleList(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      color: ColorToken.surface.of(ctx),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            height: 36.px,
            alignment: Alignment.centerLeft,
            child: CLText.titleSmall(Localized.text('ox_common.circles')).setPaddingOnly(left: 16.px)
        ),
        ValueListenableBuilder(
          valueListenable: selectedCircle$,
          builder: (context, selectedCircle, __) {
            return CLListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              items: circles.map((circle) =>
                  _circleItemListTileMapper(circle, selectedCircle)).toList(),
            );
          },
        ),
        _buildOptionButtons(),
      ],
    ),
  );

  ListViewItem _circleItemListTileMapper(CircleItem item, CircleItem? selectedCircle) {
    final selected = item.id == selectedCircle?.id;
    final result$ = _latencyHandler.getPingResultNotifier(item.relayUrl);
    final subtitle = _buildRelaySubtitle(
      item: item,
      selected: selected,
      result$: result$,
    );

    return CustomItemModel(
      leading: CircleAvatar(
        child: Text(item.name.isNotEmpty ? item.name[0] : '?'),
      ),
      titleWidget: CLText(item.name),
      subtitleWidget: subtitle,
      trailing: CLRadio(
        value: item.id,
        groupValue: selectedCircle?.id,
      ),
      onTap: () => onCircleSelected?.call(item),
    );
  }

  Widget? _buildRelaySubtitle({
    required CircleItem item,
    required bool selected,
    required ValueNotifier<PingResult> result$,
  }) {
    if (item.type == CircleType.bitchat) return null;
    if (!selected) {
      return Text(
        item.relayUrl,
        overflow: TextOverflow.ellipsis,
      );
    }

    return ValueListenableBuilder<PingResult>(
      valueListenable: result$,
      builder: (_, result, __) {
        final color = result.relayStatusColor;
        final reachable = result.reachable && result.timeMs > 0;
        final latencyText = reachable ? '${result.timeMs}ms' : '--';
        final latencyStyle = reachable ? TextStyle(color: color) : null;

        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: latencyText, style: latencyStyle),
              const TextSpan(text: ' · '),
              TextSpan(text: item.relayUrl),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildOptionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.px,
        vertical: 12.px,
      ),
      child: Row(
        children: [
          Expanded(
            child: CLButton.filled(
              padding: EdgeInsets.symmetric(vertical: 12.px),
              text: Localized.text('ox_home.add_circle'),
              onTap: joinOnTap,
            ),
          ),
          // SizedBox(width: 10.px,),
          // Expanded(
          //   child: CLButton.tonal(
          //     padding: EdgeInsets.symmetric(vertical: 12.px),
          //     text: Localized.text('ox_home.new_paid_circle'),
          //     onTap: paidOnTap,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget buildMask() => ValueListenableBuilder(
    valueListenable: isShowExtendBody$,
    builder: (_, isShowExtendBody, __) {
      return IgnorePointer(
        ignoring: !isShowExtendBody,
        child: AnimatedOpacity(
          opacity: isShowExtendBody ? 1 : 0,
          duration: extendBodyDuration,
          child: GestureDetector(
            onTap: () {
              isShowExtendBody$.value = false;
            },
            child: Container(
              height: Adapt.screenH,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    },
  );

  void onSearchTap() {

  }
}