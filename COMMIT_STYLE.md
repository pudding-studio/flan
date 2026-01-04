# Commit Message Style Guide

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type
커밋의 성격을 나타냅니다:

- **feat**: 새로운 기능 추가
- **fix**: 버그 수정
- **docs**: 문서 수정
- **style**: 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음)
- **refactor**: 코드 리팩토링 (기능 변경 없음)
- **test**: 테스트 코드 추가/수정
- **chore**: 빌드 작업, 패키지 매니저 설정 등
- **perf**: 성능 개선
- **build**: 빌드 시스템 또는 외부 종속성 변경
- **ci**: CI/CD 설정 변경

## Scope (선택사항)
변경된 부분을 나타냅니다:

- **ui**: UI/UX 관련
- **api**: API 관련
- **auth**: 인증/권한 관련
- **db**: 데이터베이스 관련
- **config**: 설정 관련
- **deps**: 의존성 관련

## Subject
- 50자 이내로 작성
- 명령형, 현재 시제 사용 ("added" ❌, "add" ✅)
- 첫 글자는 소문자
- 마침표를 붙이지 않음
- 한글 또는 영어 사용 가능

## Body (선택사항)
- 72자마다 줄바꿈
- "어떻게"보다 "무엇을", "왜"를 설명
- 한 줄 띄우고 작성

## Footer (선택사항)
- Breaking changes: `BREAKING CHANGE:` 로 시작
- Issue 참조: `Closes #123`, `Fixes #456`, `Ref #789`

## Examples

### 기본 커밋
```
feat(ui): 로그인 화면 추가
```

### 상세 커밋
```
feat(auth): 소셜 로그인 기능 구현

Google 및 Apple 로그인을 지원합니다.
- Google Sign-In 패키지 추가
- Apple Sign-In 설정 완료
- 로그인 성공 시 토큰 저장 로직 구현

Closes #42
```

### Breaking Change
```
refactor(api)!: API 엔드포인트 구조 변경

BREAKING CHANGE: 기존 /api/v1 엔드포인트가 /api/v2로 변경되었습니다.
클라이언트 코드에서 엔드포인트 URL을 업데이트해야 합니다.
```

### 버그 수정
```
fix(ui): 다크모드에서 텍스트 색상 오류 수정

Fixes #89
```

### 여러 타입의 작업
```
chore: 프로젝트 초기 설정

- Flutter 프로젝트 생성
- 필요한 패키지 추가
- 폴더 구조 설정
```

## Tips

1. **원자적 커밋**: 하나의 커밋은 하나의 논리적 변경사항만 포함
2. **자주 커밋**: 작은 단위로 자주 커밋
3. **명확한 메시지**: 다른 개발자가 읽었을 때 이해할 수 있도록 작성
4. **일관성 유지**: 팀 내에서 동일한 스타일 유지

## Flutter 프로젝트 특화 Scope

- **widget**: 위젯 관련
- **model**: 데이터 모델 관련
- **provider**: 상태 관리 관련
- **service**: 서비스 레이어 관련
- **util**: 유틸리티 함수 관련
- **route**: 라우팅 관련
- **theme**: 테마/스타일 관련
- **l10n**: 다국어 지원 관련
