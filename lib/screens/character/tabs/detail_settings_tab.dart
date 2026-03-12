import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_title_medium.dart';

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
                const CommonTitleMedium(
                  text: '세계관 설정',
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
            child: CommonEditText(
              controller: descriptionController,
              hintText: '세계관 설정을 입력해주세요.',
              size: CommonEditTextSize.medium,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}
