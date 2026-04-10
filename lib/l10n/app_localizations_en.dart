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
}
