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

  /// No description provided for @drawerTabInfo.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get drawerTabInfo;

  /// No description provided for @drawerTabPersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나'**
  String get drawerTabPersona;

  /// No description provided for @drawerTabCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 정보'**
  String get drawerTabCharacter;

  /// No description provided for @drawerTabLorebook.
  ///
  /// In ko, this message translates to:
  /// **'설정집'**
  String get drawerTabLorebook;

  /// No description provided for @drawerTabSummary.
  ///
  /// In ko, this message translates to:
  /// **'요약'**
  String get drawerTabSummary;

  /// No description provided for @drawerChatMemo.
  ///
  /// In ko, this message translates to:
  /// **'채팅 메모'**
  String get drawerChatMemo;

  /// No description provided for @drawerMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'메모를 입력하세요'**
  String get drawerMemoHint;

  /// No description provided for @drawerChatSettings.
  ///
  /// In ko, this message translates to:
  /// **'채팅창 설정'**
  String get drawerChatSettings;

  /// No description provided for @drawerModelPreset.
  ///
  /// In ko, this message translates to:
  /// **'모델설정'**
  String get drawerModelPreset;

  /// No description provided for @drawerProvider.
  ///
  /// In ko, this message translates to:
  /// **'제조사'**
  String get drawerProvider;

  /// No description provided for @drawerChatModel.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델'**
  String get drawerChatModel;

  /// No description provided for @drawerChatPrompt.
  ///
  /// In ko, this message translates to:
  /// **'채팅 프롬프트'**
  String get drawerChatPrompt;

  /// No description provided for @drawerNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get drawerNone;

  /// No description provided for @drawerPromptPreset.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 프리셋'**
  String get drawerPromptPreset;

  /// No description provided for @drawerShowImages.
  ///
  /// In ko, this message translates to:
  /// **'이미지 보기'**
  String get drawerShowImages;

  /// No description provided for @drawerNoName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get drawerNoName;

  /// No description provided for @drawerSelectItem.
  ///
  /// In ko, this message translates to:
  /// **'항목을 선택하세요'**
  String get drawerSelectItem;

  /// No description provided for @drawerOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get drawerOther;

  /// No description provided for @drawerEnterValue.
  ///
  /// In ko, this message translates to:
  /// **'값을 입력하세요'**
  String get drawerEnterValue;

  /// No description provided for @drawerSelectPersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 선택'**
  String get drawerSelectPersona;

  /// No description provided for @drawerCreateNewPersona.
  ///
  /// In ko, this message translates to:
  /// **'+ 새 페르소나 생성'**
  String get drawerCreateNewPersona;

  /// No description provided for @drawerNewPersona.
  ///
  /// In ko, this message translates to:
  /// **'새 페르소나'**
  String get drawerNewPersona;

  /// No description provided for @drawerPersonaName.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 이름'**
  String get drawerPersonaName;

  /// No description provided for @drawerPersonaDescription.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 설명'**
  String get drawerPersonaDescription;

  /// No description provided for @drawerPersonaDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 설명을 입력하세요'**
  String get drawerPersonaDescriptionHint;

  /// No description provided for @drawerCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터'**
  String get drawerCharacter;

  /// No description provided for @drawerCharacterDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 설정을 입력하세요'**
  String get drawerCharacterDescriptionHint;

  /// No description provided for @drawerLorebookEmpty.
  ///
  /// In ko, this message translates to:
  /// **'설정집 항목이 없습니다'**
  String get drawerLorebookEmpty;

  /// No description provided for @drawerBookNameHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 이름'**
  String get drawerBookNameHint;

  /// No description provided for @drawerBookActivationCondition.
  ///
  /// In ko, this message translates to:
  /// **'활성화 조건'**
  String get drawerBookActivationCondition;

  /// No description provided for @drawerBookSecondaryKey.
  ///
  /// In ko, this message translates to:
  /// **'두번째 키'**
  String get drawerBookSecondaryKey;

  /// No description provided for @drawerBookActivationKey.
  ///
  /// In ko, this message translates to:
  /// **'활성화 키'**
  String get drawerBookActivationKey;

  /// No description provided for @drawerBookKeysHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분하여 입력'**
  String get drawerBookKeysHint;

  /// No description provided for @drawerBookSecondaryKeysHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분하여 입력 (예: 마법, 전투)'**
  String get drawerBookSecondaryKeysHint;

  /// No description provided for @drawerBookInsertionOrder.
  ///
  /// In ko, this message translates to:
  /// **'배치 순서'**
  String get drawerBookInsertionOrder;

  /// No description provided for @drawerBookContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get drawerBookContent;

  /// No description provided for @drawerBookContentHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 내용을 입력해주세요'**
  String get drawerBookContentHint;

  /// No description provided for @drawerAutoSummary.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약'**
  String get drawerAutoSummary;

  /// No description provided for @drawerAgentMode.
  ///
  /// In ko, this message translates to:
  /// **'에이전트 모드'**
  String get drawerAgentMode;

  /// No description provided for @drawerSummaryMessageCount.
  ///
  /// In ko, this message translates to:
  /// **'요약 메시지 수'**
  String get drawerSummaryMessageCount;

  /// No description provided for @drawerMessageCountHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지 수'**
  String get drawerMessageCountHint;

  /// No description provided for @drawerAutoSummaryList.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약 목록'**
  String get drawerAutoSummaryList;

  /// No description provided for @drawerSummaryCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String drawerSummaryCount(int count);

  /// No description provided for @drawerNoSummaries.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약이 없습니다.\n설정에서 자동 요약을 활성화하세요.'**
  String get drawerNoSummaries;

  /// No description provided for @drawerSummaryContentHint.
  ///
  /// In ko, this message translates to:
  /// **'요약 내용'**
  String get drawerSummaryContentHint;

  /// No description provided for @drawerGenerating.
  ///
  /// In ko, this message translates to:
  /// **'생성 중...'**
  String get drawerGenerating;

  /// No description provided for @drawerRegenerate.
  ///
  /// In ko, this message translates to:
  /// **'재생성'**
  String get drawerRegenerate;

  /// No description provided for @drawerActive.
  ///
  /// In ko, this message translates to:
  /// **'활성'**
  String get drawerActive;

  /// No description provided for @drawerInactive.
  ///
  /// In ko, this message translates to:
  /// **'비활성'**
  String get drawerInactive;

  /// No description provided for @drawerNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get drawerNameLabel;

  /// No description provided for @drawerNameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get drawerNameHint;

  /// No description provided for @drawerAddSummaryButton.
  ///
  /// In ko, this message translates to:
  /// **'현재 메시지 기준 요약 추가'**
  String get drawerAddSummaryButton;

  /// No description provided for @drawerNoMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 없습니다'**
  String get drawerNoMessages;

  /// No description provided for @drawerNoNewMessages.
  ///
  /// In ko, this message translates to:
  /// **'요약할 새 메시지가 없습니다'**
  String get drawerNoNewMessages;

  /// No description provided for @drawerSummaryAdded.
  ///
  /// In ko, this message translates to:
  /// **'요약이 추가되었습니다. 내용을 입력해주세요.'**
  String get drawerSummaryAdded;

  /// No description provided for @drawerSummaryAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'요약 추가 중 오류가 발생했습니다: {error}'**
  String drawerSummaryAddFailed(String error);

  /// No description provided for @drawerSummaryRegenerated.
  ///
  /// In ko, this message translates to:
  /// **'요약이 재생성되었습니다'**
  String get drawerSummaryRegenerated;

  /// No description provided for @drawerSummaryRegenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'요약 재생성 중 오류가 발생했습니다: {error}'**
  String drawerSummaryRegenerateFailed(String error);

  /// No description provided for @drawerSummaryItemName.
  ///
  /// In ko, this message translates to:
  /// **'이 요약'**
  String get drawerSummaryItemName;

  /// No description provided for @drawerSummaryDeleted.
  ///
  /// In ko, this message translates to:
  /// **'요약이 삭제되었습니다'**
  String get drawerSummaryDeleted;

  /// No description provided for @drawerSummaryDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'요약 삭제 중 오류가 발생했습니다: {error}'**
  String drawerSummaryDeleteFailed(String error);

  /// No description provided for @drawerAgentEntryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'{type} 데이터가 없습니다.\n채팅을 진행하면 자동으로 생성됩니다.'**
  String drawerAgentEntryEmpty(String type);

  /// No description provided for @drawerAgentEntrySaved.
  ///
  /// In ko, this message translates to:
  /// **'{name} 저장됨'**
  String drawerAgentEntrySaved(String name);

  /// No description provided for @drawerAgentEntryDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{name} 삭제됨'**
  String drawerAgentEntryDeleted(String name);

  /// No description provided for @agentFieldDateRange.
  ///
  /// In ko, this message translates to:
  /// **'날짜/시간'**
  String get agentFieldDateRange;

  /// No description provided for @agentFieldCharacters.
  ///
  /// In ko, this message translates to:
  /// **'등장인물'**
  String get agentFieldCharacters;

  /// No description provided for @agentFieldCharactersList.
  ///
  /// In ko, this message translates to:
  /// **'등장인물 (쉼표 구분)'**
  String get agentFieldCharactersList;

  /// No description provided for @agentFieldLocations.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get agentFieldLocations;

  /// No description provided for @agentFieldLocationsList.
  ///
  /// In ko, this message translates to:
  /// **'장소 (쉼표 구분)'**
  String get agentFieldLocationsList;

  /// No description provided for @agentFieldSummary.
  ///
  /// In ko, this message translates to:
  /// **'요약'**
  String get agentFieldSummary;

  /// No description provided for @agentFieldAppearance.
  ///
  /// In ko, this message translates to:
  /// **'외형'**
  String get agentFieldAppearance;

  /// No description provided for @agentFieldPersonality.
  ///
  /// In ko, this message translates to:
  /// **'성격'**
  String get agentFieldPersonality;

  /// No description provided for @agentFieldPast.
  ///
  /// In ko, this message translates to:
  /// **'과거'**
  String get agentFieldPast;

  /// No description provided for @agentFieldAbilities.
  ///
  /// In ko, this message translates to:
  /// **'능력'**
  String get agentFieldAbilities;

  /// No description provided for @agentFieldStoryActions.
  ///
  /// In ko, this message translates to:
  /// **'작중행적'**
  String get agentFieldStoryActions;

  /// No description provided for @agentFieldDialogueStyle.
  ///
  /// In ko, this message translates to:
  /// **'대사 스타일'**
  String get agentFieldDialogueStyle;

  /// No description provided for @agentFieldPossessions.
  ///
  /// In ko, this message translates to:
  /// **'소지품'**
  String get agentFieldPossessions;

  /// No description provided for @agentFieldPossessionsList.
  ///
  /// In ko, this message translates to:
  /// **'소지품 (쉼표 구분)'**
  String get agentFieldPossessionsList;

  /// No description provided for @agentFieldParentLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get agentFieldParentLocation;

  /// No description provided for @agentFieldFeatures.
  ///
  /// In ko, this message translates to:
  /// **'특징'**
  String get agentFieldFeatures;

  /// No description provided for @agentFieldAsciiMap.
  ///
  /// In ko, this message translates to:
  /// **'맵'**
  String get agentFieldAsciiMap;

  /// No description provided for @agentFieldRelatedEpisodes.
  ///
  /// In ko, this message translates to:
  /// **'관련 에피소드'**
  String get agentFieldRelatedEpisodes;

  /// No description provided for @agentFieldRelatedEpisodesList.
  ///
  /// In ko, this message translates to:
  /// **'관련 에피소드 (쉼표 구분)'**
  String get agentFieldRelatedEpisodesList;

  /// No description provided for @agentFieldKeywords.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get agentFieldKeywords;

  /// No description provided for @agentFieldDatetime.
  ///
  /// In ko, this message translates to:
  /// **'일시'**
  String get agentFieldDatetime;

  /// No description provided for @agentFieldOverview.
  ///
  /// In ko, this message translates to:
  /// **'개요'**
  String get agentFieldOverview;

  /// No description provided for @agentFieldResult.
  ///
  /// In ko, this message translates to:
  /// **'결과'**
  String get agentFieldResult;

  /// No description provided for @chatRoomNotFound.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 찾을 수 없습니다'**
  String get chatRoomNotFound;

  /// No description provided for @chatRoomCannotLoad.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 불러올 수 없습니다'**
  String get chatRoomCannotLoad;

  /// No description provided for @chatRoomMessageSendFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 전송 중 오류가 발생했습니다: {error}'**
  String chatRoomMessageSendFailed(String error);

  /// No description provided for @chatRoomMessageItemName.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지'**
  String get chatRoomMessageItemName;

  /// No description provided for @chatRoomMessageDeleted.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 삭제되었습니다'**
  String get chatRoomMessageDeleted;

  /// No description provided for @chatRoomMessageDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 삭제 중 오류가 발생했습니다'**
  String get chatRoomMessageDeleteFailed;

  /// No description provided for @chatRoomMessageEdited.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 수정되었습니다'**
  String get chatRoomMessageEdited;

  /// No description provided for @chatRoomMessageEditFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 수정 중 오류가 발생했습니다'**
  String get chatRoomMessageEditFailed;

  /// No description provided for @chatRoomMessageRetryFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 재전송 중 오류가 발생했습니다: {error}'**
  String chatRoomMessageRetryFailed(String error);

  /// No description provided for @chatRoomMessageRegenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 재생성 중 오류가 발생했습니다: {error}'**
  String chatRoomMessageRegenerateFailed(String error);

  /// No description provided for @chatRoomTextSettings.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 설정'**
  String get chatRoomTextSettings;

  /// No description provided for @chatRoomBranchTitle.
  ///
  /// In ko, this message translates to:
  /// **'분기 생성'**
  String get chatRoomBranchTitle;

  /// No description provided for @chatRoomBranchContent.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지까지의 내용으로 새 분기점을 생성하시겠습니까?'**
  String get chatRoomBranchContent;

  /// No description provided for @chatRoomBranchConfirm.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get chatRoomBranchConfirm;

  /// No description provided for @chatRoomBranchCreated.
  ///
  /// In ko, this message translates to:
  /// **'분기가 생성되었습니다'**
  String get chatRoomBranchCreated;

  /// No description provided for @chatRoomBranchFailed.
  ///
  /// In ko, this message translates to:
  /// **'분기 생성 중 오류가 발생했습니다'**
  String get chatRoomBranchFailed;

  /// No description provided for @chatRoomWarningTitle.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get chatRoomWarningTitle;

  /// No description provided for @chatRoomWarningDesc.
  ///
  /// In ko, this message translates to:
  /// **'모든 AI 응답은 자동 생성되며, 편향적이거나 부정확할 수 있습니다.'**
  String get chatRoomWarningDesc;

  /// No description provided for @chatRoomStartSetting.
  ///
  /// In ko, this message translates to:
  /// **'시작 설정'**
  String get chatRoomStartSetting;

  /// No description provided for @chatRoomNoStats.
  ///
  /// In ko, this message translates to:
  /// **'통계 정보가 없습니다'**
  String get chatRoomNoStats;

  /// No description provided for @chatRoomStatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'응답 통계'**
  String get chatRoomStatsTitle;

  /// No description provided for @chatRoomStatModel.
  ///
  /// In ko, this message translates to:
  /// **'모델'**
  String get chatRoomStatModel;

  /// No description provided for @chatRoomStatInputTokens.
  ///
  /// In ko, this message translates to:
  /// **'입력 토큰'**
  String get chatRoomStatInputTokens;

  /// No description provided for @chatRoomStatCachedTokens.
  ///
  /// In ko, this message translates to:
  /// **'캐시 토큰'**
  String get chatRoomStatCachedTokens;

  /// No description provided for @chatRoomStatCacheRatio.
  ///
  /// In ko, this message translates to:
  /// **'캐시 비율'**
  String get chatRoomStatCacheRatio;

  /// No description provided for @chatRoomStatOutputTokens.
  ///
  /// In ko, this message translates to:
  /// **'출력 토큰'**
  String get chatRoomStatOutputTokens;

  /// No description provided for @chatRoomStatThoughtTokens.
  ///
  /// In ko, this message translates to:
  /// **'생각 토큰'**
  String get chatRoomStatThoughtTokens;

  /// No description provided for @chatRoomStatThoughtRatio.
  ///
  /// In ko, this message translates to:
  /// **'생각 비율'**
  String get chatRoomStatThoughtRatio;

  /// No description provided for @chatRoomStatTotalTokens.
  ///
  /// In ko, this message translates to:
  /// **'총 토큰'**
  String get chatRoomStatTotalTokens;

  /// No description provided for @chatRoomStatEstimatedCost.
  ///
  /// In ko, this message translates to:
  /// **'예상 비용'**
  String get chatRoomStatEstimatedCost;

  /// No description provided for @chatRoomMessageSearch.
  ///
  /// In ko, this message translates to:
  /// **'메시지 검색...'**
  String get chatRoomMessageSearch;

  /// No description provided for @chatRoomSearchTooltip.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get chatRoomSearchTooltip;

  /// No description provided for @chatRoomNewMessages.
  ///
  /// In ko, this message translates to:
  /// **'새로운 메시지'**
  String get chatRoomNewMessages;

  /// No description provided for @chatRoomGenerating.
  ///
  /// In ko, this message translates to:
  /// **'메시지 생성 중...'**
  String get chatRoomGenerating;

  /// No description provided for @chatRoomRetrying.
  ///
  /// In ko, this message translates to:
  /// **'재전송 중({attempt})...'**
  String chatRoomRetrying(int attempt);

  /// No description provided for @chatRoomWaiting.
  ///
  /// In ko, this message translates to:
  /// **'응답 대기 중...'**
  String get chatRoomWaiting;

  /// No description provided for @chatRoomSummarizing.
  ///
  /// In ko, this message translates to:
  /// **'요약 중...'**
  String get chatRoomSummarizing;

  /// No description provided for @chatRoomMessageHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요'**
  String get chatRoomMessageHint;

  /// No description provided for @chatRoomDayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get chatRoomDayMon;

  /// No description provided for @chatRoomDayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get chatRoomDayTue;

  /// No description provided for @chatRoomDayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get chatRoomDayWed;

  /// No description provided for @chatRoomDayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get chatRoomDayThu;

  /// No description provided for @chatRoomDayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get chatRoomDayFri;

  /// No description provided for @chatRoomDaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get chatRoomDaySat;

  /// No description provided for @chatRoomDaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get chatRoomDaySun;

  /// No description provided for @chatRoomDay.
  ///
  /// In ko, this message translates to:
  /// **'낮'**
  String get chatRoomDay;

  /// No description provided for @chatRoomNight.
  ///
  /// In ko, this message translates to:
  /// **'밤'**
  String get chatRoomNight;

  /// No description provided for @characterEditDataLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'데이터 로드 실패: {error}'**
  String characterEditDataLoadFailed(String error);

  /// No description provided for @characterEditDraftFoundTitle.
  ///
  /// In ko, this message translates to:
  /// **'작성 중인 데이터 발견'**
  String get characterEditDraftFoundTitle;

  /// No description provided for @characterEditDraftFoundContent.
  ///
  /// In ko, this message translates to:
  /// **'저장되지 않은 작성 중인 데이터가 있습니다.\n마지막 작성 시간: {timestamp}\n\n불러오시겠습니까?'**
  String characterEditDraftFoundContent(String timestamp);

  /// No description provided for @characterEditDraftLoad.
  ///
  /// In ko, this message translates to:
  /// **'불러오기'**
  String get characterEditDraftLoad;

  /// No description provided for @characterEditJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get characterEditJustNow;

  /// No description provided for @characterEditMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String characterEditMinutesAgo(int minutes);

  /// No description provided for @characterEditHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String characterEditHoursAgo(int hours);

  /// No description provided for @characterEditDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String characterEditDaysAgo(int days);

  /// No description provided for @characterEditNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 이름을 입력해주세요'**
  String get characterEditNameRequired;

  /// No description provided for @characterEditCreated.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 생성되었습니다'**
  String get characterEditCreated;

  /// No description provided for @characterEditUpdated.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 수정되었습니다'**
  String get characterEditUpdated;

  /// No description provided for @characterEditSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String characterEditSaveFailed(String error);

  /// No description provided for @characterEditTitleNew.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 만들기'**
  String get characterEditTitleNew;

  /// No description provided for @characterEditTitleEdit.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 수정'**
  String get characterEditTitleEdit;

  /// No description provided for @characterEditTabProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get characterEditTabProfile;

  /// No description provided for @characterEditTabCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터설정'**
  String get characterEditTabCharacter;

  /// No description provided for @characterEditTabLorebook.
  ///
  /// In ko, this message translates to:
  /// **'설정집'**
  String get characterEditTabLorebook;

  /// No description provided for @characterEditTabPersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나'**
  String get characterEditTabPersona;

  /// No description provided for @characterEditTabStartSetting.
  ///
  /// In ko, this message translates to:
  /// **'시작설정'**
  String get characterEditTabStartSetting;

  /// No description provided for @characterEditTabCoverImage.
  ///
  /// In ko, this message translates to:
  /// **'표지이미지'**
  String get characterEditTabCoverImage;

  /// No description provided for @characterEditTabAdditionalImage.
  ///
  /// In ko, this message translates to:
  /// **'추가이미지'**
  String get characterEditTabAdditionalImage;

  /// No description provided for @characterEditSnsHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 SNS 게시판 설정을 구성합니다.'**
  String get characterEditSnsHelp;

  /// No description provided for @characterEditSnsBoardHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 자유게시판, 모험가 광장 등'**
  String get characterEditSnsBoardHint;

  /// No description provided for @characterEditSnsToneHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 유머러스하고 친근한 분위기'**
  String get characterEditSnsToneHint;

  /// No description provided for @characterEditSnsLanguageHint.
  ///
  /// In ko, this message translates to:
  /// **'사용자 언어 (현재는 한국어만 지원)'**
  String get characterEditSnsLanguageHint;

  /// No description provided for @characterEditNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get characterEditNameLabel;

  /// No description provided for @characterEditNameHelpText.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 고유한 이름을 입력해주세요.'**
  String get characterEditNameHelpText;

  /// No description provided for @characterEditNameHintText.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 이름을 입력해주세요.'**
  String get characterEditNameHintText;

  /// No description provided for @characterEditNicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get characterEditNicknameLabel;

  /// No description provided for @characterEditNicknameHelp.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트에서 char 변수 대신 사용할 호칭입니다. 비워두면 이름이 사용됩니다.'**
  String get characterEditNicknameHelp;

  /// No description provided for @characterEditNicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 닉네임을 입력해주세요.'**
  String get characterEditNicknameHint;

  /// No description provided for @characterEditTaglineLabel.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개'**
  String get characterEditTaglineLabel;

  /// No description provided for @characterEditTaglineHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터를 간단히 설명하는 한 문장을 작성해주세요.'**
  String get characterEditTaglineHelp;

  /// No description provided for @characterEditTaglineHint.
  ///
  /// In ko, this message translates to:
  /// **'어떤 캐릭터인지 설명할 수 있는 간단한 소개를 입력해주세요.'**
  String get characterEditTaglineHint;

  /// No description provided for @characterEditKeywordsLabel.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get characterEditKeywordsLabel;

  /// No description provided for @characterEditKeywordsHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터를 나타내는 키워드를 쉼표(,)로 구분하여 입력해주세요.'**
  String get characterEditKeywordsHelp;

  /// No description provided for @characterEditKeywordsHint.
  ///
  /// In ko, this message translates to:
  /// **'키워드 입력 예시: 판타지, 남자'**
  String get characterEditKeywordsHint;

  /// No description provided for @characterEditWorldSetting.
  ///
  /// In ko, this message translates to:
  /// **'세계관 설정'**
  String get characterEditWorldSetting;

  /// No description provided for @characterEditWorldSettingHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 속한 세계관이나 배경 설정을 자유롭게 작성해주세요.'**
  String get characterEditWorldSettingHelp;

  /// No description provided for @characterEditWorldSettingHint.
  ///
  /// In ko, this message translates to:
  /// **'세계관 설정을 입력해주세요.'**
  String get characterEditWorldSettingHint;

  /// No description provided for @characterExportFormatTitle.
  ///
  /// In ko, this message translates to:
  /// **'내보내기 형식 선택'**
  String get characterExportFormatTitle;

  /// No description provided for @characterExportFlanFormat.
  ///
  /// In ko, this message translates to:
  /// **'Flan 형식'**
  String get characterExportFlanFormat;

  /// No description provided for @characterExportFlanSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 전용 JSON (이미지 포함)'**
  String get characterExportFlanSubtitle;

  /// No description provided for @characterExportV2Card.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터카드 v2'**
  String get characterExportV2Card;

  /// No description provided for @characterExportV2Subtitle.
  ///
  /// In ko, this message translates to:
  /// **'PNG — 일부 데이터 잘릴 수 있음'**
  String get characterExportV2Subtitle;

  /// No description provided for @characterExportV3Card.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터카드 v3'**
  String get characterExportV3Card;

  /// No description provided for @characterExportSuccessAndroid.
  ///
  /// In ko, this message translates to:
  /// **'내보내기 완료: /storage/emulated/0/Download/{fileName}'**
  String characterExportSuccessAndroid(String fileName);

  /// No description provided for @characterExportSuccessIos.
  ///
  /// In ko, this message translates to:
  /// **'내보내기 완료: {path}'**
  String characterExportSuccessIos(String path);

  /// No description provided for @characterExportSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일 저장에 실패했습니다'**
  String get characterExportSaveFailed;

  /// No description provided for @characterCoverDefault.
  ///
  /// In ko, this message translates to:
  /// **'표지 1'**
  String get characterCoverDefault;

  /// No description provided for @characterCopyName.
  ///
  /// In ko, this message translates to:
  /// **'{name} (복사본)'**
  String characterCopyName(String name);

  /// No description provided for @autoSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약'**
  String get autoSummaryTitle;

  /// No description provided for @autoSummarySaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다'**
  String get autoSummarySaveFailed;

  /// No description provided for @autoSummaryExportFailed.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트 내보내기 실패: {error}'**
  String autoSummaryExportFailed(String error);

  /// No description provided for @autoSummaryResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get autoSummaryResetTitle;

  /// No description provided for @autoSummaryResetContent.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트를 최신 기본 프롬프트로 되돌리시겠습니까?'**
  String get autoSummaryResetContent;

  /// No description provided for @autoSummaryResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get autoSummaryResetConfirm;

  /// No description provided for @autoSummaryResetSuccess.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트가 초기화되었습니다'**
  String get autoSummaryResetSuccess;

  /// No description provided for @autoSummaryResetFailed.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트 초기화에 실패했습니다: {error}'**
  String autoSummaryResetFailed(String error);

  /// No description provided for @autoSummaryInvalidFormat.
  ///
  /// In ko, this message translates to:
  /// **'올바른 요약 프롬프트 형식이 아닙니다'**
  String get autoSummaryInvalidFormat;

  /// No description provided for @autoSummaryEmptyItems.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 항목이 비어있습니다'**
  String get autoSummaryEmptyItems;

  /// No description provided for @autoSummaryImportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트를 가져왔습니다'**
  String get autoSummaryImportSuccess;

  /// No description provided for @autoSummaryImportFailed.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트 가져오기 실패: {error}'**
  String autoSummaryImportFailed(String error);

  /// No description provided for @autoSummaryTabBasic.
  ///
  /// In ko, this message translates to:
  /// **'기본정보'**
  String get autoSummaryTabBasic;

  /// No description provided for @autoSummaryTabParameters.
  ///
  /// In ko, this message translates to:
  /// **'파라미터'**
  String get autoSummaryTabParameters;

  /// No description provided for @autoSummaryTabPrompt.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트'**
  String get autoSummaryTabPrompt;

  /// No description provided for @autoSummarySection.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약 설정'**
  String get autoSummarySection;

  /// No description provided for @autoSummaryEnableTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약'**
  String get autoSummaryEnableTitle;

  /// No description provided for @autoSummaryEnableSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'토큰 수 초과 시 자동으로 요약을 생성합니다'**
  String get autoSummaryEnableSubtitle;

  /// No description provided for @autoSummaryAgentTitle.
  ///
  /// In ko, this message translates to:
  /// **'에이전트 모드'**
  String get autoSummaryAgentTitle;

  /// No description provided for @autoSummaryAgentSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'구조화된 세계관 데이터를 자동으로 관리합니다'**
  String get autoSummaryAgentSubtitle;

  /// No description provided for @autoSummaryModelSection.
  ///
  /// In ko, this message translates to:
  /// **'요약 모델'**
  String get autoSummaryModelSection;

  /// No description provided for @autoSummaryUseSubModel.
  ///
  /// In ko, this message translates to:
  /// **'보조 모델 사용'**
  String get autoSummaryUseSubModel;

  /// No description provided for @autoSummaryUseSubModelSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델 설정의 보조 모델을 사용합니다'**
  String get autoSummaryUseSubModelSubtitle;

  /// No description provided for @autoSummaryStartCondition.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약 시작 조건'**
  String get autoSummaryStartCondition;

  /// No description provided for @autoSummaryTokenHint.
  ///
  /// In ko, this message translates to:
  /// **'토큰 수를 입력하세요'**
  String get autoSummaryTokenHint;

  /// No description provided for @autoSummaryPeriod.
  ///
  /// In ko, this message translates to:
  /// **'요약 주기'**
  String get autoSummaryPeriod;

  /// No description provided for @autoSummaryMaxResponseSize.
  ///
  /// In ko, this message translates to:
  /// **'최대 응답 크기'**
  String get autoSummaryMaxResponseSize;

  /// No description provided for @autoSummaryMaxResponseHelp.
  ///
  /// In ko, this message translates to:
  /// **'생성할 수 있는 최대 토큰 수입니다.'**
  String get autoSummaryMaxResponseHelp;

  /// No description provided for @autoSummaryTemperature.
  ///
  /// In ko, this message translates to:
  /// **'온도'**
  String get autoSummaryTemperature;

  /// No description provided for @autoSummaryTemperatureHelp.
  ///
  /// In ko, this message translates to:
  /// **'값이 높을수록 더 창의적이고 다양한 응답을 생성합니다.'**
  String get autoSummaryTemperatureHelp;

  /// No description provided for @autoSummaryTopPHelp.
  ///
  /// In ko, this message translates to:
  /// **'누적 확률 임계값입니다. 값이 낮을수록 더 집중된 응답을 생성합니다.'**
  String get autoSummaryTopPHelp;

  /// No description provided for @autoSummaryTopKHelp.
  ///
  /// In ko, this message translates to:
  /// **'고려할 상위 토큰의 수입니다.'**
  String get autoSummaryTopKHelp;

  /// No description provided for @autoSummaryPresencePenalty.
  ///
  /// In ko, this message translates to:
  /// **'프리센스 패널티'**
  String get autoSummaryPresencePenalty;

  /// No description provided for @autoSummaryPresencePenaltyHelp.
  ///
  /// In ko, this message translates to:
  /// **'양수 값은 새로운 주제를 장려하고, 음수 값은 기존 주제에 집중합니다.'**
  String get autoSummaryPresencePenaltyHelp;

  /// No description provided for @autoSummaryFrequencyPenalty.
  ///
  /// In ko, this message translates to:
  /// **'빈도 패널티'**
  String get autoSummaryFrequencyPenalty;

  /// No description provided for @autoSummaryFrequencyPenaltyHelp.
  ///
  /// In ko, this message translates to:
  /// **'양수 값은 반복을 줄이고, 음수 값은 반복을 증가시킵니다.'**
  String get autoSummaryFrequencyPenaltyHelp;

  /// No description provided for @autoSummaryPromptHelp.
  ///
  /// In ko, this message translates to:
  /// **'요약 프롬프트 항목을 구성합니다. \"요약대상\" 역할 위치에 요약할 메시지가 자동으로 삽입됩니다.\n\n길게 눌러 순서를 변경할 수 있습니다.'**
  String get autoSummaryPromptHelp;

  /// No description provided for @autoSummaryNoItems.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 항목이 없습니다'**
  String get autoSummaryNoItems;

  /// No description provided for @autoSummaryAddItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get autoSummaryAddItem;

  /// No description provided for @autoSummaryResetDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 프롬프트로 초기화'**
  String get autoSummaryResetDefault;

  /// No description provided for @autoSummaryImport.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get autoSummaryImport;

  /// No description provided for @autoSummaryExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get autoSummaryExport;

  /// No description provided for @autoSummaryItemNameHint.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름 (예: 시스템 설정)'**
  String get autoSummaryItemNameHint;

  /// No description provided for @autoSummaryItemRole.
  ///
  /// In ko, this message translates to:
  /// **'역할'**
  String get autoSummaryItemRole;

  /// No description provided for @autoSummaryTargetMessageInfo.
  ///
  /// In ko, this message translates to:
  /// **'요약할 메시지가 이 위치에 자동으로 삽입됩니다'**
  String get autoSummaryTargetMessageInfo;

  /// No description provided for @autoSummaryItemPrompt.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트'**
  String get autoSummaryItemPrompt;

  /// No description provided for @autoSummaryItemPromptHint.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 내용을 입력하세요'**
  String get autoSummaryItemPromptHint;

  /// No description provided for @autoSummaryNoModel.
  ///
  /// In ko, this message translates to:
  /// **'모델 없음'**
  String get autoSummaryNoModel;

  /// No description provided for @customModelTitle.
  ///
  /// In ko, this message translates to:
  /// **'커스텀 모델'**
  String get customModelTitle;

  /// No description provided for @customModelEmpty.
  ///
  /// In ko, this message translates to:
  /// **'커스텀 제조사가 없습니다'**
  String get customModelEmpty;

  /// No description provided for @customModelAddProvider.
  ///
  /// In ko, this message translates to:
  /// **'제조사 추가'**
  String get customModelAddProvider;

  /// No description provided for @customModelEditProvider.
  ///
  /// In ko, this message translates to:
  /// **'제조사 수정'**
  String get customModelEditProvider;

  /// No description provided for @customModelDeleteProviderTitle.
  ///
  /// In ko, this message translates to:
  /// **'제조사 삭제'**
  String get customModelDeleteProviderTitle;

  /// No description provided for @customModelDeleteModelTitle.
  ///
  /// In ko, this message translates to:
  /// **'모델 삭제'**
  String get customModelDeleteModelTitle;

  /// No description provided for @customModelNoExportable.
  ///
  /// In ko, this message translates to:
  /// **'내보낼 커스텀 모델이 없습니다'**
  String get customModelNoExportable;

  /// No description provided for @customModelSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다'**
  String get customModelSaveFailed;

  /// No description provided for @customModelExportFailed.
  ///
  /// In ko, this message translates to:
  /// **'내보내기 실패: {error}'**
  String customModelExportFailed(String error);

  /// No description provided for @customModelImportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'제조사 {providerCount}개, 모델 {modelCount}개를 가져왔습니다'**
  String customModelImportSuccess(int providerCount, int modelCount);

  /// No description provided for @customModelImportFailed.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 실패: {error}'**
  String customModelImportFailed(String error);

  /// No description provided for @customModelAddModel.
  ///
  /// In ko, this message translates to:
  /// **'모델 추가'**
  String get customModelAddModel;

  /// No description provided for @customModelEditModel.
  ///
  /// In ko, this message translates to:
  /// **'모델 수정'**
  String get customModelEditModel;

  /// No description provided for @customModelProviderUpdated.
  ///
  /// In ko, this message translates to:
  /// **'제조사가 수정되었습니다'**
  String get customModelProviderUpdated;

  /// No description provided for @customModelProviderAdded.
  ///
  /// In ko, this message translates to:
  /// **'제조사가 추가되었습니다'**
  String get customModelProviderAdded;

  /// No description provided for @customModelProviderName.
  ///
  /// In ko, this message translates to:
  /// **'제조사 이름'**
  String get customModelProviderName;

  /// No description provided for @customModelProviderNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: OpenRouter'**
  String get customModelProviderNameHint;

  /// No description provided for @customModelProviderNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'제조사 이름을 입력해주세요'**
  String get customModelProviderNameRequired;

  /// No description provided for @customModelEndpointHint.
  ///
  /// In ko, this message translates to:
  /// **'예: https://openrouter.ai/api'**
  String get customModelEndpointHint;

  /// No description provided for @customModelRetrySection.
  ///
  /// In ko, this message translates to:
  /// **'실패 시 재전송'**
  String get customModelRetrySection;

  /// No description provided for @customModelRetryCount.
  ///
  /// In ko, this message translates to:
  /// **'재전송 횟수'**
  String get customModelRetryCount;

  /// No description provided for @customModelEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get customModelEdit;

  /// No description provided for @customModelAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get customModelAdd;

  /// No description provided for @customModelUpdated.
  ///
  /// In ko, this message translates to:
  /// **'모델이 수정되었습니다'**
  String get customModelUpdated;

  /// No description provided for @customModelAdded.
  ///
  /// In ko, this message translates to:
  /// **'모델이 추가되었습니다'**
  String get customModelAdded;

  /// No description provided for @customModelName.
  ///
  /// In ko, this message translates to:
  /// **'모델 이름'**
  String get customModelName;

  /// No description provided for @customModelNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: GPT-4o'**
  String get customModelNameHint;

  /// No description provided for @customModelNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'모델 이름을 입력해주세요'**
  String get customModelNameRequired;

  /// No description provided for @customModelId.
  ///
  /// In ko, this message translates to:
  /// **'모델 ID'**
  String get customModelId;

  /// No description provided for @customModelIdHint.
  ///
  /// In ko, this message translates to:
  /// **'예: openai/gpt-4o'**
  String get customModelIdHint;

  /// No description provided for @customModelIdRequired.
  ///
  /// In ko, this message translates to:
  /// **'모델 ID를 입력해주세요'**
  String get customModelIdRequired;

  /// No description provided for @customModelPriceSection.
  ///
  /// In ko, this message translates to:
  /// **'가격 (선택)'**
  String get customModelPriceSection;

  /// No description provided for @customModelDeleteProviderWithModels.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 제조사와 하위 모델 {count}개를 삭제하시겠습니까?'**
  String customModelDeleteProviderWithModels(String name, int count);

  /// No description provided for @customModelDeleteProvider.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 제조사를 삭제하시겠습니까?'**
  String customModelDeleteProvider(String name);

  /// No description provided for @customModelDeleteModel.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 모델을 삭제하시겠습니까?'**
  String customModelDeleteModel(String name);

  /// No description provided for @promptEditDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get promptEditDefaultName;

  /// No description provided for @promptEditNewFolderName.
  ///
  /// In ko, this message translates to:
  /// **'새 폴더'**
  String get promptEditNewFolderName;

  /// No description provided for @promptEditDefaultRuleName.
  ///
  /// In ko, this message translates to:
  /// **'정규식 규칙'**
  String get promptEditDefaultRuleName;

  /// No description provided for @promptEditDefaultPresetName.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get promptEditDefaultPresetName;

  /// No description provided for @promptEditDefaultConditionName.
  ///
  /// In ko, this message translates to:
  /// **'조건'**
  String get promptEditDefaultConditionName;

  /// No description provided for @promptEditUpdated.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트가 수정되었습니다'**
  String get promptEditUpdated;

  /// No description provided for @promptEditCreated.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트가 생성되었습니다'**
  String get promptEditCreated;

  /// No description provided for @promptEditSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 저장 실패: {error}'**
  String promptEditSaveFailed(String error);

  /// No description provided for @promptEditTitleView.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 보기'**
  String get promptEditTitleView;

  /// No description provided for @promptEditTitleEdit.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 수정'**
  String get promptEditTitleEdit;

  /// No description provided for @promptEditTitleNew.
  ///
  /// In ko, this message translates to:
  /// **'새 프롬프트'**
  String get promptEditTitleNew;

  /// No description provided for @promptEditTabBasic.
  ///
  /// In ko, this message translates to:
  /// **'기본정보'**
  String get promptEditTabBasic;

  /// No description provided for @promptEditTabParameters.
  ///
  /// In ko, this message translates to:
  /// **'파라미터'**
  String get promptEditTabParameters;

  /// No description provided for @promptEditTabPrompt.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트'**
  String get promptEditTabPrompt;

  /// No description provided for @promptEditTabRegex.
  ///
  /// In ko, this message translates to:
  /// **'정규식'**
  String get promptEditTabRegex;

  /// No description provided for @promptEditTabOther.
  ///
  /// In ko, this message translates to:
  /// **'기타설정'**
  String get promptEditTabOther;

  /// No description provided for @promptEditNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 이름'**
  String get promptEditNameLabel;

  /// No description provided for @promptEditNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 친근한 도우미, 전문가 모드'**
  String get promptEditNameHint;

  /// No description provided for @promptEditNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 이름을 입력해주세요'**
  String get promptEditNameRequired;

  /// No description provided for @promptEditDescriptionTitle.
  ///
  /// In ko, this message translates to:
  /// **'설명'**
  String get promptEditDescriptionTitle;

  /// No description provided for @promptEditDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'이 프롬프트에 대한 설명을 입력하세요'**
  String get promptEditDescriptionHint;

  /// No description provided for @promptEditMaxInputSize.
  ///
  /// In ko, this message translates to:
  /// **'최대 입력 크기'**
  String get promptEditMaxInputSize;

  /// No description provided for @promptEditMaxInputHelp.
  ///
  /// In ko, this message translates to:
  /// **'입력할 수 있는 최대 토큰 수입니다.'**
  String get promptEditMaxInputHelp;

  /// No description provided for @promptEditThinkingTokens.
  ///
  /// In ko, this message translates to:
  /// **'사고토큰'**
  String get promptEditThinkingTokens;

  /// No description provided for @promptEditThinkingHelp.
  ///
  /// In ko, this message translates to:
  /// **'사고에 사용할 토큰 수입니다.'**
  String get promptEditThinkingHelp;

  /// No description provided for @promptEditStopStrings.
  ///
  /// In ko, this message translates to:
  /// **'정지 문자열'**
  String get promptEditStopStrings;

  /// No description provided for @promptEditStopStringsHint.
  ///
  /// In ko, this message translates to:
  /// **'문자열 입력 후 추가'**
  String get promptEditStopStringsHint;

  /// No description provided for @promptEditThinkingConfig.
  ///
  /// In ko, this message translates to:
  /// **'사고기능 구성'**
  String get promptEditThinkingConfig;

  /// No description provided for @promptEditThinkingTokenCount.
  ///
  /// In ko, this message translates to:
  /// **'생각토큰 수'**
  String get promptEditThinkingTokenCount;

  /// No description provided for @promptEditThinkingTokenHelp.
  ///
  /// In ko, this message translates to:
  /// **'생각에 사용할 최대 토큰 수입니다.'**
  String get promptEditThinkingTokenHelp;

  /// No description provided for @promptEditThinkingLevel.
  ///
  /// In ko, this message translates to:
  /// **'생각 수준'**
  String get promptEditThinkingLevel;

  /// No description provided for @chatModelTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델'**
  String get chatModelTitle;

  /// No description provided for @chatModelTabMain.
  ///
  /// In ko, this message translates to:
  /// **'주 모델'**
  String get chatModelTabMain;

  /// No description provided for @chatModelTabSub.
  ///
  /// In ko, this message translates to:
  /// **'보조 모델'**
  String get chatModelTabSub;

  /// No description provided for @chatModelSubInfo.
  ///
  /// In ko, this message translates to:
  /// **'보조 모델은 SNS 요약 등에 사용됩니다.\n설정 시 해당 기능들의 기본 모델이 변경됩니다.'**
  String get chatModelSubInfo;

  /// No description provided for @chatModelProviderSection.
  ///
  /// In ko, this message translates to:
  /// **'제조사'**
  String get chatModelProviderSection;

  /// No description provided for @chatModelUsedModelSection.
  ///
  /// In ko, this message translates to:
  /// **'사용 모델'**
  String get chatModelUsedModelSection;

  /// No description provided for @chatModelInfoSection.
  ///
  /// In ko, this message translates to:
  /// **'모델 정보'**
  String get chatModelInfoSection;

  /// No description provided for @chatModelManagement.
  ///
  /// In ko, this message translates to:
  /// **'커스텀 모델 관리'**
  String get chatModelManagement;

  /// No description provided for @chatModelApiKeyDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'이 API 키를 삭제하시겠습니까?'**
  String get chatModelApiKeyDeleteContent;

  /// No description provided for @chatModelVertexValidationFailed.
  ///
  /// In ko, this message translates to:
  /// **'서비스 계정 검증 실패'**
  String get chatModelVertexValidationFailed;

  /// No description provided for @chatModelNewApiKey.
  ///
  /// In ko, this message translates to:
  /// **'새 API 키'**
  String get chatModelNewApiKey;

  /// No description provided for @chatModelJsonAdd.
  ///
  /// In ko, this message translates to:
  /// **'JSON 추가'**
  String get chatModelJsonAdd;

  /// No description provided for @chatModelKeyAdd.
  ///
  /// In ko, this message translates to:
  /// **'키 추가'**
  String get chatModelKeyAdd;

  /// No description provided for @chatModelNoApiKey.
  ///
  /// In ko, this message translates to:
  /// **'등록된 API 키가 없습니다'**
  String get chatModelNoApiKey;

  /// No description provided for @apiKeyMultiInfo.
  ///
  /// In ko, this message translates to:
  /// **'각 제공사별로 여러 개의 API 키를 등록할 수 있습니다.'**
  String get apiKeyMultiInfo;

  /// No description provided for @chatPromptListLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 목록을 불러오는데 실패했습니다: {error}'**
  String chatPromptListLoadFailed(String error);

  /// No description provided for @chatPromptSelectFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 선택에 실패했습니다: {error}'**
  String chatPromptSelectFailed(String error);

  /// No description provided for @chatPromptDeleted.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트가 삭제되었습니다'**
  String get chatPromptDeleted;

  /// No description provided for @chatPromptDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 삭제에 실패했습니다: {error}'**
  String chatPromptDeleteFailed(String error);

  /// No description provided for @chatPromptDefaultSelect.
  ///
  /// In ko, this message translates to:
  /// **'기본 프롬프트 선택'**
  String get chatPromptDefaultSelect;

  /// No description provided for @chatPromptEmpty.
  ///
  /// In ko, this message translates to:
  /// **'빈 프롬프트'**
  String get chatPromptEmpty;

  /// No description provided for @chatPromptCopied.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트가 복사되었습니다'**
  String get chatPromptCopied;

  /// No description provided for @chatPromptCopyFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 복사에 실패했습니다: {error}'**
  String chatPromptCopyFailed(String error);

  /// No description provided for @chatPromptResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get chatPromptResetTitle;

  /// No description provided for @chatPromptResetContent.
  ///
  /// In ko, this message translates to:
  /// **'모든 기본 프롬프트를 초기 상태로 되돌리시겠습니까?'**
  String get chatPromptResetContent;

  /// No description provided for @chatPromptResetSuccess.
  ///
  /// In ko, this message translates to:
  /// **'기본 프롬프트가 초기화되었습니다'**
  String get chatPromptResetSuccess;

  /// No description provided for @chatPromptResetFailed.
  ///
  /// In ko, this message translates to:
  /// **'기본 프롬프트 초기화에 실패했습니다: {error}'**
  String chatPromptResetFailed(String error);

  /// No description provided for @chatPromptExportFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 내보내기 실패: {error}'**
  String chatPromptExportFailed(String error);

  /// No description provided for @chatPromptImportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트가 가져오기 되었습니다'**
  String get chatPromptImportSuccess;

  /// No description provided for @chatPromptImportFailed.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 가져오기 실패: {error}'**
  String chatPromptImportFailed(String error);

  /// No description provided for @chatPromptListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트가 없습니다'**
  String get chatPromptListEmpty;
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
