# UI 표준 가이드

## 텍스트 스타일

### 입력 필드 (TextFormField)

모든 입력 필드의 기본 텍스트 크기는 **`bodyMedium`** 을 사용합니다.

```dart
TextFormField(
  style: Theme.of(context).textTheme.bodyMedium,
  decoration: InputDecoration(
    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
)
```

### Material 3 텍스트 스케일

- `bodyLarge`: 16sp (기본 본문)
- `bodyMedium`: 14sp (입력 필드 기본)
- `bodySmall`: 12sp (작은 텍스트, 카운터 등)

## 입력 필드 스타일

### 테두리

- **기본 모서리**: `BorderRadius.circular(16)`
- **비활성 테두리 색상**: `colorScheme.outline.withOpacity(0.3)`
- **포커스 테두리 색상**: `colorScheme.primary`

### 패딩

- **내부 패딩**: `EdgeInsets.symmetric(horizontal: 18, vertical: 5)`
- **라벨 좌우 여백**: `EdgeInsets.symmetric(horizontal: 5.0)`

### 색상

- **힌트 텍스트**: `colorScheme.onSurfaceVariant`
- **카운터 텍스트**: `textTheme.bodySmall`

## 탭 (TabBar)

- **탭 너비**: 가장 긴 텍스트 기준으로 모든 탭 동일 (예: 80px)
- **스크롤 가능**: `isScrollable: true`
- **정렬**: `tabAlignment: TabAlignment.start`

## FloatingActionButton

- **그림자**: `elevation: 0` (Material 3)
- **위치**: 기본 우하단 (`FloatingActionButtonLocation.endFloat`)
