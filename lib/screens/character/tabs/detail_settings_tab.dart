import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../widgets/common/common_label_with_help.dart';

class DetailSettingsTab extends StatelessWidget {
  final TextEditingController descriptionController;

  const DetailSettingsTab({
    super.key,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CommonLabelWithHelp(
                  label: '세계관 설정',
                  helpMessage: '캐릭터가 속한 세계관이나 배경 설정을 자유롭게 작성해주세요.',
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: descriptionController,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextFormField(
              controller: descriptionController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '세계관 설정을 입력해주세요.',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                counterText: '',
                isDense: true,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}
