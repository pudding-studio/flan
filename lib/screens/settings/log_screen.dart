import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../models/chat/chat_log.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_info_box.dart';

String _formatTimestamp(DateTime timestamp) {
  return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<ChatLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final logs = await _db.readAllChatLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.logLoadFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _deleteLog(int id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.logDeleteTitle,
      content: l10n.logDeleteContent,
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      await _db.deleteChatLog(id);
      await _loadLogs();
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.logDeleteSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.logDeleteFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _deleteAllLogs() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.logDeleteAllTitle,
      content: l10n.logDeleteAllContent,
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      await _db.deleteAllChatLogs();
      await _loadLogs();
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.logDeleteAllSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.logDeleteFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _showLogDetail(ChatLog log) async {
    if (log.id == null) return;
    final fullLog = await _db.readChatLog(log.id!);
    if (fullLog == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogDetailSheet(log: fullLog),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.logTitle,
        actions: [
          if (_logs.isNotEmpty)
            CommonAppBarIconButton(
              icon: Icons.delete_sweep,
              onPressed: _deleteAllLogs,
              tooltip: l10n.logDeleteAllTooltip,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: CommonInfoBox(
                    message: l10n.logInfoMessage,
                  ),
                ),
                Expanded(
                  child: _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.logEmpty,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _logs.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final isAutoSummary = log.type == 'auto_summary';
                            return ListTile(
                              leading: isAutoSummary
                                  ? Icon(
                                      Icons.summarize,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      size: 20,
                                    )
                                  : null,
                              title: Text(
                                _formatTimestamp(log.timestamp),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: isAutoSummary
                                          ? Theme.of(context).colorScheme.tertiary
                                          : null,
                                    ),
                              ),
                              subtitle: Text(
                                isAutoSummary ? l10n.logAutoSummaryLabel : 'Type: ${log.type}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isAutoSummary
                                          ? Theme.of(context).colorScheme.tertiary
                                          : null,
                                    ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteLog(log.id!),
                              ),
                              onTap: () => _showLogDetail(log),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _LogDetailSheet extends StatefulWidget {
  final ChatLog log;

  const _LogDetailSheet({required this.log});

  @override
  State<_LogDetailSheet> createState() => _LogDetailSheetState();
}

class _LogDetailSheetState extends State<_LogDetailSheet> {
  bool _showFormattedRequest = true;
  bool _showFormattedResponse = true;

  String _formatJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return jsonString;
    }
  }

  String _getModelName() {
    return widget.log.modelName ?? widget.log.type;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    CommonDialog.showSnackBar(
      context: context,
      message: AppLocalizations.of(context).logDetailCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).logDetailTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoCard(context),
                    const SizedBox(height: 16),
                    _buildRequestCard(context),
                    const SizedBox(height: 16),
                    _buildResponseCard(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.logDetailInfoSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(l10n.logDetailTime, _formatTimestamp(widget.log.timestamp)),
            _buildInfoRow(l10n.logDetailType, widget.log.type),
            _buildInfoRow(l10n.logDetailModel, _getModelName()),
            if (widget.log.chatRoomId != null)
              _buildInfoRow(l10n.logDetailChatRoomId, widget.log.chatRoomId.toString()),
            if (widget.log.characterId != null)
              _buildInfoRow(l10n.logDetailCharacterId, widget.log.characterId.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(widget.log.request),
                  tooltip: AppLocalizations.of(context).commonCopy,
                ),
                Switch(
                  value: _showFormattedRequest,
                  onChanged: (value) {
                    setState(() => _showFormattedRequest = value);
                  },
                ),
                Text(AppLocalizations.of(context).logDetailFormatLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _showFormattedRequest
                    ? _formatJson(widget.log.request)
                    : widget.log.request,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Response',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(widget.log.response),
                  tooltip: AppLocalizations.of(context).commonCopy,
                ),
                Switch(
                  value: _showFormattedResponse,
                  onChanged: (value) {
                    setState(() => _showFormattedResponse = value);
                  },
                ),
                Text(AppLocalizations.of(context).logDetailFormatLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _showFormattedResponse && !widget.log.response.startsWith('Error:')
                    ? _formatJson(widget.log.response)
                    : widget.log.response,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
