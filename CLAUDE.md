# CLAUDE.md

## Git Workflow

- 기본 브랜치: `mvp`
- 커밋 및 push는 항상 `mvp` 브랜치에 직접 수행
- 별도 feature 브랜치나 PR 없이 `mvp`로 바로 push

## Project Overview

- Flutter 기반 AI 채팅 앱 (Android)
- Google Gemini API 연동
- SQLite(sqflite) 데이터베이스 사용
- Provider 패턴으로 상태 관리

## Key File Locations

| 용도 | 경로 |
|------|------|
| 채팅 메시지 모델 | `lib/models/chat/chat_message.dart` |
| 메시지 메타데이터 | `lib/models/chat/chat_message_metadata.dart` |
| 채팅방 모델 | `lib/models/chat/chat_room.dart` |
| 채팅방 화면 (메인 UI) | `lib/screens/chat/chat_room_screen.dart` |
| DB 헬퍼 | `lib/database/database_helper.dart` |
| 메타데이터 파서 (핀/씬 로직) | `lib/utils/metadata_parser.dart` |

## Conventions

- 커밋 메시지: 한국어, `feat:` / `fix:` / `refactor:` / `chore:` 접두사 사용
- 메타데이터 태그 포맷: `[📍|장소]`, `[📅|YYYY.MM.DD]`, `[🕰|HH:MM]`
- Scene 태그: 핀 감지 시 메시지 content에 `<N><Info>...</Info>` / `</N>` 자동 삽입
