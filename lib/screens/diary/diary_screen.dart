import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/start_scenario.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_message_metadata.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/model_preset.dart';
import '../../models/chat/unified_model.dart';
import '../../models/diary/diary_entry.dart';
import '../../providers/chat_model_provider.dart';
import '../../providers/diary_model_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/diary_parser.dart';
import '../../utils/metadata_parser.dart';
import '../../widgets/common/common_dropdown_button.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  final int characterId;
  final int chatRoomId;

  const DiaryScreen({
    super.key,
    required this.characterId,
    required this.chatRoomId,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Character? _character;
  ChatRoom? _chatRoom;
  StartScenario? _selectedScenario;
  bool _isLoading = true;
  bool _isGenerating = false;

  // Calendar state
  late DateTime _currentMonth;
  String? _currentChatDate; // latest date tag from chat metadata

  // Metadata-derived data
  Map<String, List<String>> _dateCharacters = {}; // date -> character names
  Set<String> _diaryDates = {}; // dates that have diary entries
  List<DiaryEntry> _selectedDayEntries = [];
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _db.readCharacter(widget.characterId),
      _db.readChatRoom(widget.chatRoomId),
      _db.readChatMessageMetadataByChatRoom(widget.chatRoomId),
      _db.readDiaryDates(widget.chatRoomId),
    ]);
    if (!mounted) return;

    final chatRoom = results[1] as ChatRoom?;
    StartScenario? scenario;
    if (chatRoom?.selectedStartScenarioId != null) {
      scenario = await _db.readStartScenario(chatRoom!.selectedStartScenarioId!);
    }
    if (!mounted) return;

    final metadataList = results[2] as List<ChatMessageMetadata>;
    final diaryDateList = results[3] as List<String>;

    // Build date -> characters map from messages
    final dateChars = <String, Set<String>>{};
    final allMessages = await _db.readChatMessagesByChatRoom(widget.chatRoomId);
    if (!mounted) return;

    String? trackingDate;
    for (final msg in allMessages) {
      final parsed = MetadataParser.parse(msg.content);
      if (parsed.date != null) {
        // Use metadata date tag if present
        trackingDate = parsed.date;
      } else if (trackingDate == null) {
        // No date tag seen yet — fallback to message's created_at
        final dt = msg.createdAt;
        trackingDate = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
      }
      if (trackingDate != null) {
        final charTags = MetadataParser.parseCharacterTags(msg.content);
        if (charTags.isNotEmpty) {
          dateChars.putIfAbsent(trackingDate, () => {});
          for (final tag in charTags) {
            dateChars[trackingDate]!.add(tag.name);
          }
        }
      }
    }

    // Determine latest date: prefer metadata, fallback to last message created_at
    String? latestDate;
    for (final meta in metadataList) {
      if (meta.date != null && meta.date!.isNotEmpty) {
        latestDate = meta.date;
      }
    }
    if (latestDate == null && allMessages.isNotEmpty) {
      final dt = allMessages.last.createdAt;
      latestDate = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    }

    // Set calendar to the month of the current chat date
    DateTime initialMonth = DateTime.now();
    if (latestDate != null) {
      final parts = latestDate.split('.');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          initialMonth = DateTime(y, m);
        }
      }
    }

    setState(() {
      _character = results[0] as Character?;
      _chatRoom = chatRoom;
      _selectedScenario = scenario;
      _currentChatDate = latestDate;
      _currentMonth = initialMonth;
      _dateCharacters = dateChars.map((k, v) => MapEntry(k, v.toList()));
      _diaryDates = diaryDateList.toSet();
      _isLoading = false;
    });
  }

  Future<UnifiedModel> _getModel() async {
    final diaryProvider = context.read<DiaryModelProvider>();
    final chatProvider = context.read<ChatModelSettingsProvider>();
    await diaryProvider.initialized;
    await chatProvider.initialized;
    switch (diaryProvider.modelPreset) {
      case ModelPreset.primary:
        return chatProvider.selectedModel;
      case ModelPreset.secondary:
        return chatProvider.subModel;
      case ModelPreset.custom:
        return diaryProvider.selectedModel;
    }
  }

  String _buildWorldviewText() {
    final parts = <String>[];
    if (_character?.description?.isNotEmpty == true) {
      parts.add('## Worldview Description\n${_character!.description}');
    }
    if (_selectedScenario?.startSetting?.isNotEmpty == true) {
      parts.add('## Scenario: ${_selectedScenario!.name}\n${_selectedScenario!.startSetting}');
    }
    if (_chatRoom?.summary.isNotEmpty == true) {
      parts.add('## Chat Summary\n${_chatRoom!.summary}');
    }
    return parts.join('\n\n');
  }

  Future<void> _generateDiary(String date) async {
    setState(() => _isGenerating = true);
    try {
      // Get chat messages for the target date
      final allMessages = await _db.readChatMessagesByChatRoom(widget.chatRoomId);
      final summaries = await _db.getChatSummaries(widget.chatRoomId);

      // Filter messages that belong to the target date
      final dateMessages = <ChatMessage>[];
      String? trackingDate;
      for (final msg in allMessages) {
        final parsed = MetadataParser.parse(msg.content);
        if (parsed.date != null) {
          trackingDate = parsed.date;
        } else if (trackingDate == null) {
          final dt = msg.createdAt;
          trackingDate = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
        }
        if (trackingDate == date) {
          dateMessages.add(msg);
        }
      }

      // Limit messages to avoid token overflow (keep latest ~30)
      final limitedMessages = dateMessages.length > 30
          ? dateMessages.sublist(dateMessages.length - 30)
          : dateMessages;

      // Build context
      final worldview = _buildWorldviewText();
      final messageText = limitedMessages.map((m) {
        final role = m.role == MessageRole.user ? '{{user}}' : _character?.name ?? 'Assistant';
        final clean = MetadataParser.removeMetadataTags(m.content);
        return '$role: $clean';
      }).join('\n');

      // Include relevant summaries (up to 3 most recent)
      final relevantSummaries = summaries.length > 3
          ? summaries.sublist(summaries.length - 3)
          : summaries;
      final summaryText = relevantSummaries.map((s) => s.summaryContent).join('\n\n');

      final model = await _getModel();
      final systemPrompt = await rootBundle.loadString(
        'assets/defaults/diary_prompts/diary_generate.txt',
      );

      final userMessage = 'Target date: $date\n\n'
          '${worldview.isNotEmpty ? '$worldview\n\n' : ''}'
          '${summaryText.isNotEmpty ? '## Episode Summaries\n$summaryText\n\n' : ''}'
          '## Chat Messages on $date\n$messageText';

      final response = await _aiService.sendMessage(
        systemPrompt: systemPrompt,
        contents: [
          {'role': 'user', 'parts': [{'text': userMessage}]}
        ],
        model: model,
        characterId: widget.characterId,
        chatRoomId: widget.chatRoomId,
        logType: 'diary',
      );

      final entries = DiaryParser.parse(response.text, chatRoomId: widget.chatRoomId, date: date);
      for (final entry in entries) {
        await _db.createDiaryEntry(entry);
      }

      _diaryDates.add(date);

      // Reload entries for the selected date
      if (_selectedDate == date) {
        final updated = await _db.readDiaryEntriesByDate(widget.chatRoomId, date);
        if (mounted) setState(() => _selectedDayEntries = updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).diaryGenerateFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _onDayTapped(String date) async {
    final entries = await _db.readDiaryEntriesByDate(widget.chatRoomId, date);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    if (entries.isEmpty) {
      // Ask if user wants to generate
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.diaryGenerateTitle),
          content: Text(l10n.diaryGenerateContent(date)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonConfirm)),
          ],
        ),
      );
      if (confirmed == true) {
        setState(() => _selectedDate = date);
        await _generateDiary(date);
      }
    } else {
      setState(() {
        _selectedDate = date;
        _selectedDayEntries = entries;
      });
    }
  }

  void _viewDiary(DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _deleteDiaryEntry(DiaryEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.diaryDeleteTitle),
        content: Text(l10n.diaryDeleteContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteDiaryEntry(entry.id!);
    final updated = await _db.readDiaryEntriesByDate(widget.chatRoomId, entry.date);
    if (!mounted) return;
    setState(() {
      _selectedDayEntries = updated;
      if (updated.isEmpty) {
        _diaryDates.remove(entry.date);
      }
    });
  }

  Future<void> _regenerateDiary() async {
    if (_selectedDate == null || _isGenerating) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.diaryRegenerateTitle),
        content: Text(l10n.diaryRegenerateContent(_selectedDate!)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    // Delete existing entries for this date
    for (final entry in _selectedDayEntries) {
      await _db.deleteDiaryEntry(entry.id!);
    }
    setState(() => _selectedDayEntries = []);

    await _generateDiary(_selectedDate!);
  }

  // ── Calendar helpers ──

  String _dateToString(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSecondary = Theme.of(context).colorScheme.onSecondary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        iconTheme: IconThemeData(color: onSecondary),
        title: Text('Diary', style: TextStyle(color: onSecondary)),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: onSecondary),
            tooltip: AppLocalizations.of(context).diarySettingsTooltip,
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildModelDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isGenerating) const LinearProgressIndicator(),
                _buildCalendar(),
                const Divider(height: 1),
                Expanded(child: _buildEntryList()),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    final days = _getDaysInMonth(_currentMonth);
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                }),
              ),
              Text(
                '${_currentMonth.year}.${_currentMonth.month.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                }),
              ),
            ],
          ),
        ),
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              AppLocalizations.of(context).diaryDaySun,
              AppLocalizations.of(context).diaryDayMon,
              AppLocalizations.of(context).diaryDayTue,
              AppLocalizations.of(context).diaryDayWed,
              AppLocalizations.of(context).diaryDayThu,
              AppLocalizations.of(context).diaryDayFri,
              AppLocalizations.of(context).diaryDaySat,
            ]
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                )),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.7,
            ),
            itemCount: firstWeekday + days.length,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = days[index - firstWeekday];
              final dateStr = _dateToString(day);
              final isCurrentChatDate = dateStr == _currentChatDate;
              final hasDiary = _diaryDates.contains(dateStr);
              final hasCharacters = _dateCharacters.containsKey(dateStr);
              final isSelected = dateStr == _selectedDate;
              final characters = _dateCharacters[dateStr] ?? [];

              return GestureDetector(
                onTap: hasCharacters || hasDiary ? () => _onDayTapped(dateStr) : null,
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : isCurrentChatDate
                            ? colorScheme.tertiary.withValues(alpha: 0.15)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentChatDate
                        ? Border.all(color: colorScheme.tertiary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isCurrentChatDate ? FontWeight.bold : null,
                              color: hasCharacters || hasDiary
                                  ? colorScheme.onSurface
                                  : colorScheme.outline.withValues(alpha: 0.5),
                            ),
                      ),
                      if (hasDiary)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.auto_stories, size: 10, color: colorScheme.primary),
                        ),
                      if (characters.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 1,
                              runSpacing: 1,
                              children: characters.take(3).map((name) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    name.length > 3 ? '${name.substring(0, 3)}..' : name,
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEntryList() {
    final l10n = AppLocalizations.of(context);
    if (_selectedDate == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories,
                size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(l10n.diarySelectDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ],
        ),
      );
    }

    if (_selectedDayEntries.isEmpty) {
      return Center(
        child: _isGenerating
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.diaryGenerating),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note,
                      size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(l10n.diaryNoEntries,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ],
              ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _selectedDayEntries.length + 1, // +1 for header
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  _selectedDate!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: l10n.diaryRegenerateTooltip,
                  onPressed: _isGenerating ? null : _regenerateDiary,
                ),
              ],
            ),
          );
        }
        final entry = _selectedDayEntries[i - 1];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewDiary(entry),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.author,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.author}의 일기',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _deleteDiaryEntry(entry),
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(Icons.delete_outline, size: 18, color: colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelDrawer() {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<DiaryModelProvider>(
            builder: (context, provider, _) {
              final l10n = AppLocalizations.of(context);
              final providerOptions = ProviderOption.buildOptions(provider.customProviders);

              ProviderOption? currentProviderOption;
              if (provider.modelPreset == ModelPreset.custom) {
                currentProviderOption = providerOptions.where(
                  (o) => o.builtInProvider == provider.selectedProvider,
                ).firstOrNull;
                currentProviderOption ??= providerOptions.firstOrNull;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.diaryUsedModel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    label: l10n.diaryModelPreset,
                    child: CommonDropdownButton<ModelPreset>(
                      value: provider.modelPreset,
                      items: ModelPreset.values,
                      onChanged: (p) { if (p != null) provider.setModelPreset(p); },
                      labelBuilder: (p) => p.displayName,
                      size: CommonDropdownButtonSize.xsmall,
                    ),
                  ),
                  if (provider.modelPreset != ModelPreset.custom) ...[
                    const SizedBox(height: 4),
                    Consumer<ChatModelSettingsProvider>(
                      builder: (context, chatProvider, _) => Text(
                        provider.modelPreset == ModelPreset.primary
                            ? chatProvider.primaryModelLabel
                            : chatProvider.subModelLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ),
                  ],
                  if (provider.modelPreset == ModelPreset.custom) ...[
                    const SizedBox(height: 8),
                    _buildSettingRow(
                      label: l10n.diaryProvider,
                      child: CommonDropdownButton<ProviderOption>(
                        value: currentProviderOption,
                        items: providerOptions,
                        onChanged: (option) {
                          if (option == null) return;
                          if (option.isCustom) {
                            provider.setProvider(ChatModelProvider.custom);
                          } else {
                            provider.setProvider(option.builtInProvider!);
                          }
                        },
                        labelBuilder: (o) => o.displayName,
                        size: CommonDropdownButtonSize.xsmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSettingRow(
                      label: l10n.diaryChatModel,
                      child: CommonDropdownButton<UnifiedModel>(
                        value: provider.selectedModel,
                        items: provider.availableModels,
                        onChanged: (m) { if (m != null) provider.setModel(m); },
                        labelBuilder: (m) => m.displayName,
                        size: CommonDropdownButtonSize.xsmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.diarySettingsSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.diaryAutoGenerate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                      Switch(
                        value: provider.autoGenerate,
                        onChanged: (v) => provider.setAutoGenerate(v),
                      ),
                    ],
                  ),
                  if (provider.autoGenerate)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.diaryAutoGenerateDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
