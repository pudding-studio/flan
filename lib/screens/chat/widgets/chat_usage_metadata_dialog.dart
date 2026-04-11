import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat/chat_message.dart';
import '../../../models/chat/chat_model.dart';
import '../../../utils/common_dialog.dart';

/// Token usage / cost breakdown dialog for an AI message.
///
/// Falls back to a snackbar when the message has no usage metadata.
class ChatUsageMetadataDialog {
  static Future<void> show(BuildContext context, ChatMessage message) async {
    final l10n = AppLocalizations.of(context);
    final metadata = message.usageMetadata;
    if (metadata == null) {
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.chatRoomNoStats,
      );
      return;
    }

    final model = message.modelId != null ? ChatModel.fromModelId(message.modelId!) : null;

    double? cost;
    if (model != null) {
      cost = model.pricing.calculateCost(
        promptTokens: metadata.promptTokenCount,
        cachedTokens: metadata.cachedContentTokenCount ?? 0,
        outputTokens: metadata.candidatesTokenCount,
        thinkingTokens: metadata.thoughtsTokenCount ?? 0,
      );
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatRoomStatsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model != null)
              _statRow(context, l10n.chatRoomStatModel, model.displayName),
            if (model != null) const Divider(),
            _statRow(context, l10n.chatRoomStatInputTokens, '${metadata.promptTokenCount}'),
            if (metadata.cachedContentTokenCount != null) ...[
              _statRow(context, l10n.chatRoomStatCachedTokens, '${metadata.cachedContentTokenCount}'),
              _statRow(context, l10n.chatRoomStatCacheRatio, '${(metadata.cacheRatio * 100).toStringAsFixed(1)}%'),
            ],
            const Divider(),
            _statRow(context, l10n.chatRoomStatOutputTokens, '${metadata.candidatesTokenCount}'),
            if (metadata.thoughtsTokenCount != null) ...[
              _statRow(context, l10n.chatRoomStatThoughtTokens, '${metadata.thoughtsTokenCount}'),
              _statRow(context, l10n.chatRoomStatThoughtRatio, '${(metadata.thoughtsRatio * 100).toStringAsFixed(1)}%'),
            ],
            const Divider(),
            _statRow(context, l10n.chatRoomStatTotalTokens, '${metadata.totalTokenCount}'),
            if (cost != null) ...[
              const Divider(),
              _statRow(context, l10n.chatRoomStatEstimatedCost, '\$${cost.toStringAsFixed(6)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  static Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
