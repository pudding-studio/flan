import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The edited text of an entry; fields the sheet did not show stay null.
typedef EditedTextEntry = ({String? author, String? title, String content});

/// Bottom sheet for fixing the text of a post, comment, diary entry or news
/// article. Only the fields given an initial value are shown; a cleared
/// author or title keeps the previous one, and the content may not be empty.
class EditTextEntrySheet extends StatefulWidget {
  final String heading;
  final String? author;
  final String? title;
  final String content;

  const EditTextEntrySheet({
    super.key,
    required this.heading,
    this.author,
    this.title,
    required this.content,
  });

  static Future<EditedTextEntry?> show(
    BuildContext context, {
    required String heading,
    String? author,
    String? title,
    required String content,
  }) {
    return showModalBottomSheet<EditedTextEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditTextEntrySheet(
        heading: heading,
        author: author,
        title: title,
        content: content,
      ),
    );
  }

  @override
  State<EditTextEntrySheet> createState() => _EditTextEntrySheetState();
}

class _EditTextEntrySheetState extends State<EditTextEntrySheet> {
  late final _authorController = TextEditingController(text: widget.author);
  late final _titleController = TextEditingController(text: widget.title);
  late final _contentController = TextEditingController(text: widget.content);

  @override
  void dispose() {
    _authorController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String? _keepIfEmpty(String? original, TextEditingController controller) {
    if (original == null) return null;
    final text = controller.text.trim();
    return text.isEmpty ? original : text;
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    Navigator.pop<EditedTextEntry>(context, (
      author: _keepIfEmpty(widget.author, _authorController),
      title: _keepIfEmpty(widget.title, _titleController),
      content: content,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    InputDecoration decoration(String hint) => InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.heading,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.author != null) ...[
              TextField(
                controller: _authorController,
                decoration: decoration(l10n.communityNickname),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.title != null) ...[
              TextField(
                controller: _titleController,
                decoration: decoration(l10n.communityTitle),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _contentController,
              minLines: 3,
              maxLines: 12,
              decoration: decoration(l10n.communityContent),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
