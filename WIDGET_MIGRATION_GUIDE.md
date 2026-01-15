# 공통 위젯 적용 가이드

프로젝트의 코드 중복을 줄이고 일관된 디자인을 유지하기 위한 공통 위젯 시스템이 구축되었습니다.

## 🎯 생성된 공통 위젯

### 1. UIConstants (디자인 토큰)
**위치**: `lib/constants/ui_constants.dart`

```dart
// Border Radius
UIConstants.borderRadiusSmall         // 8.0
UIConstants.borderRadiusMedium        // 10.0
UIConstants.borderRadiusLarge         // 12.0
UIConstants.borderRadiusXLarge        // 16.0
UIConstants.borderRadiusXXLarge       // 20.0

// Opacity
UIConstants.opacityLow                // 0.2
UIConstants.opacityMedium             // 0.3
UIConstants.opacityHigh               // 0.5
UIConstants.opacitySemiTransparent    // 0.7

// Spacing
UIConstants.spacing4 / spacing8 / spacing12 / spacing16 / spacing20 / spacing24

// Icon Sizes
UIConstants.iconSizeSmall / iconSizeMedium / iconSizeLarge / iconSizeXLarge

// Padding
UIConstants.textFieldPaddingSmall     // (h:12, v:8)
UIConstants.textFieldPaddingLarge     // (h:18, v:10)
UIConstants.containerPadding          // (h:10, v:10)
```

---

### 2. LabelWithHelp
**위치**: `lib/widgets/label_with_help.dart`

#### 기존 코드
```dart
Row(
  children: [
    Text(
      '이름',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    SizedBox(width: 4),
    GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('도움말 내용'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('확인'),
              ),
            ],
          ),
        );
      },
      child: Icon(
        Icons.help_outline,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  ],
)
```

#### 개선된 코드
```dart
LabelWithHelp(
  label: '이름',
  helpMessage: '도움말 내용',
)
```

#### 적용 대상 파일 (8개)
- `lib/screens/settings/tabs/prompt_items_tab.dart` ✅ 완료
- `lib/screens/settings/prompt_edit_screen.dart`
- `lib/screens/character/character_edit_screen.dart`
- `lib/screens/character/tabs/start_scenario_tab.dart`
- `lib/screens/character/tabs/persona_tab.dart`
- `lib/screens/character/tabs/lorebook_tab.dart` ✅ 완료
- `lib/screens/character/tabs/cover_image_tab.dart`
- `lib/screens/character/tabs/detail_settings_tab.dart`

---

### 3. CommonTextField
**위치**: `lib/widgets/common_text_field.dart`

#### 기존 코드
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      '이름',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    SizedBox(height: 8),
    TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: '힌트',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    ),
  ],
)
```

#### 개선된 코드
```dart
CommonTextField(
  labelText: '이름',
  hintText: '힌트',
  helpMessage: '도움말 (선택사항)',
  controller: _controller,
  size: TextFieldSize.small,  // or TextFieldSize.large
)
```

#### 적용 대상 파일 (11개)
- `lib/screens/settings/tabs/prompt_items_tab.dart`
- `lib/screens/settings/prompt_edit_screen.dart`
- `lib/screens/chat/chat_room_screen.dart`
- `lib/screens/chat/chat_screen.dart`
- `lib/screens/character/character_edit_screen.dart`
- `lib/screens/character/tabs/start_scenario_tab.dart`
- `lib/screens/character/tabs/persona_tab.dart`
- `lib/screens/character/tabs/lorebook_tab.dart`
- `lib/screens/settings/api_key_screen.dart`
- `lib/screens/character/tabs/cover_image_tab.dart`
- `lib/screens/character/tabs/profile_tab.dart`

---

### 4. CommonDialog
**위치**: `lib/utils/common_dialog.dart`

#### 4-1. 확인 다이얼로그

**기존 코드**
```dart
final confirm = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('제목'),
    content: Text('내용'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('취소'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('확인'),
      ),
    ],
  ),
);
```

**개선된 코드**
```dart
final confirm = await CommonDialog.showConfirmation(
  context: context,
  title: '제목',
  content: '내용',
  confirmText: '확인',  // 기본값: '확인'
  cancelText: '취소',   // 기본값: '취소'
  isDestructive: false, // true면 빨간색 삭제 스타일
);
```

#### 4-2. 삭제 확인 다이얼로그

**기존 코드**
```dart
final confirm = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('삭제 확인'),
    content: Text('캐릭터를 삭제하시겠습니까?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('취소'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('삭제', style: TextStyle(color: Colors.red)),
      ),
    ],
  ),
);
```

**개선된 코드**
```dart
final confirmed = await CommonDialog.showDeleteConfirmation(
  context: context,
  itemName: '캐릭터',
);
```

#### 4-3. 정보 다이얼로그

**기존 코드**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('도움말'),
    content: Text('설명 내용'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('확인'),
      ),
    ],
  ),
);
```

**개선된 코드**
```dart
await CommonDialog.showInfo(
  context: context,
  title: '도움말',  // 선택사항
  content: '설명 내용',
);
```

#### 4-4. 스낵바

