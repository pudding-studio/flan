import 'package:flutter/material.dart';
import '../../models/prompt/auxiliary_prompt.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/settings/auxiliary_prompt_editor.dart';

class AuxiliaryPromptEditScreen extends StatelessWidget {
  final AuxiliaryPromptKey promptKey;
  final String title;

  const AuxiliaryPromptEditScreen({
    super.key,
    required this.promptKey,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: title),
      body: AuxiliaryPromptEditor(promptKey: promptKey),
    );
  }
}
