# 코드 파일 생성 규칙

## 프로젝트 구조 개요

```
lib/
├── constants/      # 상수 정의
├── models/         # 데이터 모델
├── screens/        # 화면 (탭별 폴더로 구성)
├── theme/          # 테마 및 스타일
├── widgets/        # 공용 위젯
└── main.dart       # 앱 진입점
```

## 1. Screens 구조 규칙

**중요: screen은 탭 이름별로 폴더로 나뉘어져 있어야 합니다.**

### 1.1 탭별 폴더 구조

```
lib/screens/
├── character/              # 캐릭터 탭
│   ├── character_screen.dart
│   ├── character_edit_screen.dart
│   └── widgets/            # 캐릭터 탭 전용 위젯
│       ├── character_card.dart
│       └── character_list_item.dart
├── chat/                   # 채팅 탭
│   ├── chat_screen.dart
│   ├── chat_room_screen.dart
│   └── widgets/            # 채팅 탭 전용 위젯
│       └── chat_room_card.dart
└── settings/               # 설정 탭
    ├── settings_screen.dart
    └── widgets/            # 설정 탭 전용 위젯
        └── settings_list_tile.dart
```

### 1.2 Screen 파일 명명 규칙

- 메인 화면: `{탭이름}_screen.dart` (예: `character_screen.dart`)
- 서브 화면: `{탭이름}_{기능}_screen.dart` (예: `character_edit_screen.dart`)
- 탭 전용 위젯: `screens/{탭이름}/widgets/{위젯이름}.dart`

### 1.3 Screen 파일 생성 시 체크리스트

- [ ] 해당 탭 폴더 안에 생성되었는가?
- [ ] 파일명이 `{탭이름}_`으로 시작하는가?
- [ ] 전용 위젯이 있다면 `widgets/` 서브폴더에 분리되었는가?

## 2. Models 구조 규칙

### 2.1 모델 파일 명명 규칙

- 단수형 사용: `persona.dart`, `character.dart`
- snake_case 사용
- 복합 단어는 밑줄로 연결: `lorebook_folder.dart`, `start_scenario.dart`

### 2.2 모델 파일 구조

```dart
// lib/models/character.dart
class Character {
  final String id;
  final String name;
  // ...

  Character({
    required this.id,
    required this.name,
    // ...
  });

  // JSON serialization
  factory Character.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

## 3. Widgets 구조 규칙

### 3.1 공용 위젯 vs 탭 전용 위젯

**공용 위젯 (`lib/widgets/`)**
- 여러 탭에서 사용되는 재사용 가능한 위젯
- 예: `custom_text_field.dart`, `loading_indicator.dart`

**탭 전용 위젯 (`lib/screens/{탭이름}/widgets/`)**
- 특정 탭에서만 사용되는 위젯
- 예: `lib/screens/character/widgets/character_card.dart`

### 3.2 위젯 파일 명명 규칙

- snake_case 사용
- 위젯의 역할을 명확히 표현
- 예: `custom_text_field.dart`, `character_card.dart`

### 3.3 Private 위젯 규칙

화면 파일 내부에서만 사용되는 위젯은 `_` 접두사로 시작:

```dart
// character_screen.dart 내부
class _CharacterCard extends StatelessWidget { ... }
class _TagChip extends StatelessWidget { ... }
```

재사용 가능성이 있으면 별도 파일로 분리:
```dart
// lib/screens/character/widgets/character_card.dart
class CharacterCard extends StatelessWidget { ... }
```

## 4. Constants 구조 규칙

### 4.1 상수 파일 분류

```
lib/constants/
├── ui_constants.dart       # UI 관련 상수 (패딩, 크기 등)
├── api_constants.dart      # API 엔드포인트
├── app_constants.dart      # 앱 전역 상수
└── route_constants.dart    # 라우트 이름
```

### 4.2 상수 정의 규칙

```dart
// ui_constants.dart
class UIConstants {
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 20.0;
  // ...
}
```

## 5. Theme 구조 규칙

### 5.1 테마 파일 구조

```
lib/theme/
├── app_theme.dart              # 메인 테마 설정
├── custom_indicator_shape.dart # 커스텀 Shape
└── text_styles.dart            # 텍스트 스타일 정의 (필요시)
```

## 6. 일반 파일 생성 규칙

### 6.1 파일명 규칙

- **파일명**: snake_case 사용
- **클래스명**: PascalCase 사용
- 파일명과 주요 클래스명은 일치해야 함
  ```dart
  // character_screen.dart
  class CharacterScreen extends StatefulWidget { ... }
  ```

### 6.2 Import 순서

```dart
// 1. Dart 기본 패키지
import 'dart:async';

// 2. Flutter 패키지
import 'package:flutter/material.dart';

// 3. 서드파티 패키지
import 'package:provider/provider.dart';

// 4. 프로젝트 파일 (상대경로 사용 금지, package: import 사용)
import 'package:flan/models/character.dart';
import 'package:flan/widgets/custom_text_field.dart';
```

### 6.3 파일 크기 가이드라인

- 하나의 파일은 500줄 이하를 권장
- 500줄 초과 시 파일 분리 고려:
  - 위젯을 별도 파일로 분리
  - 비즈니스 로직을 별도 클래스로 분리

## 7. 새로운 탭 추가 시 절차

1. `lib/screens/{새로운_탭이름}/` 폴더 생성
2. `{새로운_탭이름}_screen.dart` 파일 생성
3. 필요한 경우 `widgets/` 서브폴더 생성
4. `main.dart`에 탭 추가
5. 관련 모델이 있다면 `lib/models/`에 추가

## 8. 체크리스트

새로운 파일 생성 전 확인사항:

- [ ] 파일을 올바른 폴더에 생성하는가?
- [ ] 파일명이 snake_case를 따르는가?
- [ ] 클래스명이 PascalCase를 따르는가?
- [ ] Screen 파일이 탭별 폴더에 있는가?
- [ ] 탭 전용 위젯이 해당 탭의 widgets 폴더에 있는가?
- [ ] Import 순서가 올바른가?
- [ ] Private 클래스(`_`로 시작)와 public 클래스를 적절히 구분했는가?

## 9. 예시

### 좋은 예시

```
lib/screens/character/character_screen.dart
lib/screens/character/character_edit_screen.dart
lib/screens/character/widgets/character_card.dart
lib/models/character.dart
lib/widgets/custom_button.dart
```

### 나쁜 예시

```
lib/screens/character_screen.dart              # ❌ 탭별 폴더가 없음
lib/screens/characterScreen.dart               # ❌ camelCase 사용
lib/character_card.dart                        # ❌ 잘못된 위치
lib/screens/character/CharacterCard.dart       # ❌ PascalCase 파일명
```
