import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:chatcore/chat-core.dart';
import 'package:isar/isar.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/model/chat_session_model_isar.dart';
import 'package:ox_common/utils/ox_chat_binding.dart';
import 'package:ox_common/utils/ox_chat_observer.dart';

import 'session_list_mixin.dart';
import 'session_view_model.dart';

class SessionListDataController with OXChatObserver, SessionListMixin {
  SessionListDataController(this.ownerPubkey, this.circle);
  final String ownerPubkey;
  final Circle circle;

  HashMap<String, SessionListViewModel> allSessionCache =
    HashMap<String, SessionListViewModel>();

  ValueNotifier<bool> hasArchivedChats$ = ValueNotifier(false);

  @override
  bool get shouldPushNotification => true;

  @override
  int compareSession(ChatSessionModelISAR a, ChatSessionModelISAR b) {
    // First compare by alwaysTop (pinned sessions come first)
    if (a.alwaysTop != b.alwaysTop) {
      return b.alwaysTop ? 1 : -1;
    }
    // Then sort by lastActivityTime descending
    return b.lastActivityTime.compareTo(a.lastActivityTime);
  }

  @override
  Future<List<SessionListViewModel>> initializedSessionList() async {
    final isar = DBISAR.sharedInstance.isar;
    final List<ChatSessionModelISAR> sessionList = isar
        .chatSessionModelISARs
        .where()
        .chatIdIsNotEmpty()
        .group((q) => q.isArchivedIsNull().or().isArchivedEqualTo(false))
        .sortByAlwaysTopDesc()
        .thenByLastActivityTimeDesc()
        .findAll();

    final viewModelData = <SessionListViewModel>[];
    for (var sessionModel in sessionList) {
      final viewModel = SessionListViewModel(sessionModel);
      viewModelData.add(viewModel);
    }

    return viewModelData;
  }

  @override
  Future deleteSessionCallback(List<String> chatIds) async {
    await super.deleteSessionCallback(chatIds);
    _updateArchivedChatsStatus();
  }

  @override
  void didSessionUpdate(ChatSessionModelISAR session) {
    final viewModel = sessionCache[session.chatId];
    if (viewModel != null && session.isArchivedSafe) {
      removeViewModel(viewModel);
    } else if (viewModel == null && !session.isArchivedSafe) {
      addViewModel(SessionListViewModel(session));
    }
  }

  @override
  Future<void> initialized() async {
    await super.initialized();

    _updateArchivedChatsStatus();

    OXChatBinding.sharedInstance.sessionModelFetcher =
        (chatId) => allSessionCache[chatId]?.sessionModel;
    OXChatBinding.sharedInstance.sessionListFetcher =
        () => sessionList$.value.map((e) => e.sessionModel).toList();
  }
}

extension SessionDCInterface on SessionListDataController {
  void _updateArchivedChatsStatus() {
    final isar = DBISAR.sharedInstance.isar;
    final archivedSession = isar.chatSessionModelISARs.where()
        .isArchivedEqualTo(true)
        .findAll();
    hasArchivedChats$.value = archivedSession.isNotEmpty;
  }
}