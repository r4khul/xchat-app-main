import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../widgets/archived_session_list_controller.dart';
import '../widgets/session_list_item_widget.dart';
import '../widgets/session_view_model.dart';

class ArchivedChatsPage extends StatefulWidget {
  const ArchivedChatsPage({
    super.key,
    required this.ownerPubkey,
    required this.circle,
  });

  final String ownerPubkey;
  final Circle circle;

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  ArchivedSessionListController? controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _initializeController() {
    if (widget.ownerPubkey.isNotEmpty) {
      controller = ArchivedSessionListController(widget.ownerPubkey, widget.circle);
      controller!.initialized();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      backgroundColor: ColorToken.surface.of(context),
      appBar: CLAppBar(
        title: Localized.text('ox_chat.archived_chats'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller == null || widget.ownerPubkey.isEmpty) {
      return Center(
        child: CLProgressIndicator.circular(),
      );
    }

    return ValueListenableBuilder(
      valueListenable: controller!.sessionList$,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: EdgeInsets.only(bottom: Adapt.bottomSafeAreaHeightByKeyboard),
          itemBuilder: (context, index) => _itemBuilder(context, value[index]),
          separatorBuilder: _separatorBuilder,
          itemCount: value.length,
        );
      },
    );
  }

  Widget _itemBuilder(BuildContext context, SessionListViewModel item) {
    return SessionListItemWidget(
      item: item,
      sessionListController: controller,
      showPinnedBackground: false,
    );
  }

  Widget _separatorBuilder(BuildContext context, int index) {
    if (PlatformStyle.isUseMaterial) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(left: 72.px),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -120.px),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.px),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.archivebox,
                size: 120.px,
                color: PlatformStyle.isUseMaterial
                    ? ColorToken.primary.of(context)
                    : CupertinoTheme.of(context)
                        .textTheme
                        .actionSmallTextStyle
                        .color,
              ),
              SizedBox(height: 24.px),
              CLText.titleMedium(
                Localized.text('ox_chat.no_archived_chats'),
                colorToken: ColorToken.onSurface,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

