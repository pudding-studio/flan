import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/custom_model.dart';
import '../../widgets/common/common_appbar.dart';

enum _Period {
  week(7),
  month(30),
  all(null);

  final int? days;
  const _Period(this.days);
}

class _ModelStats {
  final String modelId;
  final String displayName;
  final int messageCount;
  final int promptTokens;
  final int outputTokens;
  final int cachedTokens;
  final int thinkingTokens;
  final double cost;

  const _ModelStats({
    required this.modelId,
    required this.displayName,
    required this.messageCount,
    required this.promptTokens,
    required this.outputTokens,
    required this.cachedTokens,
    required this.thinkingTokens,
    required this.cost,
  });

  int get totalTokens => promptTokens + outputTokens;
}

class _DailyStats {
  final String date;
  final List<_ModelStats> modelStats;

  const _DailyStats({required this.date, required this.modelStats});

  double get totalCost => modelStats.fold(0, (s, m) => s + m.cost);
  int get totalMessages => modelStats.fold(0, (s, m) => s + m.messageCount);
  int get totalTokens => modelStats.fold(0, (s, m) => s + m.totalTokens);
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _db = DatabaseHelper.instance;
  _Period _period = _Period.week;
  List<_DailyStats> _dailyStats = [];
  bool _isLoading = true;
  List<CustomModel> _customModels = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _customModels = await CustomModelRepository.loadAll();
      final from = _period.days != null
          ? DateTime.now().subtract(Duration(days: _period.days!))
          : null;
      final rows = await _db.getMessageStatsByDateAndModel(from: from);
      _dailyStats = _buildDailyStats(rows);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_DailyStats> _buildDailyStats(List<Map<String, dynamic>> rows) {
    final Map<String, List<_ModelStats>> byDate = {};

    for (final row in rows) {
      final date = row['date'] as String;
      final modelId = row['model_id'] as String;
      final messageCount = (row['message_count'] as int?) ?? 0;
      final promptTokens = (row['prompt_tokens'] as int?) ?? 0;
      final outputTokens = (row['output_tokens'] as int?) ?? 0;
      final cachedTokens = (row['cached_tokens'] as int?) ?? 0;
      final thinkingTokens = (row['thinking_tokens'] as int?) ?? 0;

      final pricing = _getPricing(modelId);
      final cost = pricing.calculateCost(
        promptTokens: promptTokens,
        cachedTokens: cachedTokens,
        outputTokens: outputTokens,
        thinkingTokens: thinkingTokens,
      );

      final modelStats = _ModelStats(
        modelId: modelId,
        displayName: _getDisplayName(modelId),
        messageCount: messageCount,
        promptTokens: promptTokens,
        outputTokens: outputTokens,
        cachedTokens: cachedTokens,
        thinkingTokens: thinkingTokens,
        cost: cost,
      );

      byDate.putIfAbsent(date, () => []).add(modelStats);
    }

    return byDate.entries
        .map((e) => _DailyStats(date: e.key, modelStats: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  ModelPricing _getPricing(String modelId) {
    final builtIn = ChatModel.fromModelId(modelId);
    if (builtIn != null) return builtIn.pricing;

    final custom = _customModels.where((m) => m.modelId == modelId).firstOrNull;
    return custom?.pricing ?? const ModelPricing.zero();
  }

  String _getDisplayName(String modelId) {
    final builtIn = ChatModel.fromModelId(modelId);
    if (builtIn != null) return builtIn.displayName;

    final custom = _customModels.where((m) => m.modelId == modelId).firstOrNull;
    return custom?.displayName ?? modelId;
  }

  double get _grandTotalCost =>
      _dailyStats.fold(0, (s, d) => s + d.totalCost);
  int get _grandTotalMessages =>
      _dailyStats.fold(0, (s, d) => s + d.totalMessages);
  int get _grandTotalTokens =>
      _dailyStats.fold(0, (s, d) => s + d.totalTokens);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(title: l10n.statisticsTitle),
      body: Column(
        children: [
          _buildPeriodSelector(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_dailyStats.isEmpty)
            Expanded(child: Center(child: Text(l10n.statisticsNoData)))
          else ...[
            _buildSummaryCards(),
            const Divider(height: 1),
            Expanded(child: _buildDailyList()),
          ],
        ],
      ),
    );
  }

  String _periodLabel(_Period p, AppLocalizations l10n) {
    switch (p) {
      case _Period.week: return l10n.statisticsPeriod7Days;
      case _Period.month: return l10n.statisticsPeriod30Days;
      case _Period.all: return l10n.statisticsPeriodAll;
    }
  }

  Widget _buildPeriodSelector() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SegmentedButton<_Period>(
        segments: _Period.values
            .map((p) => ButtonSegment(value: p, label: Text(_periodLabel(p, l10n))))
            .toList(),
        selected: {_period},
        onSelectionChanged: (selected) {
          setState(() => _period = selected.first);
          _load();
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: l10n.statisticsCost,
              value: _formatCost(_grandTotalCost),
              icon: Icons.attach_money,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: l10n.statisticsTokens,
              value: _formatTokens(_grandTotalTokens),
              icon: Icons.token,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: l10n.statisticsMessages,
              value: '$_grandTotalMessages',
              icon: Icons.chat_bubble_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: _dailyStats.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _DailyStatsCard(stats: _dailyStats[index]),
    );
  }

  static String _formatCost(double cost) {
    if (cost == 0) return '\$0';
    if (cost < 0.0001) return '<\$0.0001';
    if (cost < 0.01) return '\$${cost.toStringAsFixed(4)}';
    if (cost < 1) return '\$${cost.toStringAsFixed(3)}';
    return '\$${cost.toStringAsFixed(2)}';
  }

  static String _formatTokens(int tokens) {
    if (tokens < 1000) return '$tokens';
    if (tokens < 1000000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return '${(tokens / 1000000).toStringAsFixed(2)}M';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _DailyStatsCard extends StatefulWidget {
  final _DailyStats stats;

  const _DailyStatsCard({required this.stats});

  @override
  State<_DailyStatsCard> createState() => _DailyStatsCardState();
}

class _DailyStatsCardState extends State<_DailyStatsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final stats = widget.stats;
    final dateLabel = _formatDate(stats.date, l10n);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.statisticsDailyModels(stats.modelStats.length)} · '
                        '${l10n.statisticsDailyTokens(_formatTokens(stats.totalTokens))} · '
                        '${l10n.statisticsDailyMessages(stats.totalMessages)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCost(stats.totalCost),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...stats.modelStats.map(
            (m) => _ModelStatsRow(model: m),
          ),
      ],
    );
  }

  static String _formatDate(String yyyyMmDd, AppLocalizations l10n) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return yyyyMmDd;
    return l10n.statisticsDateFormat(parts[0], parts[1], parts[2]);
  }

  static String _formatCost(double cost) {
    if (cost == 0) return '\$0';
    if (cost < 0.0001) return '<\$0.0001';
    if (cost < 0.01) return '\$${cost.toStringAsFixed(4)}';
    if (cost < 1) return '\$${cost.toStringAsFixed(3)}';
    return '\$${cost.toStringAsFixed(2)}';
  }

  static String _formatTokens(int tokens) {
    if (tokens < 1000) return '$tokens';
    if (tokens < 1000000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return '${(tokens / 1000000).toStringAsFixed(2)}M';
  }
}

