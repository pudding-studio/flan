// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get navCharacter => '캐릭터';

  @override
  String get navChat => '채팅';

  @override
  String get navSettings => '설정';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '편집';

  @override
  String get commonMore => '더보기';

  @override
  String get commonSave => '저장';

  @override
  String get commonRetry => '재시도';

  @override
  String get commonClose => '닫기';

  @override
  String get commonCopy => '복사';

  @override
  String get commonModify => '수정';

  @override
  String get commonCopyItem => '복사하기';

  @override
  String get commonExport => '내보내기';

  @override
  String get commonReset => '초기화';

  @override
  String get commonDefault => '기본';

  @override
  String get commonLabelName => '이름';

  @override
  String get commonNumberHint => '숫자 입력';

  @override
  String get commonAddItem => '항목 추가';

  @override
  String get commonAddFolder => '폴더 추가';

  @override
  String get commonEmptyList => '항목이 없습니다';

  @override
  String get commonDeleteConfirmTitle => '삭제 확인';

  @override
  String commonDeleteConfirmContent(String itemName) {
    return '$itemName을(를) 삭제하시겠습니까?';
  }

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionGeneral => '일반';

  @override
  String get settingsSectionChat => '채팅';

  @override
  String get settingsSectionData => '데이터';

  @override
  String get settingsSectionEtc => '기타';

  @override
  String get settingsSectionInfo => '정보';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeSystem => '시스템 설정';

  @override
  String get settingsThemeLight => '라이트 모드';

  @override
  String get settingsThemeDark => '다크 모드';

  @override
  String get settingsThemeColor => '테마 색상';

  @override
  String get settingsThemeColorDefault => '기본';

  @override
  String get settingsLanguage => '앱 언어';

  @override
  String get settingsLanguageSystem => '시스템 설정';

  @override
  String get settingsAiResponseLanguage => 'AI 응답 언어';

  @override
  String get settingsAiResponseLanguageAuto => '앱 언어와 동일';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settingsApiKey => 'API 키 등록';

  @override
  String get settingsChatModel => '채팅 모델';

  @override
  String get settingsTokenizer => '토크나이저';

  @override
  String get settingsChatPrompt => '채팅 프롬프트';

  @override
  String get settingsAutoSummary => '자동 요약';

  @override
  String get settingsAutoSummarySubtitle => '전역 자동 요약 설정';

  @override
  String get settingsBackup => '백업 및 복구';

  @override
  String get settingsBackupSubtitle => '데이터 내보내기/가져오기';

  @override
  String get settingsStatistics => '통계';

  @override
  String get settingsStatisticsSubtitle => '날짜별 모델 사용량 및 비용';

  @override
  String get settingsLog => '로그';

  @override
  String get settingsLogSubtitle => 'API 요청/응답 로그 확인';

  @override
  String get settingsTutorial => '초기 설정 다시 진행';

  @override
  String get settingsTutorialSubtitle => 'API 키 등록 및 모델 설정 튜토리얼';

  @override
  String get settingsAppInfo => '앱 정보';

  @override
  String settingsAppInfoSubtitle(String version) {
    return '버전 $version';
  }

  @override
  String get settingsTermsOfService => '이용약관';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsAboutDescription => 'AI 캐릭터와 대화할 수 있는 앱입니다.';

  @override
  String get characterTitle => '캐릭터';

  @override
  String characterSelectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get characterEmptyTitle => '캐릭터가 없습니다';

  @override
  String get characterEmptySubtitle => '+ 버튼을 눌러 새 캐릭터를 추가해보세요';

  @override
  String get characterDeleteSelectedTitle => '캐릭터 삭제';

  @override
  String characterDeleteSelectedContent(int count) {
    return '선택한 $count개의 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.';
  }

  @override
  String get characterDeleteOneContent => '이 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.';

  @override
  String get characterDeletedSelected => '선택한 캐릭터가 삭제되었습니다';

  @override
  String get characterDeleted => '캐릭터가 삭제되었습니다';

  @override
  String characterDeleteFailed(String error) {
    return '캐릭터 삭제에 실패했습니다: $error';
  }

  @override
  String get characterCopied => '캐릭터가 복사되었습니다';

  @override
  String characterCopyFailed(String error) {
    return '캐릭터 복사에 실패했습니다: $error';
  }

  @override
  String characterLoadFailed(String error) {
    return '캐릭터 목록을 불러오는데 실패했습니다: $error';
  }

  @override
  String characterReorderFailed(String error) {
    return '순서 변경에 실패했습니다: $error';
  }

  @override
  String get characterImportSuccess => '캐릭터를 성공적으로 가져왔습니다';

  @override
  String characterImportFailed(String error) {
    return '캐릭터 가져오기 실패: $error';
  }

  @override
  String get characterImport => '가져오기';

  @override
  String get characterViewMode => '보기 방식';

  @override
  String get characterViewGrid => '격자뷰';

  @override
  String get characterViewList => '리스트뷰';

  @override
  String get characterThemeSelect => '테마 선택';

  @override
  String get characterFlanAgentTooltip => 'Flan Agent';

  @override
  String get characterAgentHighlightTooltip => '여기를 눌러 캐릭터를 만들어보세요!';

  @override
  String characterSortLabel(String label) {
    return '정렬방식: $label';
  }

  @override
  String get characterSortNameAsc => '캐릭터명 (오름차순)';

  @override
  String get characterSortNameDesc => '캐릭터명 (내림차순)';

  @override
  String get characterSortUpdatedAtAsc => '수정일시 (오름차순)';

  @override
  String get characterSortUpdatedAtDesc => '수정일시 (내림차순)';

  @override
  String get characterSortCreatedAtAsc => '생성일시 (오름차순)';

  @override
  String get characterSortCreatedAtDesc => '생성일시 (내림차순)';

  @override
  String get characterSortCustom => '사용자 지정';

  @override
  String get chatTitle => '채팅';

  @override
  String chatSelectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get chatEmptyTitle => '채팅방이 없습니다';

  @override
  String get chatEmptySubtitle => '캐릭터를 선택하여 새 채팅을 시작해보세요';

  @override
  String get chatNoMessages => '메시지가 없습니다';

  @override
  String get chatSortMethod => '정렬방식';

  @override
  String get chatSortRecent => '최근 업데이트순';

  @override
  String get chatSortName => '이름순';

  @override
  String get chatSortMessageCount => '메시지 수';

  @override
  String get chatRoomDeleteTitle => '채팅방 삭제';

  @override
  String chatRoomDeleteSelectedContent(int count) {
    return '선택한 $count개의 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.';
  }

  @override
  String chatRoomDeleteOneContent(String name) {
    return '\'$name\' 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.';
  }

  @override
  String get chatRoomDeletedSelected => '선택한 채팅방이 삭제되었습니다';

  @override
  String get chatRoomDeleted => '채팅방이 삭제되었습니다';

  @override
  String get chatRoomDeleteFailed => '채팅방 삭제 중 오류가 발생했습니다';

  @override
  String get chatRoomRenameTitle => '채팅방 이름 수정';

  @override
  String get chatRoomRenameHint => '채팅방 이름';

  @override
  String get chatRoomRenameFailed => '채팅방 이름 수정 중 오류가 발생했습니다';

  @override
  String get chatDateToday => '오늘';

  @override
  String get chatDateYesterday => '어제';

  @override
  String chatDateDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String chatDateWeeksAgo(int weeks) {
    return '$weeks주 전';
  }

  @override
  String chatDateMonthsAgo(int months) {
    return '$months개월 전';
  }

  @override
  String chatDateYearsAgo(int years) {
    return '$years년 전';
  }

  @override
  String get tutorialPrevious => '이전';

  @override
  String get tutorialNext => '다음';

  @override
  String get tutorialStart => '시작하기';

  @override
  String tutorialStep(int step) {
    return 'STEP $step';
  }

  @override
  String get tutorialWelcomeTitle => 'Flan에 오신 것을 환영합니다';

  @override
  String get tutorialWelcomeBody => 'AI 캐릭터와 대화하고, 나만의 세계를 만들어보세요.\n간단한 초기 설정을 진행하겠습니다.';

  @override
  String get tutorialApiKeyTitle => 'API 키 등록';

  @override
  String get tutorialApiKeyDesc => 'AI 모델을 사용하기 위해 API 키가 필요합니다.\n사용할 서비스를 선택하고 키를 등록해주세요.';

  @override
  String get tutorialApiKeyHint => 'API 키를 입력해주세요';

  @override
  String get tutorialApiKeyEmpty => 'API 키를 입력해주세요';

  @override
  String tutorialApiKeySaved(String provider) {
    return '$provider API 키가 저장되었습니다';
  }

  @override
  String get tutorialVertexSaved => 'Vertex AI 서비스 계정이 등록되었습니다';

  @override
  String tutorialApiKeySaveFailed(String error) {
    return 'API 키 저장 실패: $error';
  }

  @override
  String get tutorialVertexImport => '서비스 계정 JSON 파일 가져오기';

  @override
  String get tutorialVertexValidationFailed => '서비스 계정 검증 실패';

  @override
  String tutorialJsonReadFailed(String error) {
    return 'JSON 파일 읽기 실패: $error';
  }

  @override
  String get tutorialReRegister => '다시 등록';

  @override
  String get tutorialReInput => '다시 입력';

  @override
  String get tutorialModelTitle => '모델 설정';

  @override
  String get tutorialModelDesc => '채팅과 보조 기능에 사용할 AI 모델을 선택해주세요.';

  @override
  String get tutorialMainModel => '주 모델';

  @override
  String get tutorialSubModel => '보조 모델';

  @override
  String get tutorialMainDescGemini => '채팅에 사용되는 모델입니다. Gemini 3.1 Pro 추천';

  @override
  String get tutorialSubDescGemini => '요약, SNS, 뉴스 기능 등에 사용됩니다. Gemini 3 Flash 추천';

  @override
  String get tutorialMainDescOpenai => '채팅에 사용되는 모델입니다. GPT-5.4 추천';

  @override
  String get tutorialSubDescOpenai => '요약, SNS, 뉴스 기능 등에 사용됩니다. GPT-5.4 Mini 추천';

  @override
  String get tutorialMainDescAnthropic => '채팅에 사용되는 모델입니다. Claude Sonnet 4.6 추천';

  @override
  String get tutorialSubDescAnthropic => '요약, SNS, 뉴스 기능 등에 사용됩니다. Claude Haiku 4.5 추천';

  @override
  String get tutorialModelRecommended => '추천';

  @override
  String get tutorialCompleteTitle => '설정이 완료되었습니다!';

  @override
  String get tutorialCompleteSubtitle => '이제 캐릭터를 만들어볼까요?';

  @override
  String get tutorialAgentBoxTitle => 'Flan Agent';

  @override
  String get tutorialAgentBoxSubtitle => '캐릭터 탭 상단의 빛나는 아이콘을 눌러보세요';

  @override
  String get tutorialAgentBoxBody => 'Agent에게 원하는 캐릭터를 만들어달라고 말해보세요!\n\"판타지 세계의 엘프 마법사를 만들어줘\" 같이 자유롭게 요청하면 됩니다.';

  @override
  String get tutorialHelpGoogleAi => 'Google AI Studio API 키 발급';

  @override
  String get tutorialHelpVertex => 'Vertex AI 서비스 계정 설정';

  @override
  String get tutorialHelpOpenai => 'OpenAI API 키 발급';

  @override
  String get tutorialHelpAnthropic => 'Anthropic API 키 발급';

  @override
  String get drawerTabInfo => '기본 정보';

  @override
  String get drawerTabPersona => '페르소나';

  @override
  String get drawerTabCharacter => '캐릭터 정보';

  @override
  String get drawerTabLorebook => '설정집';

  @override
  String get drawerTabSummary => '요약';

  @override
  String get drawerChatMemo => '채팅 메모';

  @override
  String get drawerMemoHint => '메모를 입력하세요';

  @override
  String get drawerChatSettings => '채팅창 설정';

  @override
  String get drawerModelPreset => '모델설정';

  @override
  String get drawerProvider => '제조사';

  @override
  String get drawerChatModel => '채팅 모델';

  @override
  String get drawerChatPrompt => '채팅 프롬프트';

  @override
  String get drawerNone => '없음';

  @override
  String get drawerPromptPreset => '프롬프트 프리셋';

  @override
  String get drawerShowImages => '이미지 보기';

  @override
  String get drawerNoName => '이름 없음';

  @override
  String get drawerSelectItem => '항목을 선택하세요';

  @override
  String get drawerOther => '기타';

  @override
  String get drawerEnterValue => '값을 입력하세요';

  @override
  String get drawerSelectPersona => '페르소나 선택';

  @override
  String get drawerCreateNewPersona => '+ 새 페르소나 생성';

  @override
  String get drawerNewPersona => '새 페르소나';

  @override
  String get drawerPersonaName => '페르소나 이름';

  @override
  String get drawerPersonaDescription => '페르소나 설명';

  @override
  String get drawerPersonaDescriptionHint => '페르소나 설명을 입력하세요';

  @override
  String get drawerCharacter => '캐릭터';

  @override
  String get drawerCharacterDescriptionHint => '캐릭터 설정을 입력하세요';

  @override
  String get drawerLorebookEmpty => '설정집 항목이 없습니다';

  @override
  String get drawerBookNameHint => '설정 이름';

  @override
  String get drawerBookActivationCondition => '활성화 조건';

  @override
  String get drawerBookSecondaryKey => '두번째 키';

  @override
  String get drawerBookActivationKey => '활성화 키';

  @override
  String get drawerBookKeysHint => '쉼표로 구분하여 입력';

  @override
  String get drawerBookSecondaryKeysHint => '쉼표로 구분하여 입력 (예: 마법, 전투)';

  @override
  String get drawerBookInsertionOrder => '배치 순서';

  @override
  String get drawerBookContent => '내용';

  @override
  String get drawerBookContentHint => '설정 내용을 입력해주세요';

  @override
  String get drawerAutoSummary => '자동 요약';

  @override
  String get drawerAgentMode => '에이전트 모드';

  @override
  String get drawerSummaryMessageCount => '요약 메시지 수';

  @override
  String get drawerMessageCountHint => '메시지 수';

  @override
  String get drawerAutoSummaryList => '자동 요약 목록';

  @override
  String drawerSummaryCount(int count) {
    return '$count개';
  }

  @override
  String get drawerNoSummaries => '자동 요약이 없습니다.\n설정에서 자동 요약을 활성화하세요.';

  @override
  String get drawerSummaryContentHint => '요약 내용';

  @override
  String get drawerGenerating => '생성 중...';

  @override
  String get drawerRegenerate => '재생성';

  @override
  String get drawerActive => '활성';

  @override
  String get drawerInactive => '비활성';

  @override
  String get drawerNameLabel => '이름';

  @override
  String get drawerNameHint => '이름';

  @override
  String get drawerAddSummaryButton => '현재 메시지 기준 요약 추가';

  @override
  String get drawerNoMessages => '메시지가 없습니다';

  @override
  String get drawerNoNewMessages => '요약할 새 메시지가 없습니다';

  @override
  String get drawerSummaryAdded => '요약이 추가되었습니다. 내용을 입력해주세요.';

  @override
  String drawerSummaryAddFailed(String error) {
    return '요약 추가 중 오류가 발생했습니다: $error';
  }

  @override
  String get drawerSummaryRegenerated => '요약이 재생성되었습니다';

  @override
  String drawerSummaryRegenerateFailed(String error) {
    return '요약 재생성 중 오류가 발생했습니다: $error';
  }

  @override
  String get drawerSummaryItemName => '이 요약';

  @override
  String get drawerSummaryDeleted => '요약이 삭제되었습니다';

  @override
  String drawerSummaryDeleteFailed(String error) {
    return '요약 삭제 중 오류가 발생했습니다: $error';
  }

  @override
  String drawerAgentEntryEmpty(String type) {
    return '$type 데이터가 없습니다.\n채팅을 진행하면 자동으로 생성됩니다.';
  }

  @override
  String drawerAgentEntrySaved(String name) {
    return '$name 저장됨';
  }

  @override
  String drawerAgentEntryDeleted(String name) {
    return '$name 삭제됨';
  }

  @override
  String get agentFieldDateRange => '날짜/시간';

  @override
  String get agentFieldCharacters => '등장인물';

  @override
  String get agentFieldCharactersList => '등장인물 (쉼표 구분)';

  @override
  String get agentFieldLocations => '장소';

  @override
  String get agentFieldLocationsList => '장소 (쉼표 구분)';

  @override
  String get agentFieldSummary => '요약';

  @override
  String get agentFieldAppearance => '외형';

  @override
  String get agentFieldPersonality => '성격';

  @override
  String get agentFieldPast => '과거';

  @override
  String get agentFieldAbilities => '능력';

  @override
  String get agentFieldStoryActions => '작중행적';

  @override
  String get agentFieldDialogueStyle => '대사 스타일';

  @override
  String get agentFieldPossessions => '소지품';

  @override
  String get agentFieldPossessionsList => '소지품 (쉼표 구분)';

  @override
  String get agentFieldParentLocation => '위치';

  @override
  String get agentFieldFeatures => '특징';

  @override
  String get agentFieldAsciiMap => '맵';

  @override
  String get agentFieldRelatedEpisodes => '관련 에피소드';

  @override
  String get agentFieldRelatedEpisodesList => '관련 에피소드 (쉼표 구분)';

  @override
  String get agentFieldKeywords => '키워드';

  @override
  String get agentFieldDatetime => '일시';

  @override
  String get agentFieldOverview => '개요';

  @override
  String get agentFieldResult => '결과';

  @override
  String get chatRoomNotFound => '채팅방을 찾을 수 없습니다';

  @override
  String get chatRoomCannotLoad => '채팅방을 불러올 수 없습니다';

  @override
  String chatRoomMessageSendFailed(String error) {
    return '메시지 전송 중 오류가 발생했습니다: $error';
  }

  @override
  String get chatRoomMessageItemName => '이 메시지';

  @override
  String get chatRoomMessageDeleted => '메시지가 삭제되었습니다';

  @override
  String get chatRoomMessageDeleteFailed => '메시지 삭제 중 오류가 발생했습니다';

  @override
  String get chatRoomMessageEdited => '메시지가 수정되었습니다';

  @override
  String get chatRoomMessageEditFailed => '메시지 수정 중 오류가 발생했습니다';

  @override
  String chatRoomMessageRetryFailed(String error) {
    return '메시지 재전송 중 오류가 발생했습니다: $error';
  }

  @override
  String chatRoomMessageRegenerateFailed(String error) {
    return '메시지 재생성 중 오류가 발생했습니다: $error';
  }

  @override
  String chatRoomMainModelLoadFailed(String modelId) {
    return '주모델 \'$modelId\'을(를) 불러올 수 없습니다. 채팅 모델 설정에서 다시 선택해주세요.';
  }

  @override
  String chatRoomSubModelLoadFailed(String modelId) {
    return '보조모델 \'$modelId\'을(를) 불러올 수 없습니다. 채팅 모델 설정에서 다시 선택해주세요.';
  }

  @override
  String chatRoomCustomModelLoadFailed(String modelId) {
    return '이 채팅방에 지정된 모델 \'$modelId\'을(를) 불러올 수 없습니다. 채팅방 설정에서 모델을 다시 선택해주세요.';
  }

  @override
  String chatRoomPromptLoadFailed(String promptId) {
    return '채팅 프롬프트(id: $promptId)를 불러올 수 없습니다. 채팅방 설정에서 프롬프트를 다시 선택해주세요.';
  }

  @override
  String get chatRoomTextSettings => '텍스트 설정';

  @override
  String get chatRoomBranchTitle => '분기 생성';

  @override
  String get chatRoomBranchContent => '이 메시지까지의 내용으로 새 분기점을 생성하시겠습니까?';

  @override
  String get chatRoomBranchConfirm => '생성';

  @override
  String get chatRoomBranchCreated => '분기가 생성되었습니다';

  @override
  String get chatRoomBranchFailed => '분기 생성 중 오류가 발생했습니다';

  @override
  String get chatRoomWarningTitle => '주의';

  @override
  String get chatRoomWarningDesc => '모든 AI 응답은 자동 생성되며, 편향적이거나 부정확할 수 있습니다.';

  @override
  String get chatRoomStartSetting => '시작 설정';

  @override
  String get chatRoomNoStats => '통계 정보가 없습니다';

  @override
  String get chatRoomStatsTitle => '응답 통계';

  @override
  String get chatRoomStatModel => '모델';

  @override
  String get chatRoomStatInputTokens => '입력 토큰';

  @override
  String get chatRoomStatCachedTokens => '캐시 토큰';

  @override
  String get chatRoomStatCacheRatio => '캐시 비율';

  @override
  String get chatRoomStatOutputTokens => '출력 토큰';

  @override
  String get chatRoomStatThoughtTokens => '생각 토큰';

  @override
  String get chatRoomStatThoughtRatio => '생각 비율';

  @override
  String get chatRoomStatTotalTokens => '총 토큰';

  @override
  String get chatRoomStatEstimatedCost => '예상 비용';

  @override
  String get chatRoomMessageSearch => '메시지 검색...';

  @override
  String get chatRoomSearchTooltip => '검색';

  @override
  String get chatRoomNewMessages => '새로운 메시지';

  @override
  String get chatRoomGenerating => '메시지 생성 중...';

  @override
  String chatRoomRetrying(int attempt) {
    return '재전송 중($attempt)...';
  }

  @override
  String get chatRoomWaiting => '응답 대기 중...';

  @override
  String get chatRoomSummarizing => '요약 중...';

  @override
  String get chatRoomMessageHint => '메시지를 입력하세요';

  @override
  String get chatRoomDayMon => '월';

  @override
  String get chatRoomDayTue => '화';

  @override
  String get chatRoomDayWed => '수';

  @override
  String get chatRoomDayThu => '목';

  @override
  String get chatRoomDayFri => '금';

  @override
  String get chatRoomDaySat => '토';

  @override
  String get chatRoomDaySun => '일';

  @override
  String get chatRoomDay => '낮';

  @override
  String get chatRoomNight => '밤';

  @override
  String characterEditDataLoadFailed(String error) {
    return '데이터 로드 실패: $error';
  }

  @override
  String get characterEditDraftFoundTitle => '작성 중인 데이터 발견';

  @override
  String characterEditDraftFoundContent(String timestamp) {
    return '저장되지 않은 작성 중인 데이터가 있습니다.\n마지막 작성 시간: $timestamp\n\n불러오시겠습니까?';
  }

  @override
  String get characterEditDraftLoad => '불러오기';

  @override
  String get characterEditJustNow => '방금 전';

  @override
  String characterEditMinutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String characterEditHoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String characterEditDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get characterEditNameRequired => '캐릭터 이름을 입력해주세요';

  @override
  String get characterEditCreated => '캐릭터가 생성되었습니다';

  @override
  String get characterEditUpdated => '캐릭터가 수정되었습니다';

  @override
  String characterEditSaveFailed(String error) {
    return '저장 실패: $error';
  }

  @override
  String get characterEditTitleNew => '캐릭터 만들기';

  @override
  String get characterEditTitleEdit => '캐릭터 수정';

  @override
  String get characterEditTabProfile => '프로필';

  @override
  String get characterEditTabCharacter => '캐릭터설정';

  @override
  String get characterEditTabLorebook => '설정집';

  @override
  String get characterEditTabPersona => '페르소나';

  @override
  String get characterEditTabStartSetting => '시작설정';

  @override
  String get characterEditTabCoverImage => '표지이미지';

  @override
  String get characterEditTabAdditionalImage => '추가이미지';

  @override
  String get characterEditWorldDateTitle => '세계 시작 날짜';

  @override
  String get characterEditWorldDateHelp => '이 캐릭터 세계의 기준 날짜입니다. 프롬프트의 [world_date] 키워드로 사용되며, 뉴스/SNS 생성 시 기준 시간으로 쓰입니다.';

  @override
  String get characterEditWorldDateHint => '날짜를 선택해주세요';

  @override
  String get characterEditWorldDateClear => '날짜 초기화';

  @override
  String get characterEditSnsHelp => '캐릭터의 SNS 게시판 설정을 구성합니다.';

  @override
  String get characterEditSnsBoardHint => '예: 자유게시판, 모험가 광장 등';

  @override
  String get characterEditSnsToneHint => '예: 유머러스하고 친근한 분위기';

  @override
  String get characterEditSnsLanguageHint => '사용자 언어 (현재는 한국어만 지원)';

  @override
  String get characterEditNameLabel => '이름';

  @override
  String get characterEditNameHelpText => '캐릭터의 고유한 이름을 입력해주세요.';

  @override
  String get characterEditNameHintText => '캐릭터의 이름을 입력해주세요.';

  @override
  String get characterEditNicknameLabel => '닉네임';

  @override
  String get characterEditNicknameHelp => '프롬프트에서 char 변수 대신 사용할 호칭입니다. 비워두면 이름이 사용됩니다.';

  @override
  String get characterEditNicknameHint => '캐릭터의 닉네임을 입력해주세요.';

  @override
  String get characterEditTaglineLabel => '한 줄 소개';

  @override
  String get characterEditTaglineHelp => '캐릭터를 간단히 설명하는 한 문장을 작성해주세요.';

  @override
  String get characterEditTaglineHint => '어떤 캐릭터인지 설명할 수 있는 간단한 소개를 입력해주세요.';

  @override
  String get characterEditKeywordsLabel => '키워드';

  @override
  String get characterEditKeywordsHelp => '캐릭터를 나타내는 키워드를 쉼표(,)로 구분하여 입력해주세요.';

  @override
  String get characterEditKeywordsHint => '키워드 입력 예시: 판타지, 남자';

  @override
  String get characterEditWorldSetting => '세계관 설정';

  @override
  String get characterEditWorldSettingHelp => '캐릭터가 속한 세계관이나 배경 설정을 자유롭게 작성해주세요.';

  @override
  String get characterEditWorldSettingHint => '세계관 설정을 입력해주세요.';

  @override
  String get characterExportFormatTitle => '내보내기 형식 선택';

  @override
  String get characterExportFlanFormat => 'Flan 형식';

  @override
  String get characterExportFlanSubtitle => '앱 전용 JSON (이미지 포함)';

  @override
  String get characterExportV2Card => '캐릭터카드 v2';

  @override
  String get characterExportV2Subtitle => 'PNG — 일부 데이터 잘릴 수 있음';

  @override
  String get characterExportV3Card => '캐릭터카드 v3';

  @override
  String characterExportSuccessAndroid(String fileName) {
    return '내보내기 완료: /storage/emulated/0/Download/$fileName';
  }

  @override
  String characterExportSuccessIos(String path) {
    return '내보내기 완료: $path';
  }

  @override
  String get characterExportSaveFailed => '파일 저장에 실패했습니다';

  @override
  String get characterCoverDefault => '표지 1';

  @override
  String characterCopyName(String name) {
    return '$name (복사본)';
  }

  @override
  String get autoSummaryTitle => '자동 요약';

  @override
  String get autoSummarySaveFailed => '저장에 실패했습니다';

  @override
  String autoSummaryExportFailed(String error) {
    return '요약 프롬프트 내보내기 실패: $error';
  }

  @override
  String get autoSummaryResetTitle => '초기화';

  @override
  String get autoSummaryResetContent => '요약 프롬프트를 최신 기본 프롬프트로 되돌리시겠습니까?';

  @override
  String get autoSummaryResetConfirm => '초기화';

  @override
  String get autoSummaryResetSuccess => '요약 프롬프트가 초기화되었습니다';

  @override
  String autoSummaryResetFailed(String error) {
    return '요약 프롬프트 초기화에 실패했습니다: $error';
  }

  @override
  String get autoSummaryInvalidFormat => '올바른 요약 프롬프트 형식이 아닙니다';

  @override
  String get autoSummaryEmptyItems => '프롬프트 항목이 비어있습니다';

  @override
  String get autoSummaryImportSuccess => '요약 프롬프트를 가져왔습니다';

  @override
  String autoSummaryImportFailed(String error) {
    return '요약 프롬프트 가져오기 실패: $error';
  }

  @override
  String get autoSummaryTabBasic => '기본정보';

  @override
  String get autoSummaryTabParameters => '파라미터';

  @override
  String get autoSummaryTabPrompt => '프롬프트';

  @override
  String get autoSummarySection => '자동 요약 설정';

  @override
  String get autoSummaryEnableTitle => '자동 요약';

  @override
  String get autoSummaryEnableSubtitle => '토큰 수 초과 시 자동으로 요약을 생성합니다';

  @override
  String get autoSummaryAgentTitle => '에이전트 모드';

  @override
  String get autoSummaryAgentSubtitle => '구조화된 세계관 데이터를 자동으로 관리합니다';

  @override
  String get autoSummaryModelSection => '요약 모델';

  @override
  String get autoSummaryUseSubModel => '보조 모델 사용';

  @override
  String get autoSummaryUseSubModelSubtitle => '채팅 모델 설정의 보조 모델을 사용합니다';

  @override
  String get autoSummaryStartCondition => '자동 요약 시작 조건';

  @override
  String get autoSummaryTokenHint => '토큰 수를 입력하세요';

  @override
  String get autoSummaryPeriod => '요약 주기';

  @override
  String get autoSummaryMaxResponseSize => '최대 응답 크기';

  @override
  String get autoSummaryMaxResponseHelp => '생성할 수 있는 최대 토큰 수입니다.';

  @override
  String get autoSummaryTemperature => '온도';

  @override
  String get autoSummaryTemperatureHelp => '값이 높을수록 더 창의적이고 다양한 응답을 생성합니다.';

  @override
  String get autoSummaryTopPHelp => '누적 확률 임계값입니다. 값이 낮을수록 더 집중된 응답을 생성합니다.';

  @override
  String get autoSummaryTopKHelp => '고려할 상위 토큰의 수입니다.';

  @override
  String get autoSummaryPresencePenalty => '프리센스 패널티';

  @override
  String get autoSummaryPresencePenaltyHelp => '양수 값은 새로운 주제를 장려하고, 음수 값은 기존 주제에 집중합니다.';

  @override
  String get autoSummaryFrequencyPenalty => '빈도 패널티';

  @override
  String get autoSummaryFrequencyPenaltyHelp => '양수 값은 반복을 줄이고, 음수 값은 반복을 증가시킵니다.';

  @override
  String get autoSummaryPromptHelp => '요약 프롬프트 항목을 구성합니다. \"요약대상\" 역할 위치에 요약할 메시지가 자동으로 삽입됩니다.\n\n길게 눌러 순서를 변경할 수 있습니다.';

  @override
  String get autoSummaryNoItems => '프롬프트 항목이 없습니다';

  @override
  String get autoSummaryAddItem => '항목 추가';

  @override
  String get autoSummaryResetDefault => '기본 프롬프트로 초기화';

  @override
  String get autoSummaryImport => '가져오기';

  @override
  String get autoSummaryExport => '내보내기';

  @override
  String get autoSummaryItemNameHint => '항목 이름 (예: 시스템 설정)';

  @override
  String get autoSummaryItemRole => '역할';

  @override
  String get autoSummaryTargetMessageInfo => '요약할 메시지가 이 위치에 자동으로 삽입됩니다';

  @override
  String get autoSummaryItemPrompt => '프롬프트';

  @override
  String get autoSummaryItemPromptHint => '프롬프트 내용을 입력하세요';

  @override
  String get autoSummaryNoModel => '모델 없음';

  @override
  String get customModelTitle => '커스텀 모델';

  @override
  String get customModelEmpty => '커스텀 제조사가 없습니다';

  @override
  String get customModelAddProvider => '제조사 추가';

  @override
  String get customModelEditProvider => '제조사 수정';

  @override
  String get customModelDeleteProviderTitle => '제조사 삭제';

  @override
  String get customModelDeleteModelTitle => '모델 삭제';

  @override
  String get customModelNoExportable => '내보낼 커스텀 모델이 없습니다';

  @override
  String get customModelSaveFailed => '저장에 실패했습니다';

  @override
  String customModelExportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String customModelImportSuccess(int providerCount, int modelCount) {
    return '제조사 $providerCount개, 모델 $modelCount개를 가져왔습니다';
  }

  @override
  String customModelImportFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String get customModelAddModel => '모델 추가';

  @override
  String get customModelEditModel => '모델 수정';

  @override
  String get customModelProviderUpdated => '제조사가 수정되었습니다';

  @override
  String get customModelProviderAdded => '제조사가 추가되었습니다';

  @override
  String get customModelProviderName => '제조사 이름';

  @override
  String get customModelProviderNameHint => '예: OpenRouter';

  @override
  String get customModelProviderNameRequired => '제조사 이름을 입력해주세요';

  @override
  String get customModelEndpointHint => '예: https://openrouter.ai/api';

  @override
  String get customModelRetrySection => '실패 시 재전송';

  @override
  String get customModelRetryCount => '재전송 횟수';

  @override
  String get customModelEdit => '수정';

  @override
  String get customModelAdd => '추가';

  @override
  String get customModelUpdated => '모델이 수정되었습니다';

  @override
  String get customModelAdded => '모델이 추가되었습니다';

  @override
  String get customModelName => '모델 이름';

  @override
  String get customModelNameHint => '예: GPT-4o';

  @override
  String get customModelNameRequired => '모델 이름을 입력해주세요';

  @override
  String get customModelId => '모델 ID';

  @override
  String get customModelIdHint => '예: openai/gpt-4o';

  @override
  String get customModelIdRequired => '모델 ID를 입력해주세요';

  @override
  String get customModelPriceSection => '가격 (선택)';

  @override
  String customModelDeleteProviderWithModels(String name, int count) {
    return '\'$name\' 제조사와 하위 모델 $count개를 삭제하시겠습니까?';
  }

  @override
  String customModelDeleteProvider(String name) {
    return '\'$name\' 제조사를 삭제하시겠습니까?';
  }

  @override
  String customModelDeleteModel(String name) {
    return '\'$name\' 모델을 삭제하시겠습니까?';
  }

  @override
  String get promptEditDefaultName => '기본';

  @override
  String get promptEditNewFolderName => '새 폴더';

  @override
  String get promptEditDefaultRuleName => '정규식 규칙';

  @override
  String get promptEditDefaultPresetName => '프리셋';

  @override
  String get promptEditDefaultConditionName => '조건';

  @override
  String get promptEditUpdated => '프롬프트가 수정되었습니다';

  @override
  String get promptEditCreated => '프롬프트가 생성되었습니다';

  @override
  String promptEditSaveFailed(String error) {
    return '프롬프트 저장 실패: $error';
  }

  @override
  String get promptEditTitleView => '프롬프트 보기';

  @override
  String get promptEditTitleEdit => '프롬프트 수정';

  @override
  String get promptEditTitleNew => '새 프롬프트';

  @override
  String get promptEditTabBasic => '기본정보';

  @override
  String get promptEditTabParameters => '파라미터';

  @override
  String get promptEditTabPrompt => '프롬프트';

  @override
  String get promptEditTabRegex => '정규식';

  @override
  String get promptEditTabOther => '기타설정';

  @override
  String get promptEditNameLabel => '프롬프트 이름';

  @override
  String get promptEditNameHint => '예: 친근한 도우미, 전문가 모드';

  @override
  String get promptEditNameRequired => '프롬프트 이름을 입력해주세요';

  @override
  String get promptEditDescriptionTitle => '설명';

  @override
  String get promptEditDescriptionHint => '이 프롬프트에 대한 설명을 입력하세요';

  @override
  String get promptEditMaxInputSize => '최대 입력 크기';

  @override
  String get promptEditMaxInputHelp => '입력할 수 있는 최대 토큰 수입니다.';

  @override
  String get promptEditThinkingTokens => '사고토큰';

  @override
  String get promptEditThinkingHelp => '사고에 사용할 토큰 수입니다.';

  @override
  String get promptEditStopStrings => '정지 문자열';

  @override
  String get promptEditStopStringsHint => '문자열 입력 후 추가';

  @override
  String get promptEditThinkingConfig => '사고기능 구성';

  @override
  String get promptEditThinkingTokenCount => '생각토큰 수';

  @override
  String get promptEditThinkingTokenHelp => '생각에 사용할 최대 토큰 수입니다.';

  @override
  String get promptEditThinkingLevel => '생각 수준';

  @override
  String get chatModelTitle => '채팅 모델';

  @override
  String get chatModelTabMain => '주 모델';

  @override
  String get chatModelTabSub => '보조 모델';

  @override
  String get chatModelSubInfo => '보조 모델은 SNS 요약 등에 사용됩니다.\n설정 시 해당 기능들의 기본 모델이 변경됩니다.';

  @override
  String get chatModelProviderSection => '제조사';

  @override
  String get chatModelUsedModelSection => '사용 모델';

  @override
  String get chatModelInfoSection => '모델 정보';

  @override
  String get chatModelManagement => '커스텀 모델 관리';

  @override
  String get chatModelApiKeyDeleteContent => '이 API 키를 삭제하시겠습니까?';

  @override
  String get chatModelVertexValidationFailed => '서비스 계정 검증 실패';

  @override
  String get chatModelNewApiKey => '새 API 키';

  @override
  String get chatModelJsonAdd => 'JSON 추가';

  @override
  String get chatModelKeyAdd => '키 추가';

  @override
  String get chatModelNoApiKey => '등록된 API 키가 없습니다';

  @override
  String get apiKeyMultiInfo => '각 제공사별로 여러 개의 API 키를 등록할 수 있습니다.';

  @override
  String chatPromptListLoadFailed(String error) {
    return '프롬프트 목록을 불러오는데 실패했습니다: $error';
  }

  @override
  String chatPromptSelectFailed(String error) {
    return '프롬프트 선택에 실패했습니다: $error';
  }

  @override
  String get chatPromptDeleted => '프롬프트가 삭제되었습니다';

  @override
  String chatPromptDeleteFailed(String error) {
    return '프롬프트 삭제에 실패했습니다: $error';
  }

  @override
  String get chatPromptDefaultSelect => '기본 프롬프트 선택';

  @override
  String get chatPromptEmpty => '빈 프롬프트';

  @override
  String get chatPromptCopied => '프롬프트가 복사되었습니다';

  @override
  String chatPromptCopyFailed(String error) {
    return '프롬프트 복사에 실패했습니다: $error';
  }

  @override
  String get chatPromptResetTitle => '초기화';

  @override
  String get chatPromptResetContent => '모든 기본 프롬프트를 초기 상태로 되돌리시겠습니까?';

  @override
  String get chatPromptResetSuccess => '기본 프롬프트가 초기화되었습니다';

  @override
  String chatPromptResetFailed(String error) {
    return '기본 프롬프트 초기화에 실패했습니다: $error';
  }

  @override
  String chatPromptExportFailed(String error) {
    return '프롬프트 내보내기 실패: $error';
  }

  @override
  String get chatPromptImportSuccess => '프롬프트가 가져오기 되었습니다';

  @override
  String chatPromptImportFailed(String error) {
    return '프롬프트 가져오기 실패: $error';
  }

  @override
  String get chatPromptListEmpty => '프롬프트가 없습니다';

  @override
  String get communityAnonymous => '익명';

  @override
  String get communityNeedDescription => '캐릭터 설명 또는 요약 내용을 먼저 작성해주세요.';

  @override
  String communityGenerateFailed(String error) {
    return '생성 실패: $error';
  }

  @override
  String communityRegisterFailed(String error) {
    return '등록 실패: $error';
  }

  @override
  String get communityWritePost => '게시글 작성';

  @override
  String get communityNickname => '닉네임';

  @override
  String get communityTitle => '제목';

  @override
  String get communityContent => '내용';

  @override
  String get communityRegister => '등록';

  @override
  String get communityWriteComment => '댓글 작성';

  @override
  String get communityCommentContent => '댓글 내용';

  @override
  String get communityCommentDeleteTitle => '댓글 삭제';

  @override
  String get communityCommentDeleteContent => '이 댓글을 삭제할까요?';

  @override
  String get communityPostDeleteTitle => '게시글 삭제';

  @override
  String get communityPostDeleteContent => '이 게시글을 삭제할까요?';

  @override
  String get communityDefaultName => '자유게시판';

  @override
  String get communitySettingsTooltip => '설정';

  @override
  String get communityRefreshTooltip => '새 게시글 생성';

  @override
  String get communityNoPostsTitle => '아직 게시글이 없습니다';

  @override
  String get communityNoPostsSubtitle => '당겨서 게시글을 새로 불러오세요';

  @override
  String get communityCommentLabel => '댓글 달기';

  @override
  String get communityUsedModelSection => '사용 모델';

  @override
  String get communityModelPreset => '모델설정';

  @override
  String get communityProvider => '제조사';

  @override
  String get communityChatModel => '채팅 모델';

  @override
  String get communitySettingsSection => '커뮤니티 설정';

  @override
  String get communityNameLabel => '커뮤니티 이름';

  @override
  String get communityToneLabel => '커뮤니티 분위기';

  @override
  String get communityLanguageLabel => '사용 언어';

  @override
  String get characterViewTabInfo => '정보';

  @override
  String get characterViewTabChat => '채팅';

  @override
  String get characterViewTagline => '한 줄 소개';

  @override
  String get characterViewKeywords => '키워드';

  @override
  String get characterViewPersona => '페르소나';

  @override
  String get characterViewStartSetting => '시작 설정';

  @override
  String get characterViewStartContext => '시작 상황';

  @override
  String get characterViewStartMessage => '시작 메시지';

  @override
  String get characterViewNewChat => '새 채팅';

  @override
  String get characterViewChatCreateFailed => '채팅방 생성 중 오류가 발생했습니다';

  @override
  String get characterViewNoChats => '채팅방이 없습니다';

  @override
  String get characterViewStartNewChat => '새 채팅을 시작해보세요';

  @override
  String agentChatErrorPrefix(String error) {
    return '오류: $error';
  }

  @override
  String get agentChatResetTitle => '대화 초기화';

  @override
  String get agentChatResetContent => '모든 대화 내용이 삭제됩니다. 계속하시겠습니까?';

  @override
  String get agentChatResetTooltip => '대화 초기화';

  @override
  String get agentChatIntro => '캐릭터 생성, 수정, 편집을 도와드립니다';

  @override
  String get agentChatUserLabel => '나';

  @override
  String get agentChatUsedModel => '사용 모델';

  @override
  String get agentChatModelPreset => '모델설정';

  @override
  String get agentChatProvider => '제조사';

  @override
  String get agentChatModel => '채팅 모델';

  @override
  String get agentChatWaiting => '응답 대기 중...';

  @override
  String get agentChatHint => '메시지를 입력하세요';

  @override
  String diaryGenerateFailed(String error) {
    return '일기 생성 실패: $error';
  }

  @override
  String get diaryGenerateTitle => '일기 생성';

  @override
  String diaryGenerateContent(String date) {
    return '$date의 일기를 생성할까요?';
  }

  @override
  String get diaryDeleteTitle => '일기 삭제';

  @override
  String get diaryDeleteContent => '이 일기를 삭제할까요?';

  @override
  String get diaryRegenerateTitle => '일기 재생성';

  @override
  String diaryRegenerateContent(String date) {
    return '$date의 일기를 모두 삭제하고 다시 생성할까요?';
  }

  @override
  String get diarySettingsTooltip => '설정';

  @override
  String get diaryDaySun => '일';

  @override
  String get diaryDayMon => '월';

  @override
  String get diaryDayTue => '화';

  @override
  String get diaryDayWed => '수';

  @override
  String get diaryDayThu => '목';

  @override
  String get diaryDayFri => '금';

  @override
  String get diaryDaySat => '토';

  @override
  String get diarySelectDate => '날짜를 선택하세요';

  @override
  String get diaryGenerating => '일기를 생성하고 있습니다...';

  @override
  String get diaryNoEntries => '아직 일기가 없습니다';

  @override
  String get diaryRegenerateTooltip => '재생성';

  @override
  String get diaryUsedModel => '사용 모델';

  @override
  String get diaryModelPreset => '모델설정';

  @override
  String get diaryProvider => '제조사';

  @override
  String get diaryChatModel => '채팅 모델';

  @override
  String get diarySettingsSection => '다이어리 설정';

  @override
  String get diaryAutoGenerate => '자동 생성';

  @override
  String get diaryAutoGenerateDesc => '채팅 내 날짜가 변경되면 자동으로 일기를 생성합니다.';

  @override
  String get characterBookInvalidFormat => '올바른 설정집 형식이 아닙니다';

  @override
  String get characterBookNoImport => '가져올 설정이 없습니다';

  @override
  String characterBookImportFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String get characterBookNoExport => '내보낼 설정이 없습니다';

  @override
  String get characterBookSaveFailed => '저장에 실패했습니다';

  @override
  String characterBookExportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get characterBookNewFolder => '새 폴더';

  @override
  String get characterBookNewItem => '새 설정';

  @override
  String get characterBookFolderDeleteTitle => '폴더 삭제';

  @override
  String get characterBookSection => '설정집';

  @override
  String get characterBookSectionHelp => '캐릭터의 세계관과 관련된 정보를 설정집에 추가할 수 있습니다.\n\n길게 눌러 순서를 변경할 수 있습니다.';

  @override
  String get characterBookAddItem => '설정 추가';

  @override
  String get characterBookAddFolder => '폴더 추가';

  @override
  String get characterBookEmpty => '설정집 항목이 없습니다';

  @override
  String get characterBookNameHint => '설정 이름';

  @override
  String get characterBookActivationCondition => '활성화 조건';

  @override
  String get characterBookActivationKey => '활성화 키';

  @override
  String get characterBookKeysHint => '쉼표로 구분하여 입력 (예: 마법, 전투)';

  @override
  String get characterBookSecondaryKey => '두번째 키';

  @override
  String get characterBookInsertionOrder => '배치 순서';

  @override
  String get characterBookContent => '내용';

  @override
  String get characterBookContentHint => '설정 내용을 입력해주세요';

  @override
  String get newsArticleDeleteTitle => '기사 삭제';

  @override
  String get newsArticleDeleteContent => '이 기사를 삭제하시겠습니까?';

  @override
  String get newsEmptyTitle => '아직 기사가 없습니다';

  @override
  String get newsEmptySubtitle => '당겨서 뉴스를 불러오세요';

  @override
  String get newsRefreshTooltip => '새 기사 생성';

  @override
  String get promptItemsTitle => '프롬프트 항목';

  @override
  String get promptItemsTitleHelp => 'AI에게 전달될 프롬프트 항목들을 추가하세요. 순서대로 전달됩니다.\n\n길게 눌러 순서를 변경할 수 있습니다.';

  @override
  String get promptItemsAddItem => '항목 추가';

  @override
  String get promptItemsAddFolder => '폴더 추가';

  @override
  String get promptItemsEmpty => '프롬프트 항목이 없습니다';

  @override
  String get promptItemsNameHint => '항목 이름 (예: 시스템 설정, 캐릭터 성격)';

  @override
  String get promptItemsLabelEnable => '활성화';

  @override
  String get promptItemsLabelRole => '역할';

  @override
  String get promptItemsLabelPrompt => '프롬프트';

  @override
  String get promptItemsPromptHint => 'AI의 역할과 응답 방식을 정의하세요';

  @override
  String get promptItemsConditionSelect => '조건 선택';

  @override
  String get promptItemsConditionSelectHint => '조건을 선택하세요';

  @override
  String get promptItemsConditionNoName => '이름 없음';

  @override
  String get promptItemsConditionValue => '조건 값';

  @override
  String get promptItemsConditionEnabled => '활성화';

  @override
  String get promptItemsConditionDisabled => '비활성화';

  @override
  String get promptItemsSingleSelectItems => '선택 항목';

  @override
  String get promptItemsSingleSelectHint => '항목을 선택하세요';

  @override
  String get promptItemsChatSettings => '설정';

  @override
  String get promptItemsRecentChatCount => '최근 채팅 포함 개수';

  @override
  String get promptItemsRecentChatCountHint => '개수';

  @override
  String get promptItemsChatStartPos => '이전 채팅 시작 위치';

  @override
  String get promptItemsChatStartPosHint => '시작 위치';

  @override
  String get promptItemsChatEndPos => '이전 채팅 마지막 위치';

  @override
  String get promptItemsChatEndPosHint => '마지막 위치';

  @override
  String get promptConditionsTitle => '프롬프트 조건';

  @override
  String get promptConditionsTitleHelp => '프롬프트에 적용할 조건을 설정합니다.\n\n• 토글: ON/OFF 스위치\n• 하나만 선택: 여러 항목 중 하나를 선택\n• 변수 치환: 변수명을 선택한 항목으로 치환';

  @override
  String get promptConditionsAddButton => '조건 추가';

  @override
  String get promptConditionsNewName => '새 조건';

  @override
  String get promptConditionsNameHint => '조건 이름 (예: 말투, 분위기)';

  @override
  String get promptConditionsLabelType => '형태';

  @override
  String get promptConditionsLabelVarName => '변수 이름';

  @override
  String get promptConditionsVarNameHint => '변수 이름';

  @override
  String get promptConditionsLabelOptions => '항목 목록';

  @override
  String get promptConditionsOptionsEmpty => '항목이 없습니다';

  @override
  String get promptConditionsOptionAddHint => '항목 이름 입력';

  @override
  String get promptPresetsTitle => '프롬프트 조건 프리셋';

  @override
  String get promptPresetsTitleHelp => '프롬프트 조건의 값을 미리 설정해둔 프리셋입니다.\n\n채팅 시 프리셋을 선택하면 조건 값이 일괄 적용됩니다.';

  @override
  String get promptPresetsAddButton => '프리셋 추가';

  @override
  String get promptPresetsNewName => '새 프리셋';

  @override
  String get promptPresetsLabelName => '이름';

  @override
  String get promptPresetsNameHint => '프리셋 이름';

  @override
  String get promptPresetsLabelConditions => '조건 목록';

  @override
  String get promptPresetsConditionNoName => '이름 없음';

  @override
  String get promptPresetsSelectHint => '항목을 선택하세요';

  @override
  String get promptPresetsCustomLabel => '기타';

  @override
  String get promptPresetsCustomInputLabel => '직접입력';

  @override
  String get promptPresetsCustomInputHint => '값을 입력하세요';

  @override
  String get promptRegexTitle => '정규식 규칙';

  @override
  String get promptRegexTitleHelp => '정규식(RegExp)을 사용하여 텍스트를 변환합니다.\n\n속성에 따라 적용 시점이 달라집니다:\n• 입력문 수정: 사용자 입력 텍스트에 적용\n• 출력문 수정: AI 응답 텍스트에 적용\n• 전송데이터 수정: API 전송 데이터에 적용\n• 출력화면 수정: 화면 표시 시에만 적용';

  @override
  String get promptRegexEmpty => '정규식 규칙이 없습니다';

  @override
  String promptRegexRuleDefaultName(int index) {
    return '규칙 $index';
  }

  @override
  String get promptRegexNameHint => '규칙 이름 (예: OOC 제거, 태그 변환)';

  @override
  String get promptRegexLabelTarget => '속성';

  @override
  String get promptRegexLabelPattern => '정규식 패턴';

  @override
  String get promptRegexPatternHint => '예: \\(OOC:.*?\\)';

  @override
  String get promptRegexLabelReplacement => '변환 형식';

  @override
  String get promptRegexReplacementHint => '정규식에 매칭된 텍스트가 이 형식으로 변환됩니다\n\n캡처 그룹: \$1, \$2, ...';

  @override
  String get promptRegexAddButton => '규칙 추가';

  @override
  String get backupTitle => '백업 및 복구';

  @override
  String get backupSectionTitle => '백업 생성';

  @override
  String get backupSectionDesc => '캐릭터(이미지 포함), 채팅 기록, 프롬프트, 커스텀 모델, 설정 등 모든 데이터를 하나의 백업 파일로 내보냅니다.';

  @override
  String get backupCreateButton => '백업 파일 생성';

  @override
  String get backupRestoreTitle => '백업 복구';

  @override
  String get backupRestoreDesc => '백업 .zip 파일을 선택하여 데이터를 복원합니다. (기존 .db 파일도 지원)';

  @override
  String get backupRestoreWarning => '주의: 기존 데이터가 모두 삭제됩니다. 복구 후 앱 재시작이 필요합니다.';

  @override
  String get backupRestoreButton => '백업 파일 선택';

  @override
  String get backupProcessing => '처리 중...';

  @override
  String get backupProgressDb => '데이터베이스 준비 중...';

  @override
  String backupProgressFiles(int current, int total) {
    return '파일 압축 중... ($current/$total)';
  }

  @override
  String get backupProgressSaving => '백업 파일 저장 중...';

  @override
  String get backupRestoreProgressReading => '백업 파일 읽는 중...';

  @override
  String backupRestoreProgressFiles(int current, int total) {
    return '파일 복원 중... ($current/$total)';
  }

  @override
  String get backupRestoreProgressDb => '데이터베이스 복원 중...';

  @override
  String backupSuccessDownloads(String fileName) {
    return '백업 완료: Downloads/$fileName';
  }

  @override
  String backupSuccessIos(String fileName) {
    return '백업 완료: $fileName';
  }

  @override
  String get backupSaveFailed => '파일 저장에 실패했습니다';

  @override
  String backupFailed(String error) {
    return '백업 실패: $error';
  }

  @override
  String get backupInvalidFile => '.zip 또는 .db 백업 파일을 선택해주세요';

  @override
  String get backupZipNoDb => 'ZIP 파일에서 backup.db를 찾을 수 없습니다';

  @override
  String get backupRestoreConfirmTitle => '백업 복구';

  @override
  String backupRestoreConfirmContent(String createdAt) {
    return '백업 일시: $createdAt\n\n기존 데이터가 모두 삭제되고 백업 데이터로 대체됩니다.\n계속하시겠습니까?';
  }

  @override
  String get backupRestoreConfirmButton => '복구';

  @override
  String get backupRestoreSuccessTitle => '복구 완료';

  @override
  String get backupRestoreSuccessContent => '백업 데이터가 복구되었습니다.\n변경사항을 완전히 적용하려면 앱을 재시작해주세요.';

  @override
  String backupRestoreFailed(String error) {
    return '복구 실패: $error';
  }

  @override
  String get backupCreatedAtUnknown => '알 수 없음';

  @override
  String get logTitle => 'API 로그';

  @override
  String get logDeleteAllTooltip => '전체 삭제';

  @override
  String get logInfoMessage => 'API 요청/응답 로그를 확인할 수 있습니다.\n7일이 지난 로그는 자동으로 삭제됩니다.';

  @override
  String get logEmpty => '로그가 없습니다';

  @override
  String get logAutoSummaryLabel => '자동 요약';

  @override
  String get logDeleteTitle => '로그 삭제';

  @override
  String get logDeleteContent => '이 로그를 삭제하시겠습니까?';

  @override
  String get logDeleteSuccess => '로그가 삭제되었습니다';

  @override
  String logDeleteFailed(String error) {
    return '로그 삭제 실패: $error';
  }

  @override
  String get logDeleteAllTitle => '전체 로그 삭제';

  @override
  String get logDeleteAllContent => '모든 로그를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get logDeleteAllSuccess => '모든 로그가 삭제되었습니다';

  @override
  String logLoadFailed(String error) {
    return '로그 불러오기 실패: $error';
  }

  @override
  String get logDetailTitle => '로그 상세';

  @override
  String get logDetailInfoSection => '기본 정보';

  @override
  String get logDetailTime => '시간';

  @override
  String get logDetailType => '타입';

  @override
  String get logDetailModel => '모델';

  @override
  String get logDetailChatRoomId => '채팅방 ID';

  @override
  String get logDetailCharacterId => '캐릭터 ID';

  @override
  String get logDetailCopied => '클립보드에 복사되었습니다';

  @override
  String get logDetailFormatLabel => '포맷';

  @override
  String get statisticsTitle => '통계';

  @override
  String get statisticsNoData => '데이터가 없습니다';

  @override
  String get statisticsPeriod7Days => '7일';

  @override
  String get statisticsPeriod30Days => '30일';

  @override
  String get statisticsPeriodAll => '전체';

  @override
  String get statisticsCost => '예상 비용';

  @override
  String get statisticsTokens => '총 토큰';

  @override
  String get statisticsMessages => '메시지';

  @override
  String statisticsDailyTokens(String tokens) {
    return '$tokens 토큰';
  }

  @override
  String statisticsDailyMessages(int count) {
    return '$count개 메시지';
  }

  @override
  String statisticsModelMessages(int count) {
    return '$count개';
  }

  @override
  String statisticsDailyModels(int count) {
    return '$count개 모델';
  }

  @override
  String statisticsDateFormat(String year, String month, String day) {
    return '$year년 $month월 $day일';
  }

  @override
  String get statisticsTokenInput => '입력';

  @override
  String get statisticsTokenOutput => '출력';

  @override
  String get statisticsTokenCached => '캐시';

  @override
  String get statisticsTokenThinking => '사고';

  @override
  String get tokenizerTitle => '토크나이저';

  @override
  String get tokenizerSectionTitle => '토크나이저 선택';

  @override
  String get tokenizerLabel => '토크나이저';

  @override
  String get tokenizerDescription => '토크나이저는 텍스트를 토큰으로 변환하는 방식을 결정합니다. 모델에 따라 적합한 토크나이저가 다를 수 있습니다.';

  @override
  String get profileTabLabelName => '이름';

  @override
  String get profileTabNameHelp => '캐릭터의 고유한 이름을 입력해주세요.';

  @override
  String get profileTabNameHint => '캐릭터의 이름을 입력해주세요.';

  @override
  String get profileTabNameValidation => '캐릭터 이름을 입력해주세요';

  @override
  String get profileTabLabelNickname => '닉네임';

  @override
  String get profileTabNicknameHelp => '프롬프트에서 char 변수 대신 사용할 호칭입니다. 비워두면 이름이 사용됩니다.';

  @override
  String get profileTabNicknameHint => '캐릭터의 닉네임을 입력해주세요.';

  @override
  String get profileTabLabelCreatorNotes => '한 줄 소개';

  @override
  String get profileTabCreatorNotesHelp => '캐릭터를 간단히 설명하는 한 문장을 작성해주세요.';

  @override
  String get profileTabCreatorNotesHint => '어떤 캐릭터인지 설명할 수 있는 간단한 소개를 입력해주세요.';

  @override
  String get profileTabLabelKeywords => '키워드';

  @override
  String get profileTabKeywordsHelp => '캐릭터를 나타내는 키워드를 쉼표(,)로 구분하여 입력해주세요.';

  @override
  String get profileTabKeywordsHint => '키워드 입력 예시: 판타지, 남자';

  @override
  String get startScenarioTitle => '시작설정';

  @override
  String get startScenarioTitleHelp => '대화의 시작 설정 정보를 추가할 수 있습니다.';

  @override
  String get startScenarioEmpty => '시작설정 항목이 없습니다';

  @override
  String get startScenarioAddButton => '시작설정 추가';

  @override
  String get startScenarioNewName => '새 시작설정';

  @override
  String get startScenarioNameHint => '시작설정 이름';

  @override
  String get startScenarioStartSettingLabel => '시작 설정';

  @override
  String get startScenarioStartSettingInfo => '해당 내용은 요약 이전에 삽입되고 삭제되지 않습니다.';

  @override
  String get startScenarioStartSettingHint => '시작 설정 내용을 입력해주세요';

  @override
  String get startScenarioStartMessageLabel => '시작 메시지';

  @override
  String get startScenarioStartMessageHint => '시작 메시지를 입력해주세요';

  @override
  String get personaTitle => '페르소나';

  @override
  String get personaTitleHelp => '캐릭터의 페르소나 정보를 추가할 수 있습니다.';

  @override
  String get personaEmpty => '페르소나 항목이 없습니다';

  @override
  String get personaAddButton => '페르소나 추가';

  @override
  String get personaNewName => '새 페르소나';

  @override
  String get personaNameHint => '페르소나 이름';

  @override
  String get personaContentLabel => '내용';

  @override
  String get personaContentHint => '페르소나 내용을 입력해주세요';

  @override
  String get coverImageTitle => '표지';

  @override
  String get coverImageTitleHelp => '캐릭터의 표지 이미지를 추가할 수 있습니다.';

  @override
  String get coverImageEmpty => '표지 이미지가 없습니다';

  @override
  String get coverImageAddButton => '표지 이미지 추가';

  @override
  String coverImageDefaultName(int index) {
    return '표지 $index';
  }

  @override
  String coverImageSaveError(String error) {
    return '이미지 저장 중 오류가 발생했습니다: $error';
  }

  @override
  String get additionalImageTitle => '추가 이미지';

  @override
  String get additionalImageTitleHelp => '캐릭터에 관련된 참고 이미지를 추가할 수 있습니다.';

  @override
  String get additionalImageEmpty => '추가 이미지가 없습니다';

  @override
  String get additionalImageAddButton => '이미지 추가';

  @override
  String additionalImageDefaultName(int index) {
    return '이미지 $index';
  }

  @override
  String additionalImageSaveError(String error) {
    return '이미지 저장 중 오류가 발생했습니다: $error';
  }

  @override
  String get detailSettingsTitle => '세계관 설정';

  @override
  String get detailSettingsTitleHelp => '캐릭터가 속한 세계관이나 배경 설정을 자유롭게 작성해주세요.';

  @override
  String get detailSettingsHint => '세계관 설정을 입력해주세요.';

  @override
  String get chatBottomPanelTitle => '뷰어';

  @override
  String get chatBottomPanelFontSize => '글자 크기';

  @override
  String get chatBottomPanelLineHeight => '줄 간격';

  @override
  String get chatBottomPanelParagraphSpacing => '문단 간격';

  @override
  String get chatBottomPanelParagraphWidth => '문단 너비';

  @override
  String get chatBottomPanelParagraphAlign => '문단 정렬';

  @override
  String get chatBottomPanelAlignLeft => '왼쪽';

  @override
  String get chatBottomPanelAlignJustify => '양쪽';

  @override
  String get tutorialStepGoogleAiAccess => 'Google AI Studio 접속';

  @override
  String get tutorialStepGoogleAiPayment => '결제 계정 생성 (유료 모델 사용 시 필요)';

  @override
  String get tutorialStepGetApiKey => 'Get API Key 클릭';

  @override
  String get tutorialStepCreateApiKey => 'Create API Key 선택';

  @override
  String get tutorialStepCopyKey => '생성된 키를 복사하여 위에 붙여넣기';

  @override
  String get tutorialStepVertexAccess => 'Google Cloud Console 접속';

  @override
  String get tutorialStepVertexBilling => '결제 계정 생성 및 프로젝트에 연결';

  @override
  String get tutorialStepVertexServiceAccount => 'IAM → 서비스 계정 → 계정 생성';

  @override
  String get tutorialStepVertexRole => 'Vertex AI User 역할 부여';

  @override
  String get tutorialStepVertexCreateKey => '키 만들기 → JSON → 다운로드';

  @override
  String get tutorialStepOpenaiAccess => 'OpenAI Platform 접속';

  @override
  String get tutorialStepApiKeysMenu => 'API Keys 메뉴 선택';

  @override
  String get tutorialStepCreateSecretKey => 'Create new secret key 클릭';

  @override
  String get tutorialStepAnthropicAccess => 'Anthropic Console 접속';

  @override
  String get tutorialStepAnthropicCreate => 'Create Key 클릭';

  @override
  String tutorialModelPrice(String inputPrice, String outputPrice) {
    return '입력 $inputPrice/1M · 출력 $outputPrice/1M';
  }

  @override
  String get legalDocumentKorean => '한국어';

  @override
  String get newsTopicPolitics => '정치';

  @override
  String get newsTopicSociety => '사회';

  @override
  String get newsTopicEntertainment => '연예';

  @override
  String get newsTopicEconomy => '경제';

  @override
  String get newsTopicCulture => '문화';

  @override
  String get toolListCharacters => '캐릭터 목록 조회';

  @override
  String get toolGetCharacter => '캐릭터 상세 조회';

  @override
  String get toolCreateCharacter => '캐릭터 생성';

  @override
  String get toolUpdateCharacter => '캐릭터 수정';

  @override
  String get toolCreatePersona => '페르소나 생성';

  @override
  String get toolUpdatePersona => '페르소나 수정';

  @override
  String get toolDeletePersona => '페르소나 삭제';

  @override
  String get toolCreateStartScenario => '시작 시나리오 생성';

  @override
  String get toolUpdateStartScenario => '시작 시나리오 수정';

  @override
  String get toolDeleteStartScenario => '시작 시나리오 삭제';

  @override
  String get toolCreateCharacterBook => '캐릭터북 생성';

  @override
  String get toolUpdateCharacterBook => '캐릭터북 수정';

  @override
  String get toolDeleteCharacterBook => '캐릭터북 삭제';

  @override
  String apiKeyLoadFailed(String error) {
    return 'API 키 불러오기 실패: $error';
  }

  @override
  String get apiKeyServiceAccountLabel => '(서비스 계정 JSON)';

  @override
  String get apiKeyValidationFailed => 'API 키 검증 실패';

  @override
  String apiKeySaved(String apiKeyType) {
    return '$apiKeyType API 키가 저장되었습니다';
  }

  @override
  String get chatPromptEmptyHint => '+ 버튼을 눌러 새 프롬프트를 추가해보세요';

  @override
  String chatPromptItemCount(int count) {
    return '$count개 항목';
  }

  @override
  String customModelSubtitle(String format, int count) {
    return '$format · $count개 모델';
  }

  @override
  String get agentChatDescription => 'Flan Agent는 캐릭터를 생성하거나 편집할 수 있습니다. 원하는 캐릭터 제작 및 수정을 요청해 보세요.';

  @override
  String diaryTitle(String author) {
    return '$author의 일기';
  }

  @override
  String get characterCardOutfitLabel => '의상 ';

  @override
  String get characterCardMemoLabel => '메모 ';

  @override
  String get modelPresetPrimary => '주 모델';

  @override
  String get modelPresetSecondary => '보조 모델';

  @override
  String get modelPresetCustom => '기타';

  @override
  String get agentEntryTypeEpisode => '요약';

  @override
  String get agentEntryTypeCharacter => '등장인물';

  @override
  String get agentEntryTypeLocation => '지역/장소';

  @override
  String get agentEntryTypeItem => '물품';

  @override
  String get agentEntryTypeEvent => '업적/사건';

  @override
  String get settingsAiResponseLanguageOthers => '기타 (직접 입력)';

  @override
  String get settingsAiResponseLanguageOthersTitle => 'AI 응답 언어 입력';

  @override
  String get settingsAiResponseLanguageOthersHint => '언어 이름 입력 (예: French)';

  @override
  String get settingsAiResponseLanguageOthersLabel => '언어 이름';
}
