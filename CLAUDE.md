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

### 4. AAB 빌드 (릴리즈)
```bash
flutter build appbundle --release --split-debug-info=build/debug-info --obfuscate
```
출력: `build/app/outputs/bundle/release/app-release.aab`

### 5. APK 빌드 (디버그)
```bash
flutter build apk --debug
```
출력: `build/app/outputs/flutter-apk/app-debug.apk`

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

## Coding Principles

1. **Clean Code**: Prioritize self-explanatory code over comments
2. **Testing**: Execute comprehensive testing/verification suite after coding
3. **Single Responsibility Principle (SRP)**: Each module/function has single responsibility
4. **DRY (Don't Repeat Yourself)**: Eliminate logic duplication by extracting into reusable modules/functions
5. **Fail Fast**: Implement explicit exception handling to ensure system reliability