**기존 코드**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('메시지')),
);
```

**개선된 코드**
```dart
CommonDialog.showSnackBar(
  context: context,
  message: '메시지',
  duration: Duration(seconds: 2),  // 선택사항
);
```

#### 적용 대상 파일

**AlertDialog 사용 (13개)**
- `lib/screens/settings/tabs/prompt_items_tab.dart`
- `lib/screens/settings/prompt_edit_screen.dart`
- `lib/screens/settings/chat_prompt_screen.dart`
- `lib/screens/character/character_screen.dart` ✅ 완료
- `lib/screens/chat/chat_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/character/character_edit_screen.dart`
- `lib/screens/character/tabs/start_scenario_tab.dart`
- `lib/screens/character/tabs/persona_tab.dart`
- `lib/screens/character/tabs/lorebook_tab.dart` ✅ 완료
- `lib/screens/settings/api_key_screen.dart`
- `lib/screens/character/tabs/cover_image_tab.dart`
- `lib/screens/character/tabs/detail_settings_tab.dart`

**SnackBar 사용 (9개)**
- `lib/screens/settings/prompt_edit_screen.dart`
- `lib/screens/settings/chat_prompt_screen.dart`
- `lib/screens/character/character_screen.dart` ✅ 완료
- `lib/screens/chat/chat_room_screen.dart`
- `lib/screens/chat/chat_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/character/character_view_screen.dart`
- `lib/screens/character/character_edit_screen.dart`
- `lib/screens/settings/api_key_screen.dart`

---

### 5. ExpandableListItem
**위치**: `lib/widgets/expandable_list_item.dart`

**주의**: 드래그 앤 드롭 기능이나 인라인 편집 기능이 있는 리스트는 직접 적용하기 어렵습니다.
대신 **드래그 기능이 없는 단순한 확장 리스트**에만 사용하세요.

#### 사용 예시
```dart
ExpandableListItem(
  titleIcon: Icon(Icons.book),
  title: '아이템 제목',
  subtitle: '부제목 (선택사항)',
  content: Text('확장된 내용'),
  onEdit: () => _handleEdit(),
  onDelete: () => _handleDelete(),
  initiallyExpanded: false,
)
```

---

## 📊 예상 개선 효과

### 코드 중복 감소
- **LabelWithHelp**: 약 15-20줄 × 8개 파일 = **120-160줄 감소**
- **CommonTextField**: 약 15-25줄 × 11개 파일 = **165-275줄 감소**
- **CommonDialog**: 약 10-15줄 × 22개 파일 = **220-330줄 감소**

**총 예상**: **약 505-765줄의 중복 코드 제거 가능**

### 유지보수성 향상
- 디자인 변경 시 한 곳만 수정
- 버그 수정 시 일괄 적용
- 신규 개발자 온보딩 용이

---

## 🔧 적용 방법

### 1단계: import 추가
```dart
// 필요한 것만 import
import 'package:flan/widgets/label_with_help.dart';
import 'package:flan/widgets/common_text_field.dart';
import 'package:flan/utils/common_dialog.dart';
import 'package:flan/constants/ui_constants.dart';
```

### 2단계: 기존 코드 교체
위의 예시를 참고하여 기존 코드를 공통 위젯으로 교체합니다.

### 3단계: 테스트
각 화면에서 정상 동작하는지 확인합니다.

---

## 💡 주의사항

1. **드래그 앤 드롭 기능**: `ExpandableListItem`은 드래그 기능과 함께 사용하기 어렵습니다.
2. **커스텀 스타일**: 특별한 스타일이 필요한 경우 공통 위젯의 파라미터를 확장하거나 직접 구현하세요.
3. **점진적 적용**: 한 번에 모든 파일을 바꾸지 말고, 파일 단위로 테스트하며 적용하세요.

---

## 📝 적용 체크리스트

### LabelWithHelp (8개)
- [x] `lib/screens/settings/tabs/prompt_items_tab.dart`
- [ ] `lib/screens/settings/prompt_edit_screen.dart`
- [ ] `lib/screens/character/character_edit_screen.dart`
- [ ] `lib/screens/character/tabs/start_scenario_tab.dart`
- [ ] `lib/screens/character/tabs/persona_tab.dart`
- [x] `lib/screens/character/tabs/lorebook_tab.dart`
- [ ] `lib/screens/character/tabs/cover_image_tab.dart`
- [ ] `lib/screens/character/tabs/detail_settings_tab.dart`

### CommonDialog (22개 파일)
- [ ] 모든 AlertDialog 교체
- [ ] 모든 SnackBar 교체
- [x] `lib/screens/character/character_screen.dart` (완료)
- [x] `lib/screens/character/tabs/lorebook_tab.dart` (완료)

### CommonTextField (11개)
- [ ] 모든 TextField 스타일 통일

---

## 🎓 참고 자료

- **UIConstants**: `lib/constants/ui_constants.dart`
- **위젯 소스**: `lib/widgets/` 디렉토리
- **유틸리티**: `lib/utils/common_dialog.dart`

적용 중 문제가 발생하면 기존 위젯 소스 코드를 참고하세요!
