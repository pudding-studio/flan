# Flan 릴리즈 노트

## v1.0.0 - 프로모션 첫 단계 릴리즈

### 주요 기능

#### 캐릭터 관리
- 캐릭터 생성, 수정, 삭제 기능
- 캐릭터 표지 이미지 설정
- 캐릭터 설명, 태그 관리
- 캐릭터 목록 그리드/리스트 뷰 전환
- 캐릭터 정렬 기능

#### 캐릭터 북 (로어북)
- 캐릭터 북 폴더 및 항목 관리
- 활성화 조건 설정 (활성화/비활성화/키워드)
- 키워드 기반 활성화 (AND/OR 조건)
- 삽입 순서 설정

#### 페르소나
- 사용자 페르소나 생성 및 관리
- 채팅 시 페르소나 선택 기능

#### 시작 시나리오
- 시작 설정(장면 묘사) 작성
- 시작 메시지(첫인사) 작성
- 여러 시나리오 생성 및 선택

#### 채팅 기능
- AI 캐릭터와 실시간 채팅
- 메시지 수정 및 삭제
- 메시지 재생성 기능
- 연속 메시지 자동 병합
- 채팅방별 토큰 카운트 표시
- 채팅 히스토리 자동 스크롤

#### 프롬프트 템플릿
- 커스텀 프롬프트 템플릿 생성
- 시스템/사용자/캐릭터/채팅 역할 지원
- 프롬프트 항목 드래그 앤 드롭 정렬
- 폴더 구조로 프롬프트 그룹화
- **키워드 치환 시스템**
  - `{{char}}` - 캐릭터 이름
  - `{{char_description}}` - 캐릭터 설명
  - `{{user}}` - 페르소나 이름
  - `{{user_description}}` - 페르소나 설명
  - `{{character_book}}` - 활성화된 캐릭터 북
  - `{{start_setting}}` - 시작 설정
  - `{{start_message}}` - 시작 메시지
- **채팅 히스토리 필터링**
  - 기본 모드: 전체 채팅 히스토리
  - 고급 모드: 최근/중간/오래된 채팅 범위 지정

#### 모델 설정
- Gemini API 연동
- API 키 등록 및 관리
- 생성 파라미터 설정 (Temperature, Top-P, Top-K 등)
- 안전 설정 구성

#### 토크나이저
- 다양한 토크나이저 지원
  - GPT-4o
  - Claude
  - Gemini
  - Llama 3
- 메시지별 토큰 수 계산
- 채팅방 총 토큰 수 표시

#### API 로깅
- API 요청/응답 로그 저장
- 로그 조회 및 상세 보기
- JSON 포맷 지원

#### UI/UX
- Material 3 디자인 시스템
- 다크/라이트 테마 지원
- 공통 위젯 컴포넌트
  - CommonAppBar
  - CommonButton
  - CommonEditText
  - CommonDropdownButton
  - CommonSegmentedButton
  - CommonFilterChip
- 반응형 레이아웃

#### 기타
- Firebase Analytics 연동
- SQLite 로컬 데이터베이스
- 자동 저장 기능

---

### 기술 스택
- Flutter 3.x
- Dart
- SQLite (sqflite)
- Firebase Analytics
- Google Generative AI (Gemini)

### 지원 플랫폼
- Android (minSdk 23)
- iOS

---

*Flan - AI 캐릭터와 대화하세요*
