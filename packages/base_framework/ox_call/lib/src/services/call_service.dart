import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_call/src/call_manager.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_session.dart';
import 'package:ox_call/src/pages/call_page.dart';

class CallService {
  CallService._();

  static final CallService _instance = CallService._();
  static CallService get instance => _instance;

  bool _initialized = false;
  bool _isCallPageShowing = false;
  String? _currentSessionId;
  void Function()? _removeStateListener;

  /// Initialize the call service.
  /// Should be called after CallManager is initialized.
  void initialize() {
    if (_initialized) return;
    _removeStateListener = CallManager().addStateListener(_onCallStateChanged);
    _initialized = true;
  }

  /// Cleanup the call service.
  void cleanup() {
    _removeStateListener?.call();
    _removeStateListener = null;
    _isCallPageShowing = false;
    _currentSessionId = null;
    _initialized = false;
  }

  void _onCallStateChanged(CallSession session) {
    // Handle incoming call - show call page
    if (session.state == CallState.ringing &&
        session.direction == CallDirection.incoming) {
      _showCallPage(session);
      return;
    }

    // Handle outgoing call - show call page if not showing
    if ((session.state == CallState.ringing ||
            session.state == CallState.connecting ||
            session.state == CallState.initiating) &&
        session.direction == CallDirection.outgoing &&
        !_isCallPageShowing) {
      _showCallPage(session);
      return;
    }

    // Handle call ended - update tracking state
    if (session.state == CallState.ended &&
        _currentSessionId == session.sessionId) {
      _isCallPageShowing = false;
      _currentSessionId = null;
    }
  }

  void _showCallPage(CallSession session) {
    if (_isCallPageShowing) return;

    final context = OXNavigator.navigatorKey.currentContext;
    if (context == null) return;

    _isCallPageShowing = true;
    _currentSessionId = session.sessionId;

    OXNavigator.pushPage(
      null,
      (context) => CallPage(session: session),
      type: OXPushPageType.present,
    );
  }

  /// Notify that call page has been dismissed.
  /// Called by CallPage when it's popped.
  void notifyCallPageDismissed() {
    _isCallPageShowing = false;
    _currentSessionId = null;
  }

  /// Check if call page is currently showing.
  bool get isCallPageShowing => _isCallPageShowing;

  /// Get current call session ID.
  String? get currentSessionId => _currentSessionId;
}