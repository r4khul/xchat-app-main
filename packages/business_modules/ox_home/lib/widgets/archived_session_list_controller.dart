import 'package:chatcore/chat-core.dart';
import 'package:isar/isar.dart';
import 'package:ox_common/login/login_models.dart';
import 'package:ox_common/model/chat_session_model_isar.dart';
import 'package:ox_common/utils/ox_chat_observer.dart';

import 'session_list_mixin.dart';
import 'session_view_model.dart';

class ArchivedSessionListController with OXChatObserver, SessionListMixin {
  ArchivedSessionListController(this.ownerPubkey, this.circle);
  final String ownerPubkey;
  final Circle circle;

  @override
  bool get shouldPushNotification => true;

  @override
  int compareSession(ChatSessionModelISAR a, ChatSessionModelISAR b) {
    return b.lastActivityTime.compareTo(a.lastActivityTime);
  }

  @override
  Future<List<SessionListViewModel>> initializedSessionList() async {
    final isar = DBISAR.sharedInstance.isar;
    final List<ChatSessionModelISAR> archivedSessions = isar
        .chatSessionModelISARs
        .where()
        .chatIdIsNotEmpty()
        .isArchivedEqualTo(true)
        .sortByLastActivityTimeDesc()
        .findAll();

    final viewModelData = <SessionListViewModel>[];
    for (var sessionModel in archivedSessions) {
      final viewModel = SessionListViewModel(sessionModel);
      viewModelData.add(viewModel);
    }

    return viewModelData;
  }

  @override
  void didSessionUpdate(ChatSessionModelISAR session) {
    final viewModel = sessionCache[session.chatId];
    if (viewModel != null && !session.isArchivedSafe) {
      removeViewModel(viewModel);
    } else if (viewModel == null && session.isArchivedSafe) {
      addViewModel(SessionListViewModel(session));
    }
  }
}

