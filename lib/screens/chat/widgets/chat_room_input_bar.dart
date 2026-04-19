import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/message_send_key_provider.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../chat_sending_phase.dart';

/// Bottom message-composer for the chat room screen.
///
/// Shows a "more" toggle, the text field, and a send button. The send
/// button morphs into a phase-coloured progress indicator while a send
/// is in flight, and the hint text is driven by [sendingPhase] /
/// [retryAttempt].
class ChatRoomInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final SendingPhase sendingPhase;
  final int retryAttempt;
  final bool isMorePanelOpen;
  final VoidCallback onSend;
  final VoidCallback onMoreToggle;

  const ChatRoomInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sendingPhase,
    required this.retryAttempt,
    required this.isMorePanelOpen,
    required this.onSend,
    required this.onMoreToggle,
  });

  bool get _isSending => sendingPhase != SendingPhase.none;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: AnimatedRotation(
                  turns: isMorePanelOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.add,
                    color: isMorePanelOpen ? theme.colorScheme.primary : null,
                  ),
                ),
                onPressed: onMoreToggle,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent ||
                        event.logicalKey != LogicalKeyboardKey.enter) {
                      return KeyEventResult.ignored;
                    }
                    if (kIsWeb || !Platform.isWindows) {
                      return KeyEventResult.ignored;
                    }
                    final keys = context.read<MessageSendKeyProvider>();
                    final shiftPressed =
                        HardwareKeyboard.instance.isShiftPressed;
                    final shouldSend = shiftPressed
                        ? keys.sendOnShiftEnter
                        : keys.sendOnEnter;
                    if (!shouldSend) return KeyEventResult.ignored;
                    if (!_isSending) onSend();
                    return KeyEventResult.handled;
                  },
                  child: CommonEditText(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_isSending,
                    hintText: _hintText(l10n),
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    suffixIcon: IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: sendingPhase == SendingPhase.preparing
                                    ? theme.colorScheme.primary
                                    : sendingPhase == SendingPhase.summarizing
                                        ? theme.colorScheme.secondary
                                        : null,
                              ),
                            )
                          : const Icon(Icons.send),
                      onPressed: _isSending ? null : onSend,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hintText(AppLocalizations l10n) {
    switch (sendingPhase) {
      case SendingPhase.preparing:
        return l10n.chatRoomGenerating;
      case SendingPhase.waiting:
        return retryAttempt > 0
            ? l10n.chatRoomRetrying(retryAttempt)
            : l10n.chatRoomWaiting;
      case SendingPhase.summarizing:
        return l10n.chatRoomSummarizing;
      case SendingPhase.none:
        return l10n.chatRoomMessageHint;
    }
  }
}
