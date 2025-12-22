import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_session.dart';
import 'package:ox_call/src/models/call_target.dart';
import 'package:ox_call/src/pages/call_page.dart';

/// Demo page for testing call UI.
/// Provides buttons to preview call UI in different states without making real calls.
class CallDemoPage extends StatelessWidget {
  /// The target to call (includes pubkey and privateGroupId).
  final CallTarget target;

  const CallDemoPage({
    super.key,
    required this.target,
  });

  /// Create demo page from a user and their private group.
  factory CallDemoPage.fromUser(UserDBISAR user, String privateGroupId) {
    return CallDemoPage(
      target: CallTarget.fromUser(user, privateGroupId),
    );
  }

  /// Create a mock session for UI preview.
  CallSession _createMockSession({
    required CallType callType,
    required CallDirection direction,
    required CallState state,
  }) {
    final currentPubkey = Account.sharedInstance.currentPubkey;
    final localTarget = CallTarget(
      pubkey: currentPubkey,
      privateGroupId: target.privateGroupId,
    );

    final callerTarget = direction == CallDirection.outgoing ? localTarget : target;
    final calleeTarget = direction == CallDirection.outgoing ? target : localTarget;

    return CallSession(
      sessionId: 'mock-session-${DateTime.now().millisecondsSinceEpoch}',
      callerTarget: callerTarget,
      calleeTarget: calleeTarget,
      participants: [callerTarget, calleeTarget],
      callType: callType,
      direction: direction,
      state: state,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _openCallPage(BuildContext context, CallSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserDBISAR?>(
      valueListenable: target.user$,
      builder: (context, user, _) {
        final userName = user?.name ?? user?.shortEncodedPubkey ?? 'Unknown';

        return CLScaffold(
          appBar: CLAppBar(title: 'Call UI Demo'),
          body: ListView(
            padding: EdgeInsets.all(16.px),
            children: [
              // User info header
              Center(
                child: Column(
                  children: [
                    OXUserAvatar(user: user, size: 80.px),
                    SizedBox(height: 12.px),
                    CLText.titleMedium(userName),
                    SizedBox(height: 4.px),
                    CLText.bodySmall(
                      user?.shortEncodedPubkey ?? target.pubkey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.px),

              // Voice Call UI Previews
              _buildSectionTitle(context, 'Voice Call'),
              _buildPreviewButton(
                context,
                label: 'Outgoing - Ringing',
                icon: Icons.phone_forwarded,
                onTap: () => _openCallPage(
                  context,
                  _createMockSession(
                    callType: CallType.audio,
                    direction: CallDirection.outgoing,
                    state: CallState.ringing,
                  ),
                ),
              ),
              _buildPreviewButton(
                context,
                label: 'Incoming - Ringing',
                icon: Icons.phone_callback,
                onTap: () => _openCallPage(
                  context,
                  _createMockSession(
                    callType: CallType.audio,
                    direction: CallDirection.incoming,
                    state: CallState.ringing,
                  ),
                ),
              ),
              _buildPreviewButton(
                context,
                label: 'Connected',
                icon: Icons.phone_in_talk,
                onTap: () => _openCallPage(
                  context,
                  _createMockSession(
                    callType: CallType.audio,
                    direction: CallDirection.outgoing,
                    state: CallState.connected,
                  ),
                ),
              ),
              SizedBox(height: 24.px),

              // Video Call UI Previews
              _buildSectionTitle(context, 'Video Call'),
              _buildPreviewButton(
                context,
                label: 'Outgoing - Ringing',
                icon: Icons.videocam,
                onTap: () => _openCallPage(
                  context,
                  _createMockSession(
                    callType: CallType.video,
                    direction: CallDirection.outgoing,
                    state: CallState.ringing,
                  ),
                ),
              ),
              _buildPreviewButton(
                context,
                label: 'Incoming - Ringing',
                icon: Icons.video_call,
                onTap: () => _openCallPage(
                  context,
                  _createMockSession(
                    callType: CallType.video,
                    direction: CallDirection.incoming,
                    state: CallState.ringing,
                  ),
                ),
              ),
              _buildPreviewButton(
                context,
                label: 'Connected',
                icon: Icons.videocam,
                onTap: () => _openCallPage(
                  context,
                  _createMockSession(
                    callType: CallType.video,
                    direction: CallDirection.outgoing,
                    state: CallState.connected,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.px),
      child: CLText.titleSmall(title),
    );
  }

  Widget _buildPreviewButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.px),
      child: CLButton.elevated(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20.px),
            SizedBox(width: 12.px),
            Expanded(child: CLText.bodyMedium(label)),
            Icon(Icons.chevron_right, size: 20.px),
          ],
        ),
      ),
    );
  }
}
