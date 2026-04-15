import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../database/database_helper.dart';
import '../../../models/chat/agent_entry.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';

class DrawerAgentPanel extends StatefulWidget {
  final List<AgentEntry> agentEntries;
  final DatabaseHelper db;
  final VoidCallback onDataChanged; // callback to reload parent data

  const DrawerAgentPanel({
    super.key,
    required this.agentEntries,
    required this.db,
    required this.onDataChanged,
  });

  @override
  DrawerAgentPanelState createState() => DrawerAgentPanelState();
}

class DrawerAgentPanelState extends State<DrawerAgentPanel> {
  int _agentSubTabIndex = 0;
  final Set<int> _expandedAgentEntryIds = {};
  final Set<int> _editingAgentEntryIds = {};
  final Map<int, Map<String, TextEditingController>> _agentEditControllers = {};
  final Map<int, TextEditingController> _agentNameEditControllers = {};

  static const _agentTabTypes = AgentEntryType.values;
  static const _agentTabIcons = [
    Icons.auto_stories,
    Icons.person_outline,
    Icons.place_outlined,
    Icons.inventory_2_outlined,
    Icons.emoji_events_outlined,
  ];

  @override
  void dispose() {
    _disposeAllAgentEditControllers();
    super.dispose();
  }

  // ==================== Build methods ====================

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        // Sub-tab chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: List.generate(_agentTabTypes.length, (i) {
              final type = _agentTabTypes[i];
              final count =
                  widget.agentEntries.where((e) => e.entryType == type).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: Icon(_agentTabIcons[i], size: 16),
                  label: Text(
                      '${_agentEntryTypeName(type, AppLocalizations.of(context))} ($count)'),
                  selected: _agentSubTabIndex == i,
                  onSelected: (_) => setState(() => _agentSubTabIndex = i),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        // Entry list for selected type
        Expanded(
          child: _buildAgentEntryList(
            _agentTabTypes[_agentSubTabIndex],
            bottomInset,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentEntryList(AgentEntryType type, double bottomInset) {
    final l10n = AppLocalizations.of(context);
    final entries =
        widget.agentEntries.where((e) => e.entryType == type).toList();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.drawerAgentEntryEmpty(_agentEntryTypeName(type, l10n)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isExpanded = _expandedAgentEntryIds.contains(entry.id);

        return CommonEditableExpandableItem(
          key: ValueKey('agent_${entry.id}'),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _agentTabIcons[_agentTabTypes.indexOf(type)],
                size: 20,
                color: entry.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.isActive
                      ? Colors.green
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
          name: entry.name,
          isExpanded: isExpanded,
          showNameField: false,
          onToggleExpanded: () {
            setState(() {
              if (isExpanded) {
                _expandedAgentEntryIds.remove(entry.id!);
              } else {
                _expandedAgentEntryIds.add(entry.id!);
              }
            });
          },
          onDelete: () => _deleteAgentEntry(entry),
          onEdit: _editingAgentEntryIds.contains(entry.id)
              ? null
              : () => _editAgentEntry(entry),
          content: _editingAgentEntryIds.contains(entry.id)
              ? _buildAgentEntryEditContent(entry)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active toggle
                    Row(
                      children: [
                        Text(
                          entry.isActive
                              ? l10n.drawerActive
                              : l10n.drawerInactive,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: entry.isActive
                                        ? Colors.green
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                        ),
                        const Spacer(),
                        Switch(
                          value: entry.isActive,
                          onChanged: (value) =>
                              _toggleAgentEntryActive(entry, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Data fields
                    ..._buildAgentEntryFields(entry),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAgentEntryEditContent(AgentEntry entry) {
    final l10n = AppLocalizations.of(context);
    final id = entry.id!;
    final nameCtrl = _agentNameEditControllers[id]!;
    final controllers = _agentEditControllers[id]!;
    final fieldDefs = _agentFieldDefs(entry.entryType, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.drawerNameLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        CommonEditText(
          controller: nameCtrl,
          hintText: l10n.drawerNameHint,
          size: CommonEditTextSize.small,
        ),
        ...fieldDefs.map((def) {
          final (key, label, _) = def;
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                CommonEditText(
                  controller: controllers[key],
                  hintText: label,
                  maxLines: null,
                  minLines: 1,
                  size: CommonEditTextSize.small,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _cancelEditAgentEntry(id),
              child: Text(l10n.commonCancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _saveAgentEntry(entry),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildAgentEntryFields(AgentEntry entry) {
    final l10n = AppLocalizations.of(context);
    final fields = <Widget>[];
    final data = entry.data;

    void addField(String label, dynamic value) {
      if (value == null) return;
      final text = value is List ? value.join(', ') : value.toString();
      if (text.isEmpty) return;
      fields.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ));
    }

    switch (entry.entryType) {
      case AgentEntryType.episode:
        addField(l10n.agentFieldDateRange, data['date_range']);
        addField(l10n.agentFieldCharacters, data['characters']);
        addField(l10n.agentFieldLocations, data['locations']);
        addField(l10n.agentFieldSummary, data['summary_text']);
      case AgentEntryType.character:
        addField(l10n.agentFieldAppearance, data['appearance']);
        addField(l10n.agentFieldPersonality, data['personality']);
        addField(l10n.agentFieldPast, data['past']);
        addField(l10n.agentFieldAbilities, data['abilities']);
        addField(l10n.agentFieldStoryActions, data['story_actions']);
        addField(l10n.agentFieldDialogueStyle, data['dialogue_style']);
        addField(l10n.agentFieldPossessions, data['possessions']);
      case AgentEntryType.location:
        addField(l10n.agentFieldParentLocation, data['parent_location']);
        addField(l10n.agentFieldFeatures, data['features']);
        if (data['ascii_map'] != null) {
          addField(l10n.agentFieldAsciiMap, data['ascii_map']);
        }
        addField(l10n.agentFieldRelatedEpisodes, data['related_episodes']);
      case AgentEntryType.item:
        addField(l10n.agentFieldKeywords, data['keywords']);
        addField(l10n.agentFieldFeatures, data['features']);
        addField(l10n.agentFieldRelatedEpisodes, data['related_episodes']);
      case AgentEntryType.event:
        addField(l10n.agentFieldDatetime, data['datetime']);
        addField(l10n.agentFieldOverview, data['overview']);
        addField(l10n.agentFieldResult, data['result']);
        addField(l10n.agentFieldRelatedEpisodes, data['related_episodes']);
    }

    // Related names (cross-references)
    if (entry.relatedNames.isNotEmpty) {
      fields.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: entry.relatedNames.map((name) {
            return Chip(
              label: Text(name),
              visualDensity: VisualDensity.compact,
              labelStyle: Theme.of(context).textTheme.labelSmall,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ));
    }

    return fields;
  }

  // ==================== Logic methods ====================

  Future<void> _toggleAgentEntryActive(AgentEntry entry, bool isActive) async {
    if (entry.id == null) return;
    await widget.db.setAgentEntryActive(entry.id!, isActive);
    widget.onDataChanged();
  }

  String _agentEntryTypeName(AgentEntryType type, AppLocalizations l10n) {
    switch (type) {
      case AgentEntryType.episode:
        return l10n.agentEntryTypeEpisode;
      case AgentEntryType.character:
        return l10n.agentEntryTypeCharacter;
      case AgentEntryType.location:
        return l10n.agentEntryTypeLocation;
      case AgentEntryType.item:
        return l10n.agentEntryTypeItem;
      case AgentEntryType.event:
        return l10n.agentEntryTypeEvent;
    }
  }

  List<(String, String, bool)> _agentFieldDefs(
      AgentEntryType type, AppLocalizations l10n) {
    switch (type) {
      case AgentEntryType.episode:
        return [
          ('date_range', l10n.agentFieldDateRange, false),
          ('characters', l10n.agentFieldCharactersList, true),
          ('locations', l10n.agentFieldLocationsList, true),
          ('summary_text', l10n.agentFieldSummary, false),
        ];
      case AgentEntryType.character:
        return [
          ('appearance', l10n.agentFieldAppearance, false),
          ('personality', l10n.agentFieldPersonality, false),
          ('past', l10n.agentFieldPast, false),
          ('abilities', l10n.agentFieldAbilities, false),
          ('story_actions', l10n.agentFieldStoryActions, false),
          ('dialogue_style', l10n.agentFieldDialogueStyle, false),
          ('possessions', l10n.agentFieldPossessionsList, true),
        ];
      case AgentEntryType.location:
        return [
          ('parent_location', l10n.agentFieldParentLocation, false),
          ('features', l10n.agentFieldFeatures, false),
          ('ascii_map', l10n.agentFieldAsciiMap, false),
          ('related_episodes', l10n.agentFieldRelatedEpisodesList, true),
        ];
      case AgentEntryType.item:
        return [
          ('keywords', l10n.agentFieldKeywords, false),
          ('features', l10n.agentFieldFeatures, false),
          ('related_episodes', l10n.agentFieldRelatedEpisodesList, true),
        ];
      case AgentEntryType.event:
        return [
          ('datetime', l10n.agentFieldDatetime, false),
          ('overview', l10n.agentFieldOverview, false),
          ('result', l10n.agentFieldResult, false),
          ('related_episodes', l10n.agentFieldRelatedEpisodesList, true),
        ];
    }
  }

  void _initAgentEditControllers(AgentEntry entry) {
    final id = entry.id!;
    final data = entry.data;
    final fieldDefs =
        _agentFieldDefs(entry.entryType, AppLocalizations.of(context));

    _agentNameEditControllers[id] = TextEditingController(text: entry.name);
    _agentEditControllers[id] = {
      for (final (key, _, isList) in fieldDefs)
        key: TextEditingController(
          text: isList
              ? ((data[key] as List?)?.join(', ') ?? '')
              : (data[key]?.toString() ?? ''),
        ),
    };
  }

  void _disposeAgentEditControllers(int id) {
    _agentNameEditControllers[id]?.dispose();
    _agentNameEditControllers.remove(id);
    final controllers = _agentEditControllers.remove(id);
    if (controllers != null) {
      for (final c in controllers.values) {
        c.dispose();
      }
    }
  }

  void _disposeAllAgentEditControllers() {
    for (final id in _agentEditControllers.keys.toList()) {
      _disposeAgentEditControllers(id);
    }
  }

  void _editAgentEntry(AgentEntry entry) {
    final id = entry.id!;
    setState(() {
      _editingAgentEntryIds.add(id);
      _expandedAgentEntryIds.add(id);
      _initAgentEditControllers(entry);
    });
  }

  void _cancelEditAgentEntry(int id) {
    setState(() {
      _editingAgentEntryIds.remove(id);
      _disposeAgentEditControllers(id);
    });
  }

  Future<void> _saveAgentEntry(AgentEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final id = entry.id!;
    final nameCtrl = _agentNameEditControllers[id];
    final controllers = _agentEditControllers[id];
    if (nameCtrl == null || controllers == null) return;

    final fieldDefs = _agentFieldDefs(entry.entryType, l10n);
    final updatedData = Map<String, dynamic>.from(entry.data);

    for (final (key, _, isList) in fieldDefs) {
      final text = controllers[key]!.text.trim();
      if (text.isEmpty) {
        updatedData.remove(key);
      } else if (isList) {
        updatedData[key] = text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        updatedData[key] = text;
      }
    }

    final updatedEntry = entry.copyWith(
      name: nameCtrl.text.trim().isEmpty ? entry.name : nameCtrl.text.trim(),
      data: updatedData,
      updatedAt: DateTime.now(),
    );
    await widget.db.updateAgentEntry(updatedEntry);

    _cancelEditAgentEntry(id);
    widget.onDataChanged();

    if (!mounted) return;
    CommonDialog.showSnackBar(
      context: context,
      message: l10n.drawerAgentEntrySaved(updatedEntry.name),
    );
  }

  Future<void> _deleteAgentEntry(AgentEntry entry) async {
    if (entry.id == null) return;
    final entryName = entry.name;
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: entryName,
    );
    if (!confirmed) return;

    await widget.db.deleteAgentEntry(entry.id!);
    widget.onDataChanged();

    if (!mounted) return;
    CommonDialog.showSnackBar(
      context: context,
      message: AppLocalizations.of(context).drawerAgentEntryDeleted(entryName),
    );
  }
}
