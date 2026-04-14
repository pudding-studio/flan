import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class WriteCommentSheet extends StatelessWidget {
  final String postTitle;
  final String initialAuthor;
  final String initialContent;

  const WriteCommentSheet({
    super.key,
    required this.postTitle,
    required this.initialAuthor,
    this.initialContent = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nicknameCtrl = TextEditingController(text: initialAuthor);
    final contentCtrl = TextEditingController(text: initialContent);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.communityWriteComment,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            postTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nicknameCtrl,
            decoration: InputDecoration(
              hintText: l10n.communityNickname,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: contentCtrl,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.communityCommentContent,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final nickname = nicknameCtrl.text.trim();
                final content = contentCtrl.text.trim();
                if (nickname.isEmpty || content.isEmpty) return;
                Navigator.pop(context, (author: nickname, content: content));
              },
              child: Text(l10n.communityRegister),
            ),
          ),
        ],
      ),
    );
  }
}