class _ModelStatsRow extends StatelessWidget {
  final _ModelStats model;

  const _ModelStatsRow({required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(28, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _buildTokenDetail(colorScheme, l10n),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCost(model.cost),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.statisticsModelMessages(model.messageCount),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDetail(ColorScheme colorScheme, AppLocalizations l10n) {
    final parts = <String>[];
    parts.add('${l10n.statisticsTokenInput} ${_formatTokens(model.promptTokens)}');
    parts.add('${l10n.statisticsTokenOutput} ${_formatTokens(model.outputTokens)}');
    if (model.cachedTokens > 0) {
      parts.add('${l10n.statisticsTokenCached} ${_formatTokens(model.cachedTokens)}');
    }
    if (model.thinkingTokens > 0) {
      parts.add('${l10n.statisticsTokenThinking} ${_formatTokens(model.thinkingTokens)}');
    }

    return Text(
      parts.join(' · '),
      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
    );
  }

  static String _formatCost(double cost) {
    if (cost == 0) return '\$0';
    if (cost < 0.0001) return '<\$0.0001';
    if (cost < 0.01) return '\$${cost.toStringAsFixed(4)}';
    if (cost < 1) return '\$${cost.toStringAsFixed(3)}';
    return '\$${cost.toStringAsFixed(2)}';
  }

  static String _formatTokens(int tokens) {
    if (tokens < 1000) return '$tokens';
    if (tokens < 1000000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return '${(tokens / 1000000).toStringAsFixed(2)}M';
  }
}
