import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/diary/diary_entry.dart';
import '../../widgets/common/edit_text_entry_sheet.dart';

/// Lets the user fix the title and text of [entry]; returns the saved
/// entry, or null when the edit was cancelled.
Future<DiaryEntry?> editDiaryEntry(BuildContext context, DiaryEntry entry) async {
  final edited = await EditTextEntrySheet.show(
    context,
    heading: AppLocalizations.of(context).diaryEdit,
    title: entry.title,
    content: entry.content,
  );
  if (edited == null) return null;
  await DatabaseHelper.instance.updateDiaryEntryText(
    entry.id!,
    title: edited.title!,
    content: edited.content,
  );
  return entry.copyWith(title: edited.title, content: edited.content);
}

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late DiaryEntry entry = widget.entry;

  Future<void> _edit() async {
    final edited = await editDiaryEntry(context, entry);
    if (edited != null && mounted) setState(() => entry = edited);
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSecondary = Theme.of(context).colorScheme.onSecondary;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        iconTheme: IconThemeData(color: onSecondary),
        title: Text(AppLocalizations.of(context).diaryTitle(entry.author), style: TextStyle(color: onSecondary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(context).commonEdit,
            onPressed: _edit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.author,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              entry.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              entry.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
