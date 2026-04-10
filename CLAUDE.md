# CLAUDE.md

## Git Workflow

- Default branch: `develop`
- Only commit; push only when user explicitly requests
- All commits go to `develop` branch
- No feature branches or PRs

## Release Procedure

릴리즈 요청 시 아래 순서를 반드시 따른다.

### 1. develop에 커밋 & 푸시
```bash
git add <files>
git commit -m "..."
git push origin develop
```

### 2. 버전 업 (`pubspec.yaml`)
```
version: X.X.X+N  →  X.X.X+(N+1)
```
```bash
git add pubspec.yaml
git commit -m "chore: 버전 업 X.X.X+N → X.X.X+(N+1)"
git push origin develop
```

### 3. develop → main 머지 & 푸시
```bash
git checkout main
git merge develop --no-ff -m "chore: develop → main 머지 (vX.X.X+(N+1))"
git push origin main
git checkout develop
```

### 4. 릴리즈 노트 작성

빌드 전, `git log`로 이전 릴리즈 이후 커밋 목록을 확인하고 주요 변경사항을 한국어로 정리한다.

```bash
git log --oneline <이전 버전 태그 또는 커밋>..HEAD
```

형식 예시:
```
v1.0.4+20 릴리즈 노트

✨ 새 기능
- SNS 게시글 즐겨찾기 기능 추가

🛠 개선
- 에이전트 요약 인라인 편집 기능 추가

🐛 버그 수정
- 모델 초기화 버그 수정
```

### 5. AAB 빌드 (릴리즈)
```bash
flutter build appbundle --release --split-debug-info=build/debug-info --obfuscate
```
출력: `build/app/outputs/bundle/release/app-release.aab`

### 6. APK 빌드 (디버그)
```bash
flutter build apk --debug
```
출력: `build/app/outputs/flutter-apk/app-debug.apk`

> 릴리즈 노트는 빌드 산출물과 함께 사용자에게 전달한다.

> `build/debug-info` 폴더는 크래시 스택 트레이스 복원에 필요하므로 보관할 것

## Project Overview

- Flutter-based AI chat app (Android)
- Google Gemini API integration
- SQLite (sqflite) database
- Provider pattern for state management

## Key File Locations

| Purpose | Path |
|---------|------|
| Chat message model | `lib/models/chat/chat_message.dart` |
| Message metadata | `lib/models/chat/chat_message_metadata.dart` |
| Chat room model | `lib/models/chat/chat_room.dart` |
| Chat room screen (main UI) | `lib/screens/chat/chat_room_screen.dart` |
| Database helper | `lib/database/database_helper.dart` |
| Metadata parser (pin/scene logic) | `lib/utils/metadata_parser.dart` |

## Conventions

- **Commit messages**: Korean, use `feat:` / `fix:` / `refactor:` / `chore:` prefixes
- **Metadata tag format**: `【📍|location】`, `【📅|YYYY.MM.DD】`, `【🕰|HH:MM】`
- **Scene tags**: Auto-insert `<N><Info>...</Info>` / `</N>` in message content when pins detected
- **Code comments**: English only
- **Reports/explanations**: Korean

## Internationalization (i18n)

지원 언어: 한국어(`ko`) / 영어(`en`) / 일본어(`ja`)

### 핵심 규칙

- **모든 UI 노출 문자열은 반드시 `AppLocalizations`를 통해 제공**한다. 하드코딩 금지.
  - `Text('확인')` → `Text(l10n.commonConfirm)`
  - `tooltip: '복사'` → `tooltip: l10n.commonCopy`
- **예외 — 다국어화 불필요한 문자열:**
  - 모델·서비스·파서 레이어 (no `BuildContext`): `lib/models/`, `lib/services/`, `lib/utils/`, `lib/database/`
  - AI에게 전달되는 데이터 키 (예: `'정치'`, `'positive'` 등 내부 식별자)
  - `debugPrint` / 로그 문자열

### ARB 파일

| 파일 | 역할 |
|------|------|
| `lib/l10n/app_ko.arb` | 한국어 원본 (template) |
| `lib/l10n/app_en.arb` | 영어 (미번역 항목은 한국어 값 유지, `@@x_todo` 마커) |
| `lib/l10n/app_ja.arb` | 일본어 (동일) |

- 키 추가 시 세 파일 모두 동시에 업데이트, `flutter gen-l10n` 실행
- 키 네이밍: `screenName_widget_purpose` (예: `settings_section_general`, `common_button_confirm`)
- 파라미터 있는 키는 `@key` 메타데이터에 `placeholders` 명시

### 사용 패턴

```dart
// build() 안에서
final l10n = AppLocalizations.of(context);

// 파라미터 없는 키
Text(l10n.commonConfirm)

// 파라미터 있는 키
Text(l10n.diaryTitle(entry.author))
Text(l10n.chatPromptItemCount(items.length))
```

- async 메서드에서 `context`를 사용할 경우, `await` **전에** `l10n`을 캡처한다:
  ```dart
  final l10n = AppLocalizations.of(context);
  final result = await someAsyncOp();
  // l10n 사용 가능
  ```
- 위젯의 default 파라미터가 한국어 하드코딩인 경우, `String? param`으로 nullable화하고 `build()` 안에서 `param ?? l10n.fallbackKey`로 resolve

### 새 기능 작성 시

1. UI 문자열을 먼저 `app_ko.arb`에 추가한 뒤 `app_en.arb`, `app_ja.arb`에도 동일 키 추가
2. `flutter gen-l10n` 실행 후 `AppLocalizations`를 import해서 사용
3. `flutter analyze`로 새 경고 없음 확인

## Coding Principles

1. **Clean Code**: Prioritize self-explanatory code over comments
2. **Testing**: Execute comprehensive testing/verification suite after coding
3. **Single Responsibility Principle (SRP)**: Each module/function has single responsibility
4. **DRY (Don't Repeat Yourself)**: Eliminate logic duplication by extracting into reusable modules/functions
5. **Fail Fast**: Implement explicit exception handling to ensure system reliability
