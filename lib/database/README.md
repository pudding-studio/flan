# Flan 데이터베이스 구조

## 개요
SQLite 기반의 모바일 데이터베이스를 사용하여 캐릭터 데이터를 저장합니다.

## 데이터베이스 스키마

### 1. characters (캐릭터)
캐릭터의 기본 정보를 저장하는 메인 테이블

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INTEGER PK | 자동 증가 |
| name | TEXT | 캐릭터 이름 (필수) |
| creator_notes | TEXT | 제작자 노트 |
| tags | TEXT | 태그 (JSON 배열) |
| description | TEXT | 캐릭터 설명 |
| selected_cover_image_id | TEXT | 선택된 표지 이미지 ID |
| created_at | TEXT | 생성 일시 (ISO 8601) |
| updated_at | TEXT | 수정 일시 (ISO 8601) |
| is_draft | INTEGER | 임시저장 여부 (0/1) |
| sort_order | INTEGER | 정렬 순서 |

### 2. character_book_folders (캐릭터북 폴더)
캐릭터북을 그룹화하는 폴더

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INTEGER PK | 자동 증가 |
| character_id | INTEGER FK | 캐릭터 ID |
| name | TEXT | 폴더명 |
| order | INTEGER | 정렬 순서 |
| is_expanded | INTEGER | 펼침 상태 (0/1) |

### 3. character_books (캐릭터북)
캐릭터의 세계관 정보

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INTEGER PK | 자동 증가 |
| character_id | INTEGER FK | 캐릭터 ID |
| folder_id | INTEGER FK | 폴더 ID (nullable - standalone) |
| name | TEXT | 캐릭터북 이름 |
| order | INTEGER | 정렬 순서 |
| is_expanded | INTEGER | 펼침 상태 (0/1) |
| enabled | TEXT | 활성화 조건 (disabled/keyBased/enabled) |
| keys | TEXT | 활성화 키 (쉼표 구분) |
| key_condition | TEXT | 키 사용 조건 (and/or) |
| insertion_order | INTEGER | 배치 순서 |
| content | TEXT | 캐릭터북 내용 |

### 4. personas (페르소나)
캐릭터의 페르소나 정보

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INTEGER PK | 자동 증가 |
| character_id | INTEGER FK | 캐릭터 ID |
| name | TEXT | 페르소나 이름 |
| order | INTEGER | 정렬 순서 |
| is_expanded | INTEGER | 펼침 상태 (0/1) |
| content | TEXT | 페르소나 내용 |

### 5. start_scenarios (시작설정)
대화의 시작 설정

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INTEGER PK | 자동 증가 |
| character_id | INTEGER FK | 캐릭터 ID |
| name | TEXT | 시작설정 이름 |
| order | INTEGER | 정렬 순서 |
| is_expanded | INTEGER | 펼침 상태 (0/1) |
| start_setting | TEXT | 시작 설정 내용 |
| start_message | TEXT | 시작 메시지 |

### 6. cover_images (표지 이미지)
캐릭터 표지 이미지

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INTEGER PK | 자동 증가 |
| character_id | INTEGER FK | 캐릭터 ID |
| name | TEXT | 이미지 이름 |
| order | INTEGER | 정렬 순서 |
| is_expanded | INTEGER | 펼침 상태 (0/1) |
| image_data | BLOB | 이미지 데이터 |

## 관계
- `characters` 1:N `character_book_folders`
- `characters` 1:N `character_books`
- `character_book_folders` 1:N `character_books`
- `characters` 1:N `personas`
- `characters` 1:N `start_scenarios`
- `characters` 1:N `cover_images`

모든 외래 키는 `ON DELETE CASCADE`로 설정되어 캐릭터 삭제 시 관련 데이터가 자동으로 삭제됩니다.

## 인덱스
성능 향상을 위해 모든 `character_id` 컬럼과 `folder_id`에 인덱스가 생성됩니다.

## 사용 예시

```dart
// 데이터베이스 인스턴스 가져오기
final db = DatabaseHelper.instance;

// 캐릭터 생성
final character = Character(
  name: '홍길동',
  creatorNotes: '조선시대의 의적',
  tags: ['의적', '조선'],
);
final characterId = await db.createCharacter(character);

// 캐릭터 목록 조회
final characters = await db.readAllCharacters();

// 캐릭터 수정
final updatedCharacter = character.copyWith(
  id: characterId,
  name: '홍길동 (수정됨)',
);
await db.updateCharacter(updatedCharacter);

// 캐릭터 삭제 (관련 데이터 모두 삭제됨)
await db.deleteCharacter(characterId);
```
