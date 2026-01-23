import 'package:flutter/material.dart';
import '../../../widgets/common/common_custom_text_field.dart';
import '../../../constants/ui_constants.dart';

class ProfileTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController creatorNotesController;
  final TextEditingController keywordsController;

  const ProfileTab({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.creatorNotesController,
    required this.keywordsController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        children: [
          CommonCustomTextField(
            controller: nameController,
            label: '이름',
            helpText: '캐릭터의 고유한 이름을 입력해주세요.',
            hintText: '캐릭터의 이름을 입력해주세요.',
            maxLines: null,
            showCounter: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '캐릭터 이름을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: creatorNotesController,
            label: '한 줄 소개',
            helpText: '캐릭터를 간단히 설명하는 한 문장을 작성해주세요.',
            hintText: '어떤 캐릭터인지 설명할 수 있는 간단한 소개를 입력해주세요.',
            maxLines: null,
            showCounter: true,
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: keywordsController,
            label: '키워드',
            helpText: '캐릭터를 나타내는 키워드를 쉼표(,)로 구분하여 입력해주세요.',
            hintText: '키워드 입력 예시: 판타지, 남자',
            maxLines: null,
            showCounter: true,
          ),
        ],
      ),
    );
  }
}
