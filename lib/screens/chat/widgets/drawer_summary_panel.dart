import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../database/database_helper.dart';
import '../../../models/chat/chat_summary.dart';
import '../../../services/auto_summary_service.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';

class DrawerSummaryPanel extends StatefulWidget {
  final List<ChatSummary> summaries;
  final int chatRoomId;
  final DatabaseHelper db;
  final VoidCallback onDataChanged;

  const DrawerSummaryPanel({
    super.key,
    required this.summaries,
    required this.chatRoomId,
    required this.db,
    required this.onDataChanged,
  });

  @override
  DrawerSummaryPanelState createState() => DrawerSummaryPanelState();
}

class DrawerSummaryPanelState extends State<DrawerSummaryPanel> {
  final Map<int, TextEditingController> _summaryControllers = {};
  final Set<int> _expandedSummaryIds = {};
  final Set<int> _regeneratingSummaryIds = {};
  bool _isAddingSummary = false;
  final AutoSummaryService _autoSummaryService = AutoSummaryService();

  @override
  void initState() {
    super.initState();
    for (final summary in widget.summaries) {
      if (summary.id != null) {
        _summaryControllers[summary.id!] =
            TextEditingController(text: summary.summaryContent);
      }
    }
  }

  @override
  void didUpdateWidget(DrawerSummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final summary in widget.summaries) {
      if (summary.id != null && !_summaryControllers.containsKey(summary.id)) {
        _summaryControllers[summary.id!] =
            TextEditingController(text: summary.summaryContent);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _summaryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Save all modified summary controllers back to the database.
  Future<void> saveAll() async {
    for (final summary in widget.summaries) {
      final controller = _summaryControllers[summary.id];
      if (controller != null && controller.text != summary.summaryContent) {
        final updated = summary.copyWith(
          summaryContent: controller.text,
          updatedAt: DateTime.now(),
        );
        await widget.db.updateChatSummary(updated);
      }
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionHeaderStyle =
        Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.drawerAutoSummaryList,
                    style: sectionHeaderStyle,
                  ),
                  Text(
                    l10n.drawerSummaryCount(widget.summaries.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.summaries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.drawerNoSummaries,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                ...List.generate(widget.summaries.length, (index) {
                  final summary = widget.summaries[index];
                  final controller = _summaryControllers[summary.id]!;
                  final isExpanded = _expandedSummaryIds.contains(summary.id);

                  return CommonEditableExpandableItem(
                    key: ValueKey('summary_${summary.id}'),
                    icon: Icon(
                      Icons.summarize_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    name: 'Summary #${index + 1}',
                    isExpanded: isExpanded,
                    showNameField: false,
                    onToggleExpanded: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedSummaryIds.remove(summary.id!);
                        } else {
                          _expandedSummaryIds.add(summary.id!);
                        }
                      });
                    },
                    onDelete: () => _deleteSummary(summary.id!),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonEditText(
                          controller: controller,
                          hintText: l10n.drawerSummaryContentHint,
                          maxLines: null,
                          minLines: 4,
                          size: CommonEditTextSize.small,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _regeneratingSummaryIds
                                      .contains(summary.id)
                                  ? null
                                  : () => _regenerateSummary(summary),
                              icon: _regeneratingSummaryIds
                                      .contains(summary.id)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 16),
                              label: Text(
                                _regeneratingSummaryIds.contains(summary.id)
                                    ? l10n.drawerGenerating
                                    : l10n.drawerRegenerate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        _buildAddSummaryButton(),
      ],
    );
  }

  // ==================== Add Summary Button ====================

  Widget _buildAddSummaryButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: _isAddingSummary
            ? const Center(child: CircularProgressIndicator())
            : CommonButton.filled(
                onPressed: _addManualSummary,
                icon: Icons.add,
                label: AppLocalizations.of(context).drawerAddSummaryButton,
                size: CommonButtonSize.small,
              ),
      ),
    );
  }

  // ==================== Logic ====================

  Future<void> _addManualSummary() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isAddingSummary = true);

    try {
      final allMessages =
          await widget.db.readChatMessagesByChatRoom(widget.chatRoomId);
      if (allMessages.isEmpty) {
        if (!mounted) return;
        CommonDialog.showSnackBar(
            context: context, message: l10n.drawerNoMessages);
        return;
      }

      // Determine start: after the last existing summary's end, or 0
      final existingSummaries =
          await widget.db.getChatSummaries(widget.chatRoomId);
      final startPinMessageId = existingSummaries.isNotEmpty
          ? existingSummaries.last.endPinMessageId
          : 0;

      final endPinMessageId = allMessages.last.id!;

      if (startPinMessageId == endPinMessageId) {
        if (!mounted) return;
        CommonDialog.showSnackBar(
            context: context, message: l10n.drawerNoNewMessages);
        return;
      }

      final summary = ChatSummary(
        chatRoomId: widget.chatRoomId,
        startPinMessageId: startPinMessageId,
        endPinMessageId: endPinMessageId,
        summaryContent: '',
      );
      final newId = await widget.db.createChatSummary(summary);

      _summaryControllers[newId] = TextEditingController(text: '');
      _expandedSummaryIds.add(newId);

      widget.onDataChanged();

      if (!mounted) return;
      CommonDialog.showSnackBar(
          context: context, message: l10n.drawerSummaryAdded);
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.drawerSummaryAddFailed(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingSummary = false);
      }
    }
  }

  Future<void> _regenerateSummary(ChatSummary summary) async {
    final l10n = AppLocalizations.of(context);
    final summaryId = summary.id!;
    setState(() => _regeneratingSummaryIds.add(summaryId));

    try {
      final updated =
          await _autoSummaryService.regenerateSummary(summary: summary);

      _summaryControllers[summaryId]?.text = updated.summaryContent;

      widget.onDataChanged();

      if (!mounted) return;
      CommonDialog.showSnackBar(
          context: context, message: l10n.drawerSummaryRegenerated);
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.drawerSummaryRegenerateFailed(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _regeneratingSummaryIds.remove(summaryId));
      }
    }
  }

  Future<void> _deleteSummary(int summaryId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: l10n.drawerSummaryItemName,
    );

    if (!confirmed) return;

    try {
      await widget.db.deleteChatSummary(summaryId);

      _summaryControllers[summaryId]?.dispose();
      _summaryControllers.remove(summaryId);

      widget.onDataChanged();

      if (!mounted) return;
      CommonDialog.showSnackBar(
          context: context, message: l10n.drawerSummaryDeleted);
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.drawerSummaryDeleteFailed(e.toString()),
      );
    }
  }
}
