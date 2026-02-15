# CLAUDE.md

## Git Workflow

- Default branch: `mvp`
- Only commit; push only when user explicitly requests
- Always push directly to `mvp` branch
- No feature branches or PRs

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
- **Metadata tag format**: `[📍|location]`, `[📅|YYYY.MM.DD]`, `[🕰|HH:MM]`
- **Scene tags**: Auto-insert `<N><Info>...</Info>` / `</N>` in message content when pins detected
- **Code comments**: English only
- **Reports/explanations**: Korean

## Coding Principles

1. **Clean Code**: Prioritize self-explanatory code over comments
2. **Testing**: Execute comprehensive testing/verification suite after coding
3. **Single Responsibility Principle (SRP)**: Each module/function has single responsibility
4. **DRY (Don't Repeat Yourself)**: Eliminate logic duplication by extracting into reusable modules/functions
5. **Fail Fast**: Implement explicit exception handling to ensure system reliability
