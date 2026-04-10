import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko')
  ];

  /// No description provided for @navCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터'**
  String get navCharacter;

  /// No description provided for @navChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get navChat;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get commonEdit;

  /// No description provided for @commonMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get commonMore;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'재시도'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get commonDeleteConfirmTitle;

  /// No description provided for @commonDeleteConfirmContent.
  ///
  /// In ko, this message translates to:
  /// **'{itemName}을(를) 삭제하시겠습니까?'**
  String commonDeleteConfirmContent(String itemName);

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get settingsSectionChat;

  /// No description provided for @settingsSectionData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionEtc.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get settingsSectionEtc;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settingsSectionInfo;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트 모드'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeColor.
  ///
  /// In ko, this message translates to:
  /// **'테마 색상'**
  String get settingsThemeColor;

  /// No description provided for @settingsThemeColorDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get settingsThemeColorDefault;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'앱 언어'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAiResponseLanguage.
  ///
  /// In ko, this message translates to:
  /// **'AI 응답 언어'**
  String get settingsAiResponseLanguage;

  /// No description provided for @settingsAiResponseLanguageAuto.
  ///
  /// In ko, this message translates to:
  /// **'앱 언어와 동일'**
  String get settingsAiResponseLanguageAuto;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @settingsApiKey.
  ///
  /// In ko, this message translates to:
  /// **'API 키 등록'**
  String get settingsApiKey;

  /// No description provided for @settingsChatModel.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델'**
  String get settingsChatModel;

  /// No description provided for @settingsTokenizer.
  ///
  /// In ko, this message translates to:
  /// **'토크나이저'**
  String get settingsTokenizer;

  /// No description provided for @settingsChatPrompt.
  ///
  /// In ko, this message translates to:
  /// **'채팅 프롬프트'**
  String get settingsChatPrompt;

  /// No description provided for @settingsAutoSummary.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약'**
  String get settingsAutoSummary;

  /// No description provided for @settingsAutoSummarySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'전역 자동 요약 설정'**
  String get settingsAutoSummarySubtitle;

  /// No description provided for @settingsBackup.
  ///
  /// In ko, this message translates to:
  /// **'백업 및 복구'**
  String get settingsBackup;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기/가져오기'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsStatistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get settingsStatistics;

  /// No description provided for @settingsStatisticsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'날짜별 모델 사용량 및 비용'**
  String get settingsStatisticsSubtitle;

  /// No description provided for @settingsLog.
  ///
  /// In ko, this message translates to:
  /// **'로그'**
  String get settingsLog;

  /// No description provided for @settingsLogSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'API 요청/응답 로그 확인'**
  String get settingsLogSubtitle;

  /// No description provided for @settingsTutorial.
  ///
  /// In ko, this message translates to:
  /// **'초기 설정 다시 진행'**
  String get settingsTutorial;

  /// No description provided for @settingsTutorialSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'API 키 등록 및 모델 설정 튜토리얼'**
  String get settingsTutorialSubtitle;

  /// No description provided for @settingsAppInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingsAppInfo;

  /// No description provided for @settingsAppInfoSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String settingsAppInfoSubtitle(String version);

  /// No description provided for @settingsTermsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get settingsTermsOfService;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsAboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'AI 캐릭터와 대화할 수 있는 앱입니다.'**
  String get settingsAboutDescription;

  /// No description provided for @characterTitle.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터'**
  String get characterTitle;

  /// No description provided for @characterSelectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String characterSelectedCount(int count);

  /// No description provided for @characterEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 없습니다'**
  String get characterEmptyTitle;

  /// No description provided for @characterEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'+ 버튼을 눌러 새 캐릭터를 추가해보세요'**
  String get characterEmptySubtitle;

  /// No description provided for @characterDeleteSelectedTitle.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 삭제'**
  String get characterDeleteSelectedTitle;

  /// No description provided for @characterDeleteSelectedContent.
  ///
  /// In ko, this message translates to:
  /// **'선택한 {count}개의 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.'**
  String characterDeleteSelectedContent(int count);

  /// No description provided for @characterDeleteOneContent.
  ///
  /// In ko, this message translates to:
  /// **'이 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.'**
  String get characterDeleteOneContent;

  /// No description provided for @characterDeletedSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택한 캐릭터가 삭제되었습니다'**
  String get characterDeletedSelected;

  /// No description provided for @characterDeleted.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 삭제되었습니다'**
  String get characterDeleted;

  /// No description provided for @characterDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 삭제에 실패했습니다: {error}'**
  String characterDeleteFailed(String error);

  /// No description provided for @characterCopied.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 복사되었습니다'**
  String get characterCopied;

  /// No description provided for @characterCopyFailed.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 복사에 실패했습니다: {error}'**
  String characterCopyFailed(String error);

  /// No description provided for @characterLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 목록을 불러오는데 실패했습니다: {error}'**
  String characterLoadFailed(String error);

  /// No description provided for @characterReorderFailed.
  ///
  /// In ko, this message translates to:
  /// **'순서 변경에 실패했습니다: {error}'**
  String characterReorderFailed(String error);

  /// No description provided for @characterImportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터를 성공적으로 가져왔습니다'**
  String get characterImportSuccess;

  /// No description provided for @characterImportFailed.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 가져오기 실패: {error}'**
  String characterImportFailed(String error);

  /// No description provided for @characterImport.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get characterImport;

  /// No description provided for @characterViewMode.
  ///
  /// In ko, this message translates to:
  /// **'보기 방식'**
  String get characterViewMode;

  /// No description provided for @characterViewGrid.
  ///
  /// In ko, this message translates to:
  /// **'격자뷰'**
  String get characterViewGrid;

  /// No description provided for @characterViewList.
  ///
  /// In ko, this message translates to:
  /// **'리스트뷰'**
  String get characterViewList;

  /// No description provided for @characterThemeSelect.
  ///
  /// In ko, this message translates to:
  /// **'테마 선택'**
  String get characterThemeSelect;

  /// No description provided for @characterFlanAgentTooltip.
  ///
  /// In ko, this message translates to:
  /// **'Flan Agent'**
  String get characterFlanAgentTooltip;

  /// No description provided for @characterAgentHighlightTooltip.
  ///
  /// In ko, this message translates to:
  /// **'여기를 눌러 캐릭터를 만들어보세요!'**
  String get characterAgentHighlightTooltip;

  /// No description provided for @characterSortLabel.
  ///
  /// In ko, this message translates to:
  /// **'정렬방식: {label}'**
  String characterSortLabel(String label);

  /// No description provided for @characterSortNameAsc.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터명 (오름차순)'**
  String get characterSortNameAsc;

  /// No description provided for @characterSortNameDesc.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터명 (내림차순)'**
  String get characterSortNameDesc;

  /// No description provided for @characterSortUpdatedAtAsc.
  ///
  /// In ko, this message translates to:
  /// **'수정일시 (오름차순)'**
  String get characterSortUpdatedAtAsc;

  /// No description provided for @characterSortUpdatedAtDesc.
  ///
  /// In ko, this message translates to:
  /// **'수정일시 (내림차순)'**
  String get characterSortUpdatedAtDesc;

  /// No description provided for @characterSortCreatedAtAsc.
  ///
  /// In ko, this message translates to:
  /// **'생성일시 (오름차순)'**
  String get characterSortCreatedAtAsc;

  /// No description provided for @characterSortCreatedAtDesc.
  ///
  /// In ko, this message translates to:
  /// **'생성일시 (내림차순)'**
  String get characterSortCreatedAtDesc;

  /// No description provided for @characterSortCustom.
  ///
  /// In ko, this message translates to:
  /// **'사용자 지정'**
  String get characterSortCustom;

  /// No description provided for @chatTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get chatTitle;

  /// No description provided for @chatSelectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String chatSelectedCount(int count);

  /// No description provided for @chatEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅방이 없습니다'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터를 선택하여 새 채팅을 시작해보세요'**
  String get chatEmptySubtitle;

  /// No description provided for @chatNoMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 없습니다'**
  String get chatNoMessages;

  /// No description provided for @chatSortMethod.
  ///
  /// In ko, this message translates to:
  /// **'정렬방식'**
  String get chatSortMethod;

  /// No description provided for @chatSortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 업데이트순'**
  String get chatSortRecent;

  /// No description provided for @chatSortName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get chatSortName;

  /// No description provided for @chatSortMessageCount.
  ///
  /// In ko, this message translates to:
  /// **'메시지 수'**
  String get chatSortMessageCount;

  /// No description provided for @chatRoomDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 삭제'**
  String get chatRoomDeleteTitle;

  /// No description provided for @chatRoomDeleteSelectedContent.
  ///
  /// In ko, this message translates to:
  /// **'선택한 {count}개의 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.'**
  String chatRoomDeleteSelectedContent(int count);

  /// No description provided for @chatRoomDeleteOneContent.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.'**
  String chatRoomDeleteOneContent(String name);

  /// No description provided for @chatRoomDeletedSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택한 채팅방이 삭제되었습니다'**
  String get chatRoomDeletedSelected;

  /// No description provided for @chatRoomDeleted.
  ///
  /// In ko, this message translates to:
  /// **'채팅방이 삭제되었습니다'**
  String get chatRoomDeleted;

  /// No description provided for @chatRoomDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 삭제 중 오류가 발생했습니다'**
  String get chatRoomDeleteFailed;

  /// No description provided for @chatRoomRenameTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 이름 수정'**
  String get chatRoomRenameTitle;

  /// No description provided for @chatRoomRenameHint.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 이름'**
  String get chatRoomRenameHint;

  /// No description provided for @chatRoomRenameFailed.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 이름 수정 중 오류가 발생했습니다'**
  String get chatRoomRenameFailed;

  /// No description provided for @chatDateToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get chatDateToday;

  /// No description provided for @chatDateYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get chatDateYesterday;

  /// No description provided for @chatDateDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String chatDateDaysAgo(int days);

  /// No description provided for @chatDateWeeksAgo.
  ///
  /// In ko, this message translates to:
  /// **'{weeks}주 전'**
  String chatDateWeeksAgo(int weeks);

  /// No description provided for @chatDateMonthsAgo.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월 전'**
  String chatDateMonthsAgo(int months);

  /// No description provided for @chatDateYearsAgo.
  ///
  /// In ko, this message translates to:
  /// **'{years}년 전'**
  String chatDateYearsAgo(int years);

  /// No description provided for @tutorialPrevious.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get tutorialPrevious;

  /// No description provided for @tutorialNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get tutorialNext;

  /// No description provided for @tutorialStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get tutorialStart;

  /// No description provided for @tutorialStep.
  ///
  /// In ko, this message translates to:
  /// **'STEP {step}'**
  String tutorialStep(int step);

  /// No description provided for @tutorialWelcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'Flan에 오신 것을 환영합니다'**
  String get tutorialWelcomeTitle;

  /// No description provided for @tutorialWelcomeBody.
  ///
  /// In ko, this message translates to:
  /// **'AI 캐릭터와 대화하고, 나만의 세계를 만들어보세요.\n간단한 초기 설정을 진행하겠습니다.'**
  String get tutorialWelcomeBody;

  /// No description provided for @tutorialApiKeyTitle.
  ///
  /// In ko, this message translates to:
  /// **'API 키 등록'**
  String get tutorialApiKeyTitle;

  /// No description provided for @tutorialApiKeyDesc.
  ///
  /// In ko, this message translates to:
  /// **'AI 모델을 사용하기 위해 API 키가 필요합니다.\n사용할 서비스를 선택하고 키를 등록해주세요.'**
  String get tutorialApiKeyDesc;

  /// No description provided for @tutorialApiKeyHint.
  ///
  /// In ko, this message translates to:
  /// **'API 키를 입력해주세요'**
  String get tutorialApiKeyHint;

  /// No description provided for @tutorialApiKeyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'API 키를 입력해주세요'**
  String get tutorialApiKeyEmpty;

  /// No description provided for @tutorialApiKeySaved.
  ///
  /// In ko, this message translates to:
  /// **'{provider} API 키가 저장되었습니다'**
  String tutorialApiKeySaved(String provider);

  /// No description provided for @tutorialVertexSaved.
  ///
  /// In ko, this message translates to:
  /// **'Vertex AI 서비스 계정이 등록되었습니다'**
  String get tutorialVertexSaved;

  /// No description provided for @tutorialApiKeySaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'API 키 저장 실패: {error}'**
  String tutorialApiKeySaveFailed(String error);

  /// No description provided for @tutorialVertexImport.
  ///
  /// In ko, this message translates to:
  /// **'서비스 계정 JSON 파일 가져오기'**
  String get tutorialVertexImport;

  /// No description provided for @tutorialVertexValidationFailed.
  ///
  /// In ko, this message translates to:
  /// **'서비스 계정 검증 실패'**
  String get tutorialVertexValidationFailed;

  /// No description provided for @tutorialJsonReadFailed.
  ///
  /// In ko, this message translates to:
  /// **'JSON 파일 읽기 실패: {error}'**
  String tutorialJsonReadFailed(String error);

  /// No description provided for @tutorialReRegister.
  ///
  /// In ko, this message translates to:
  /// **'다시 등록'**
  String get tutorialReRegister;

  /// No description provided for @tutorialReInput.
  ///
  /// In ko, this message translates to:
  /// **'다시 입력'**
  String get tutorialReInput;

  /// No description provided for @tutorialModelTitle.
  ///
  /// In ko, this message translates to:
  /// **'모델 설정'**
  String get tutorialModelTitle;

  /// No description provided for @tutorialModelDesc.
  ///
  /// In ko, this message translates to:
  /// **'채팅과 보조 기능에 사용할 AI 모델을 선택해주세요.'**
  String get tutorialModelDesc;

  /// No description provided for @tutorialMainModel.
  ///
  /// In ko, this message translates to:
  /// **'주 모델'**
  String get tutorialMainModel;

  /// No description provided for @tutorialSubModel.
  ///
  /// In ko, this message translates to:
  /// **'보조 모델'**
  String get tutorialSubModel;

  /// No description provided for @tutorialMainDescGemini.
  ///
  /// In ko, this message translates to:
  /// **'채팅에 사용되는 모델입니다. Gemini 3.1 Pro 추천'**
  String get tutorialMainDescGemini;

  /// No description provided for @tutorialSubDescGemini.
  ///
  /// In ko, this message translates to:
  /// **'요약, SNS, 뉴스 기능 등에 사용됩니다. Gemini 3 Flash 추천'**
  String get tutorialSubDescGemini;

  /// No description provided for @tutorialMainDescOpenai.
  ///
  /// In ko, this message translates to:
  /// **'채팅에 사용되는 모델입니다. GPT-5.4 추천'**
  String get tutorialMainDescOpenai;

  /// No description provided for @tutorialSubDescOpenai.
  ///
  /// In ko, this message translates to:
  /// **'요약, SNS, 뉴스 기능 등에 사용됩니다. GPT-5.4 Mini 추천'**
  String get tutorialSubDescOpenai;

  /// No description provided for @tutorialMainDescAnthropic.
  ///
  /// In ko, this message translates to:
  /// **'채팅에 사용되는 모델입니다. Claude Sonnet 4.6 추천'**
  String get tutorialMainDescAnthropic;

  /// No description provided for @tutorialSubDescAnthropic.
  ///
  /// In ko, this message translates to:
  /// **'요약, SNS, 뉴스 기능 등에 사용됩니다. Claude Haiku 4.5 추천'**
  String get tutorialSubDescAnthropic;

  /// No description provided for @tutorialModelRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get tutorialModelRecommended;

  /// No description provided for @tutorialCompleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정이 완료되었습니다!'**
  String get tutorialCompleteTitle;

  /// No description provided for @tutorialCompleteSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이제 캐릭터를 만들어볼까요?'**
  String get tutorialCompleteSubtitle;

  /// No description provided for @tutorialAgentBoxTitle.
  ///
  /// In ko, this message translates to:
  /// **'Flan Agent'**
  String get tutorialAgentBoxTitle;

  /// No description provided for @tutorialAgentBoxSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 탭 상단의 빛나는 아이콘을 눌러보세요'**
  String get tutorialAgentBoxSubtitle;

  /// No description provided for @tutorialAgentBoxBody.
  ///
  /// In ko, this message translates to:
  /// **'Agent에게 원하는 캐릭터를 만들어달라고 말해보세요!\n\"판타지 세계의 엘프 마법사를 만들어줘\" 같이 자유롭게 요청하면 됩니다.'**
  String get tutorialAgentBoxBody;

  /// No description provided for @tutorialHelpGoogleAi.
  ///
  /// In ko, this message translates to:
  /// **'Google AI Studio API 키 발급'**
  String get tutorialHelpGoogleAi;

  /// No description provided for @tutorialHelpVertex.
  ///
  /// In ko, this message translates to:
  /// **'Vertex AI 서비스 계정 설정'**
  String get tutorialHelpVertex;

  /// No description provided for @tutorialHelpOpenai.
  ///
  /// In ko, this message translates to:
  /// **'OpenAI API 키 발급'**
  String get tutorialHelpOpenai;

  /// No description provided for @tutorialHelpAnthropic.
  ///
  /// In ko, this message translates to:
  /// **'Anthropic API 키 발급'**
  String get tutorialHelpAnthropic;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
