# Flan

AI 캐릭터와 대화하는 Flutter 기반 안드로이드 채팅 앱입니다.
Google Gemini API를 활용한 자연스러운 롤플레이 대화 경험을 제공합니다.

---

## 주요 기능

- **캐릭터 관리** — 이름, 설명, 페르소나, 캐릭터북, 표지 이미지 등 세부 설정 지원
- **채팅 룸** — 캐릭터별 독립된 대화 공간, 대화 이력 영구 저장
- **AI 대화** — Google Gemini / Vertex AI 기반 실시간 스트리밍 응답
- **자동 요약** — 긴 대화를 자동으로 요약해 컨텍스트 관리
- **에이전트 모드** — 툴 호출을 통해 캐릭터 및 채팅 데이터를 조회·조작하는 AI 에이전트
- **씬 핀** — 대화 내 위치·날짜·시간 핀을 자동 감지해 씬 구분 삽입
- **포맷 변환** — 외부 캐릭터 카드 형식 가져오기/내보내기

## 기술 스택

| 항목 | 내용 |
|------|------|
| Framework | Flutter 3.x (Dart ^3.7) |
| AI | Google Gemini API, Vertex AI |
| Database | SQLite (sqflite) |
| State Management | Provider |
| Analytics | Firebase Analytics, Crashlytics |
| Platform | Android (min SDK 21) |

## 프로젝트 구조

```
lib/
├── models/          # 데이터 모델 (캐릭터, 채팅 메시지 등)
├── screens/         # UI 화면 (캐릭터, 채팅, 에이전트, 설정)
├── services/        # 비즈니스 로직 (AI, 에이전트, 요약)
├── database/        # SQLite 데이터베이스 헬퍼
├── utils/           # 유틸리티 (메타데이터 파서 등)
└── widgets/         # 재사용 가능한 위젯
assets/
└── defaults/        # 기본 캐릭터, 프롬프트 템플릿
```

## 시작하기

### 필수 조건

- Flutter SDK ^3.7.2
- Android Studio 또는 VS Code
- Google Gemini API 키 (또는 Vertex AI 설정)

### 실행

```bash
flutter pub get
flutter run
```

### 릴리즈 빌드 (AAB)

```bash
flutter build appbundle --release
```

디버그 심볼 포함 빌드:

```bash
flutter build appbundle --release \
  --split-debug-info=build/debug-symbols \
  --obfuscate
```

---

## 라이선스

이 프로젝트는 [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)](LICENSE) 라이선스 하에 배포됩니다.

- **공유** — 어떤 매체나 형식으로든 복제 및 재배포 가능
- **변경** — 리믹스, 변형, 2차 저작물 제작 가능
- **단, 다음 조건을 따라야 합니다:**
  - **저작자 표시 (BY)** — 적절한 출처 및 저작자를 표시해야 합니다
  - **비영리 (NC)** — 상업적 목적으로 사용할 수 없습니다
  - **동일 조건 변경 허락 (SA)** — 2차 저작물은 동일한 라이선스로 배포해야 합니다

자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.
