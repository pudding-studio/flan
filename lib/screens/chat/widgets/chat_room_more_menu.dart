import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../community/community_screen.dart';
import '../../news/news_screen.dart';
import '../../diary/diary_screen.dart';
import 'chat_bottom_panel.dart';

/// Bottom-sheet style menu shown when the user taps the "+" button in the
/// chat room input bar.
///
/// Closes itself via [onClose] before performing each action so the host
/// can clear its open-state flag in one place.
class ChatRoomMoreMenu extends StatelessWidget {
  final int characterId;
  final int chatRoomId;
  final VoidCallback onClose;

  const ChatRoomMoreMenu({
    super.key,
    required this.characterId,
    required this.chatRoomId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 12),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _MenuAppIcon(
                icon: Icons.forum_outlined,
                label: 'SNS',
                onTap: () {
                  onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityScreen(
                        characterId: characterId,
                        chatRoomId: chatRoomId,
                      ),
                    ),
                  );
                },
              ),
              _MenuAppIcon(
                icon: Icons.newspaper_outlined,
                label: 'News',
                onTap: () {
                  onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsScreen(
                        characterId: characterId,
                        chatRoomId: chatRoomId,
                      ),
                    ),
                  );
                },
              ),
              _MenuAppIcon(
                icon: Icons.auto_stories_outlined,
                label: 'Diary',
                onTap: () {
                  onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaryScreen(
                        characterId: characterId,
                        chatRoomId: chatRoomId,
                      ),
                    ),
                  );
                },
              ),
              _MenuAppIcon(
                icon: Icons.text_fields,
                label: l10n.chatRoomTextSettings,
                onTap: () {
                  onClose();
                  showModalBottomSheet<void>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => const ChatBottomPanel(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuAppIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuAppIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 21,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
