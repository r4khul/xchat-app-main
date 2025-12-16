import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_call/src/call_manager.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_session.dart';
import 'package:ox_call/src/pages/call_in_progress_page.dart';

/// Global call service that manages call UI presentation.
///
/// Responsibilities:
/// - Listen to CallManager state changes
/// - Show incoming call page when receiving a call
/// - Manage call page lifecycle (show/dismiss)
/// - Fetch caller information
class CallService {
  CallService._();

  static final CallService _instance = CallService._();
  static CallService get instance => _instance;

  bool _initialized = false;
  bool _isCallPageShowing = false;
  String? _currentCallSessionId;

  /// ValueNotifier for current call session, UI can listen to this for updates.
  final ValueNotifier<CallSession?> currentSession$ = ValueNotifier(null);

  /// ValueNotifier for remote stream.
  final ValueNotifier<MediaStream?> remoteStream$ = ValueNotifier(null);

  /// Initialize the call service.
  /// Should be called after CallManager is initialized.
  void initialize() {
    if (_initialized) return;
    CallManager().onCallStateChanged = _onCallStateChanged;
    CallManager().onRemoteStreamReady = _onRemoteStreamReady;
    _initialized = true;
  }

  /// Cleanup the call service.
  void cleanup() {
    CallManager().onCallStateChanged = null;
    CallManager().onRemoteStreamReady = null;
    currentSession$.value = null;
    remoteStream$.value = null;
    _isCallPageShowing = false;
    _currentCallSessionId = null;
    _initialized = false;
  }

  void _onCallStateChanged(CallSession session) {
    currentSession$.value = session;

    // Handle incoming call - show call page
    if (session.state == CallState.ringing &&
        session.direction == CallDirection.incoming) {
      _showIncomingCallPage(session);
      return;
    }

    // Handle outgoing call - show call page if not showing
    if ((session.state == CallState.ringing || session.state == CallState.connecting) &&
        session.direction == CallDirection.outgoing &&
        !_isCallPageShowing) {
      _showOutgoingCallPage(session);
      return;
    }

    // Handle call ended
    if (session.state == CallState.ended) {
      _onCallEnded(session);
    }
  }

  void _onRemoteStreamReady(String sessionId, MediaStream stream) {
    if (_currentCallSessionId == sessionId) {
      remoteStream$.value = stream;
    }
  }

  void _showIncomingCallPage(CallSession session) {
    if (_isCallPageShowing) return;

    _isCallPageShowing = true;
    _currentCallSessionId = session.sessionId;

    final context = OXNavigator.navigatorKey.currentContext;
    if (context == null) {
      _isCallPageShowing = false;
      _currentCallSessionId = null;
      return;
    }

    OXNavigator.pushPage(
      null,
      (context) => CallInProgressPage(session: session),
      type: OXPushPageType.present,
      pageName: 'CallInProgressPage',
    );
  }

  void _showOutgoingCallPage(CallSession session) {
    if (_isCallPageShowing) return;

    _isCallPageShowing = true;
    _currentCallSessionId = session.sessionId;

    final context = OXNavigator.navigatorKey.currentContext;
    if (context == null) {
      _isCallPageShowing = false;
      _currentCallSessionId = null;
      return;
    }

    OXNavigator.pushPage(
      null,
      (context) => CallInProgressPage(session: session),
      type: OXPushPageType.present,
      pageName: 'CallInProgressPage',
    );
  }

  void _onCallEnded(CallSession session) {
    if (_currentCallSessionId != session.sessionId) return;
    _isCallPageShowing = false;
    _currentCallSessionId = null;
    remoteStream$.value = null;
  }

  /// Dismiss the call page manually.
  void dismissCallPage() {
    if (!_isCallPageShowing) return;

    final context = OXNavigator.navigatorKey.currentContext;
    if (context != null) {
      // Pop to remove call page
      OXNavigator.popToPage(context, pageType: 'CallInProgressPage', isPrepage: true);
    }

    _isCallPageShowing = false;
    _currentCallSessionId = null;
    remoteStream$.value = null;
  }

  /// Check if call page is currently showing.
  bool get isCallPageShowing => _isCallPageShowing;

  /// Get current call session ID.
  String? get currentCallSessionId => _currentCallSessionId;
}