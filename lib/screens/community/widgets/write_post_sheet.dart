import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class WritePostSheet extends StatelessWidget {
  final String initialAuthor;
  final String initialTitle;
  final String initialContent;

  const WritePostSheet({
    super.key,
    required this.initialAuthor,
    this.initialTitle = '',
    this.initialContent = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authorCtrl = TextEditingController(text: initialAuthor);
    final titleCtrl = TextEditingController(text: initialTitle);
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
          Text(l10n.communityWritePost,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: authorCtrl,
            decoration: InputDecoration(
              hintText: l10n.communityNickname,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              hintText: l10n.communityTitle,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: contentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.communityContent,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final author = authorCtrl.text.trim();
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();
                if (author.isEmpty || title.isEmpty || content.isEmpty) return;
                Navigator.pop(context, (author: author, title: title, content: content));
              },
              child: Text(l10n.communityRegister),
            ),
          ),
        ],
      ),
    );
  }
}
