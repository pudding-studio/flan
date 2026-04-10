// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
}
