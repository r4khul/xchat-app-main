import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_call/src/models/call_state.dart';
import 'package:ox_call/src/models/call_session.dart';
import 'package:ox_call/src/pages/call_in_progress_page.dart';

/// Demo page for testing call UI.
/// Provides buttons to preview call UI in different states without making real calls.
class CallDemoPage extends StatelessWidget {
  final UserDBISAR user;

  const CallDemoPage({
    super.key,
    required this.user,
  });

  /// Create a mock session for UI preview.
  CallSession _createMockSession({
    required CallType callType,
    required CallDirection direction,
    required CallState state,
  }) {
    return CallSession(
      sessionId: 'mock-session-${DateTime.now().millisecondsSinceEpoch}',
      offerId: 'mock-offer-id',
      callerPubkey: direction == CallDirection.outgoing
          ? Account.sharedInstance.currentPubkey
          : user.pubKey,
      calleePubkey: direction == CallDirection.outgoing
          ? user.pubKey
          : Account.sharedInstance.currentPubkey,
      participants: [Account.sharedInstance.currentPubkey, user.pubKey],
      callType: callType,
      direction: direction,
      state: state,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _openCallPage(BuildContext context, CallSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallInProgressPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = user.name ?? user.shortEncodedPubkey;

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
                  user.shortEncodedPubkey,
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