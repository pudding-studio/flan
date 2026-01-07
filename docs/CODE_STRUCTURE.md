# 코드 파일 생성 규칙

## 폴더 구조

```
lib/
├── main.dart
├── constants/          # 상수 정의
│   └── ui_constants.dart
├── models/             # 데이터 모델
│   └── character/
│       ├── lorebook_folder.dart
│       ├── persona.dart
│       └── start_scenario.dart
├── screens/            # 화면 (Screen)
│   ├── chat/
│   │   └── chat_screen.dart
│   ├── character/
│   │   ├── character_screen.dart
│   │   └── character_edit_screen.dart
│   ├── character_edit/
│   │   ├── character_edit_screen.dart
│   │   ├── tabs/
│   │   │   ├── profile_tab.dart
│   │   │   ├── detail_settings_tab.dart
│   │   │   ├── lorebook_tab.dart
│   │   │   └── start_settings_tab.dart
│   │   └── widgets/
│   │       ├── folder_item.dart
│   │       ├── lorebook_item.dart
│   │       └── lorebook_fields.dart
│   └── settings/
│       └── settings_screen.dart
├── theme/              # 테마 설정
│   ├── app_theme.dart
│   └── custom_indicator_shape.dart
└── widgets/            # 공통 위젯
    └── custom_text_field.dart
```

## 파일 생성 규칙

### 1. Screen 파일
- **위치**: `lib/screens/{기능명}/`
- **명명 규칙**: `{기능명}_screen.dart`
- **예시**: `character_edit_screen.dart`, `chat_screen.dart`

#### Screen에 탭이 있는 경우
- **탭 파일 위치**: `lib/screens/{기능명}/tabs/`
- **탭 명명 규칙**: `{탭이름}_tab.dart`
- **예시**:
  - `profile_tab.dart` (프로필 탭)
  - `detail_settings_tab.dart` (캐릭터설정 탭)
  - `lorebook_tab.dart` (로어북 탭)
  - `start_settings_tab.dart` (시작설정 탭)

#### Screen 전용 위젯이 있는 경우
- **위젯 파일 위치**: `lib/screens/{기능명}/widgets/`
- **위젯 명명 규칙**: `{위젯명}.dart`
- **예시**:
  - `folder_item.dart` (폴더 아이템 위젯)
  - `lorebook_item.dart` (로어북 아이템 위젯)

### 2. Model 파일
- **위치**: `lib/models/{기능명}/`
- **명명 규칙**: `{모델명}_snake_case.dart`
- **예시**:
  - `lib/models/character/lorebook_folder.dart`
  - `lib/models/character/persona.dart`
  - `lib/models/chat/chat_message.dart`

### 3. Widget 파일 (공통)
- **위치**: `lib/widgets/`
- **명명 규칙**: `{위젯명}.dart`
- **용도**: 여러 화면에서 공통으로 사용되는 위젯
- **예시**: `custom_text_field.dart`

### 4. Constants 파일
- **위치**: `lib/constants/`
- **명명 규칙**: `{카테고리명}_constants.dart`
- **예시**: `ui_constants.dart`, `api_constants.dart`

### 5. Theme 파일
- **위치**: `lib/theme/`
- **명명 규칙**: `{테마요소명}.dart`
- **예시**: `app_theme.dart`, `custom_indicator_shape.dart`

## 코드 분리 원칙

### 1. 단일 책임 원칙
- 하나의 파일은 하나의 책임만 가져야 함
- Screen 파일이 500줄을 넘어가면 탭이나 위젯으로 분리 고려

### 2. 탭 분리 기준
- TabController를 사용하는 Screen은 각 탭을 별도 파일로 분리
- 각 탭은 독립적인 StatefulWidget 또는 StatelessWidget으로 구현

### 3. 위젯 분리 기준
- 동일한 위젯이 2번 이상 사용되면 별도 파일로 분리
- 100줄 이상의 복잡한 위젯은 별도 파일로 분리 고려

### 4. Screen 전용 vs 공통 위젯
- **Screen 전용**: 해당 Screen에서만 사용 → `screens/{기능명}/widgets/`
- **공통**: 여러 Screen에서 사용 → `widgets/`

## Import 순서

```dart
// 1. Dart 기본 라이브러리
import 'dart:async';

// 2. Flutter 패키지
import 'package:flutter/material.dart';

// 3. 외부 패키지
import 'package:provider/provider.dart';

// 4. 프로젝트 내부 파일 (상대 경로)
import '../models/character/lorebook_folder.dart';
import '../widgets/custom_text_field.dart';
import '../constants/ui_constants.dart';
```

## 클래스 명명 규칙

- **Screen**: `{기능명}Screen` (예: `CharacterEditScreen`)
- **Tab**: `{탭이름}Tab` (예: `ProfileTab`, `LorebookTab`)
- **Widget**: `{위젯명}` (예: `FolderItem`, `CustomTextField`)
- **Model**: `{모델명}` (예: `LorebookFolder`, `Persona`)

## 파일 구조 예시

### Screen 파일 (character_edit_screen.dart)
```dart
import 'package:flutter/material.dart';
import 'tabs/profile_tab.dart';
import 'tabs/lorebook_tab.dart';

class CharacterEditScreen extends StatefulWidget {
  // Screen의 주요 역할: 탭 관리 및 전체 레이아웃
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(/* ... */),
      body: TabBarView(
        children: [
          ProfileTab(),
          LorebookTab(),
          // ...
        ],
      ),
    );
  }
}
```

### Tab 파일 (lorebook_tab.dart)
```dart
import 'package:flutter/material.dart';
import '../widgets/folder_item.dart';

class LorebookTab extends StatefulWidget {
  // Tab의 주요 역할: 해당 탭의 UI 및 로직 관리
  @override
  Widget build(BuildContext context) {
    return /* 탭 내용 */;
  }
}
```

## 주의사항

1. **절대 경로 사용 금지**: import는 항상 상대 경로 사용
2. **순환 참조 방지**: 파일 간 상호 참조가 발생하지 않도록 설계
3. **파일 크기 제한**: 하나의 파일은 가능한 500줄 이하로 유지
4. **일관성 유지**: 기존 규칙을 따라 새로운 파일 생성
