import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/circle_join_utils.dart';
import 'package:ox_common/utils/user_search_manager.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:chatcore/chat-core.dart';
import 'package:lpinyin/lpinyin.dart';

import 'select_group_members_page.dart';
import 'find_people_page.dart';
import '../../utils/chat_session_utils.dart';
import 'package:ox_usercenter/page/settings/qr_code_display_page.dart';

class CLNewMessagePage extends StatefulWidget {
  const CLNewMessagePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CLNewMessagePageState();
  }
}

class _CLNewMessagePageState extends State<CLNewMessagePage> {

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool get isSearchOnFocus => _searchFocusNode.hasFocus;

  List<ValueNotifier<UserDBISAR>> _allUsers = [];
  Map<String, List<ValueNotifier<UserDBISAR>>> _groupedUsers = {};
  late final UserSearchManager<ValueNotifier<UserDBISAR>> _userSearchManager;

  // For tracking scroll-based background color changes
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _userSearchManager = UserSearchManager.defaultCreate(
      debounceDelay: const Duration(milliseconds: 300),
      minSearchLength: 1,
      maxResults: 50,
    );

    // Add search result listener for immediate UI updates
    _userSearchManager.resultNotifier.addListener(_onSearchResultChanged);

    _loadData();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollOffset.dispose();
    _userSearchManager.resultNotifier.removeListener(_onSearchResultChanged);
    _userSearchManager.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      await _userSearchManager.initialize();
      _allUsers = _userSearchManager.allUsers;
      _groupUsers();
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() {});
    }
  }

  void _groupUsers() {
    _groupedUsers.clear();

    for (final user$ in _allUsers) {
      final showName = _getUserShowName(user$);
      String firstChar = '#';

      if (showName.isNotEmpty) {
        final firstCharacter = showName[0];
        if (RegExp(r'[a-zA-Z]').hasMatch(firstCharacter)) {
          firstChar = firstCharacter.toUpperCase();
        } else if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(firstCharacter)) {
          // Chinese character, get pinyin first letter
          final pinyin = PinyinHelper.getFirstWordPinyin(firstCharacter);
          if (pinyin.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(pinyin[0])) {
            firstChar = pinyin[0].toUpperCase();
          }
        }
      }

      _groupedUsers.putIfAbsent(firstChar, () => []).add(user$);
    }

    // Sort users within each group
    _groupedUsers.forEach((key, users) {
      users.sort((a, b) => _getUserShowName(a).compareTo(_getUserShowName(b)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return CLScaffold(
      appBar: CLAppBar(
        title: Localized.text('ox_chat.str_title_new_message'),
        actions: [
          if (PlatformStyle.isUseMaterial)
            CLButton.icon(
              icon: PlatformStyle.isUseMaterial
                  ? Icons.person_add
                  : CupertinoIcons.person_add,
              onTap: _onAddFriends,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 80.px),
          child: _buildSearchBar(),
        ),
      ),
      isSectionListPage: true,
      body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _searchFocusNode.unfocus();
          },
          child: isSearchOnFocus || _searchController.text.isNotEmpty
              ? _buildSearchResults()
              : _buildUserList()
      ),
    );
  }

  Widget _buildSearchBar() {
    return CLSearch(
      padding: EdgeInsets.symmetric(
        vertical: 16.px,
        horizontal: CLLayout.horizontalPadding,
      ),
      controller: _searchController,
      focusNode: _searchFocusNode,
      placeholder: Localized.text('ox_common.search_npub_or_username'),
      showClearButton: true,
      onSubmitted: _onSubmittedHandler,
    );
  }

  Widget _buildUserList() {
    if (_userSearchManager.isLoading) {
      return SizedBox.expand();
    }

    return CLSectionListView(
      items: [
        menuSection(),
        ...userListSectionItems(),
      ],
    );
  }

  SectionListViewItem menuSection() {
    return SectionListViewItem(
      data: [
        LabelItemModel(
          icon: ListViewIcon(
            iconName: 'icon_new_group.png',
            package: 'ox_common',
          ),
          title: Localized.text('ox_chat.str_new_group'),
          onTap: _onNewGroup,
        ),

        LabelItemModel(
          icon: ListViewIcon.data(
            PlatformStyle.isUseMaterial
                ? Icons.person_add
                : CupertinoIcons.person_add,
          ),
          title: Localized.text('ox_chat.add_friends'),
          onTap: _onAddFriends,
        ),
        LabelItemModel(
          icon: ListViewIcon.data(
            Icons.share,
          ),
          title: Localized.text('ox_usercenter.invite'),
          onTap: _onInviteFriends,
        ),
      ],
    );
  }

  List<SectionListViewItem> userListSectionItems() {
    final list = <SectionListViewItem>[];

    final sortedKeys = _groupedUsers.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    for (final key in sortedKeys) {
      final users = _groupedUsers[key]!;
      list.add(SectionListViewItem(
        header: key,
        data: users.map((user$) => userListItem(user$)).toList(),
      ));
    }

    return list;
  }

  ListViewItem userListItem(ValueNotifier<UserDBISAR> user$) {
    final circleType = LoginManager.instance.currentCircle?.type;
    final currentPubkey = LoginManager.instance.currentPubkey;
    final isSelf = user$.value.pubKey == currentPubkey;
    
    if (isSelf) {
      // Special UI for self (file transfer assistant)
      return CustomItemModel(
        leading: ValueListenableBuilder(
          valueListenable: user$,
          builder: (context, user, _) {
            return _buildSelfAvatar(context);
          }
        ),
        titleWidget: ValueListenableBuilder(
          valueListenable: user$,
          builder: (context, user, _) {
            return Row(
              children: [
                CLText.bodyMedium(
                  '${Localized.text('ox_common.me')} (${Localized.text('ox_chat.file_transfer_assistant')})',
                  colorToken: ColorToken.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 8.px),
                _buildYourselfTag(context),
              ],
            );
          }
        ),
        subtitleWidget: circleType == CircleType.bitchat ? null : CLText.bodySmall(
          '${user$.value.encodedPubkey} (${Localized.text('ox_chat.click_to_send_message_to_yourself')})',
          colorToken: ColorToken.onSurfaceVariant,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _onUserTap(user$),
      );
    }
    
    // Normal user item
    return CustomItemModel(
      leading: ValueListenableBuilder(
        valueListenable: user$,
        builder: (context, user, _) {
          return OXUserAvatar(
            user: user,
            size: 40.px,
            isClickable: false,
          );
        }
      ),
      titleWidget: ValueListenableBuilder(
        valueListenable: user$,
        builder: (context, user, _) {
          return CLText.bodyMedium(
            _getUserShowName(user$),
            colorToken: ColorToken.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      ),
      subtitleWidget: circleType == CircleType.bitchat ? null : CLText.bodySmall(
        user$.value.encodedPubkey,
        colorToken: ColorToken.onSurfaceVariant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _onUserTap(user$),
    );
  }

  Widget _buildSelfAvatar(BuildContext context) {
    return Container(
      width: 40.px,
      height: 40.px,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: CLThemeData.themeGradientOf(context),
      ),
      child: Center(
        child: CLText.bodyLarge(
          Localized.text('ox_common.me'),
          customColor: Colors.white,
          isBold: true,
        ),
      ),
    );
  }

  Widget _buildYourselfTag(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 2.px),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.px),
        gradient: CLThemeData.themeGradientOf(context),
      ),
      child: CLText.labelSmall(
        Localized.text('ox_chat.yourself'),
        customColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isSearchOnFocus && _searchController.text.isEmpty) {
      return SizedBox.expand();
    }

    return ValueListenableBuilder<SearchResult<ValueNotifier<UserDBISAR>>>(
      valueListenable: _userSearchManager.resultNotifier,
      builder: (context, searchResult, child) {
        // Show loading indicator when searching
        if (searchResult.state == SearchState.searching) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.px),
              child: CLProgressIndicator.circular(),
            ),
          );
        }

        // Show empty results
        if (searchResult.results.isEmpty) {
          final query = _searchController.text.trim();
          final potentialRemote = query.startsWith('npub') || query.contains('@');

          // Hide empty UI when typing or potential remote search
          if (searchResult.state == SearchState.typing ||
              (potentialRemote && isSearchOnFocus)) {
            return SizedBox.expand();
          }

          return _buildEmptySearchResults();
        }

        // Show search results
        final sections = <SectionListViewItem>[
          SectionListViewItem(
            data: searchResult.results.map((user) => userListItem(user)).toList(),
          ),
        ];

        return CLSectionListView(
          items: sections,
        );
      },
    );
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.px),
        child: CLText.bodyLarge(
          'No "${_searchController.text}" results found',
          colorToken: ColorToken.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static String _getUserShowName(ValueNotifier<UserDBISAR> user$) {
    final user = user$.value;
    final name = user.name ?? '';
    final nickName = user.nickName ?? '';

    if (name.isNotEmpty && nickName.isNotEmpty) {
      return '$name($nickName)';
    } else if (name.isNotEmpty) {
      return name;
    } else if (nickName.isNotEmpty) {
      return nickName;
    }
    return user.shortEncodedPubkey;
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _userSearchManager.search(query);
  }

  void _onSearchResultChanged() {
    if (mounted) {
      // Update local users list with any new users from remote search
      final searchResults = _userSearchManager.results;
      bool hasNewUsers = false;
      
      for (final searchUser$ in searchResults) {
        // Check if this user is not in our local list
        if (!_allUsers.any((user$) => user$.value.pubKey == searchUser$.value.pubKey)) {
          _allUsers.add(searchUser$);
          hasNewUsers = true;
        }
      }
      
      // Re-group users only if we added new ones (performance optimization)
      if (hasNewUsers) {
        _groupUsers();
      }
      
      setState(() {});
    }
  }

  void _onFocusChanged() {
    setState(() {});
  }



  void _onAddFriends() {
    OXNavigator.pushPage(
      context,
      (context) => const FindPeoplePage(),
    );
  }

  void _onNewGroup() {
    OXNavigator.pushPage(context, (context) => const SelectGroupMembersPage());
  }

  void _onInviteFriends() {
    final circle = LoginManager.instance.currentCircle;
    if (circle == null) {
      CircleJoinUtils.showJoinCircleGuideDialog(context: OXNavigator.rootContext);
      return;
    }
    
    OXNavigator.pushPage(
      context, 
      (context) => const QRCodeDisplayPage(),
    );
  }

  void _onUserTap(ValueNotifier<UserDBISAR> user$) async {
    await ChatSessionUtils.createSecretChatWithConfirmation(
      context: context,
      user: user$.value,
      isPushWithReplace: true,
    );
  }

  void _onSubmittedHandler(String text) async {
    text = text.trim();
    if (text.isEmpty) return;

    // Use immediate search for submit action
    await _userSearchManager.searchImmediate(text);
  }
}
