import 'package:flutter/material.dart';
import '../../models/prompt/auxiliary_prompt.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/settings/auxiliary_prompt_editor.dart';

class MultiAuxTab {
  final String label;
  final AuxiliaryPromptKey key;

  const MultiAuxTab({required this.label, required this.key});
}

class AuxiliaryMultiPromptEditScreen extends StatefulWidget {
  final String title;
  final List<MultiAuxTab> tabs;

  const AuxiliaryMultiPromptEditScreen({
    super.key,
    required this.title,
    required this.tabs,
  });

  @override
  State<AuxiliaryMultiPromptEditScreen> createState() =>
      _AuxiliaryMultiPromptEditScreenState();
}

class _AuxiliaryMultiPromptEditScreenState
    extends State<AuxiliaryMultiPromptEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.title,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: widget.tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.tabs
            .map(
              (t) => AuxiliaryPromptEditor(
                key: ValueKey(t.key.storageKey),
                promptKey: t.key,
              ),
            )
            .toList(),
      ),
    );
  }
}
