import 'package:flutter/material.dart';
import 'package:ox_call/src/models/call_session.dart';
import 'package:ox_call/src/services/call_service.dart';
import 'widgets/call_page_controller.dart';
import 'widgets/call_top_bar.dart';
import 'widgets/call_content_area.dart';
import 'widgets/call_control_bar.dart';

/// Main call page that displays during an active call.
///
/// This page is a pure UI container that:
/// - Doesn't care whether it's a voice or video call
/// - Doesn't handle any business logic directly
/// - Delegates all state management to [CallPageController]
/// - Composes [CallTopBar], [CallContentArea], and [CallControlBar]
class CallPage extends StatefulWidget {
  final CallSession session;

  const CallPage({
    super.key,
    required this.session,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late final CallPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CallPageController(widget.session);
    _controller.hasPopped$.addListener(_onHasPopped);
  }

  void _onHasPopped() {
    if (_controller.hasPopped$.value && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _onMinimize() {
    // TODO: Implement minimize to PiP
  }

  @override
  void dispose() {
    _controller.hasPopped$.removeListener(_onHasPopped);
    _controller.dispose();
    // Notify CallService that call page is dismissed
    CallService.instance.notifyCallPageDismissed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isControlsVisible$,
        builder: (context, isControlsVisible, _) {
          return Stack(
            children: [
              // Content area (voice/video)
              Positioned.fill(
                child: CallContentArea(controller: _controller),
              ),

              // Top bar (with fade animation for video calls)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: isControlsVisible ? 0 : -100,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isControlsVisible ? 1.0 : 0.0,
                    child: CallTopBar(
                      controller: _controller,
                      onMinimize: _onMinimize,
                    ),
                  ),
                ),
              ),

              // Control bar (with fade animation for video calls)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                bottom: isControlsVisible ? 0 : -200,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isControlsVisible ? 1.0 : 0.0,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom > 0
                            ? 0
                            : 20,
                      ),
                      child: CallControlBar(controller: _controller),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}