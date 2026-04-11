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

  /// No description provided for @commonCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get commonCopy;

  /// No description provided for @commonModify.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonModify;

  /// No description provided for @commonCopyItem.
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get commonCopyItem;

  /// No description provided for @commonExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get commonExport;

  /// No description provided for @commonReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get commonReset;

  /// No description provided for @commonDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get commonDefault;

  /// No description provided for @commonLabelName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get commonLabelName;

  /// No description provided for @commonNumberHint.
  ///
  /// In ko, this message translates to:
  /// **'숫자 입력'**
  String get commonNumberHint;

  /// No description provided for @commonAddItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get commonAddItem;

  /// No description provided for @commonAddFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 추가'**
  String get commonAddFolder;

  /// No description provided for @commonEmptyList.
  ///
  /// In ko, this message translates to:
  /// **'항목이 없습니다'**
  String get commonEmptyList;

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

  /// No description provided for @chatRoomMainModelLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'주모델 \'{modelId}\'을(를) 불러올 수 없습니다. 채팅 모델 설정에서 다시 선택해주세요.'**
  String chatRoomMainModelLoadFailed(String modelId);

  /// No description provided for @chatRoomSubModelLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'보조모델 \'{modelId}\'을(를) 불러올 수 없습니다. 채팅 모델 설정에서 다시 선택해주세요.'**
  String chatRoomSubModelLoadFailed(String modelId);

  /// No description provided for @chatRoomCustomModelLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이 채팅방에 지정된 모델 \'{modelId}\'을(를) 불러올 수 없습니다. 채팅방 설정에서 모델을 다시 선택해주세요.'**
  String chatRoomCustomModelLoadFailed(String modelId);

  /// No description provided for @chatRoomPromptLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'채팅 프롬프트(id: {promptId})를 불러올 수 없습니다. 채팅방 설정에서 프롬프트를 다시 선택해주세요.'**
  String chatRoomPromptLoadFailed(String promptId);

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

  /// No description provided for @communityAnonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get communityAnonymous;

  /// No description provided for @communityNeedDescription.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 설명 또는 요약 내용을 먼저 작성해주세요.'**
  String get communityNeedDescription;

  /// No description provided for @communityGenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'생성 실패: {error}'**
  String communityGenerateFailed(String error);

  /// No description provided for @communityRegisterFailed.
  ///
  /// In ko, this message translates to:
  /// **'등록 실패: {error}'**
  String communityRegisterFailed(String error);

  /// No description provided for @communityWritePost.
  ///
  /// In ko, this message translates to:
  /// **'게시글 작성'**
  String get communityWritePost;

  /// No description provided for @communityNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get communityNickname;

  /// No description provided for @communityTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get communityTitle;

  /// No description provided for @communityContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get communityContent;

  /// No description provided for @communityRegister.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get communityRegister;

  /// No description provided for @communityWriteComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글 작성'**
  String get communityWriteComment;

  /// No description provided for @communityCommentContent.
  ///
  /// In ko, this message translates to:
  /// **'댓글 내용'**
  String get communityCommentContent;

  /// No description provided for @communityCommentDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get communityCommentDeleteTitle;

  /// No description provided for @communityCommentDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'이 댓글을 삭제할까요?'**
  String get communityCommentDeleteContent;

  /// No description provided for @communityPostDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'게시글 삭제'**
  String get communityPostDeleteTitle;

  /// No description provided for @communityPostDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'이 게시글을 삭제할까요?'**
  String get communityPostDeleteContent;

  /// No description provided for @communityDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'자유게시판'**
  String get communityDefaultName;

  /// No description provided for @communitySettingsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get communitySettingsTooltip;

  /// No description provided for @communityRefreshTooltip.
  ///
  /// In ko, this message translates to:
  /// **'새 게시글 생성'**
  String get communityRefreshTooltip;

  /// No description provided for @communityNoPostsTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 게시글이 없습니다'**
  String get communityNoPostsTitle;

  /// No description provided for @communityNoPostsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'당겨서 게시글을 새로 불러오세요'**
  String get communityNoPostsSubtitle;

  /// No description provided for @communityCommentLabel.
  ///
  /// In ko, this message translates to:
  /// **'댓글 달기'**
  String get communityCommentLabel;

  /// No description provided for @communityUsedModelSection.
  ///
  /// In ko, this message translates to:
  /// **'사용 모델'**
  String get communityUsedModelSection;

  /// No description provided for @communityModelPreset.
  ///
  /// In ko, this message translates to:
  /// **'모델설정'**
  String get communityModelPreset;

  /// No description provided for @communityProvider.
  ///
  /// In ko, this message translates to:
  /// **'제조사'**
  String get communityProvider;

  /// No description provided for @communityChatModel.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델'**
  String get communityChatModel;

  /// No description provided for @communitySettingsSection.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 설정'**
  String get communitySettingsSection;

  /// No description provided for @communityNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 이름'**
  String get communityNameLabel;

  /// No description provided for @communityToneLabel.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 분위기'**
  String get communityToneLabel;

  /// No description provided for @communityLanguageLabel.
  ///
  /// In ko, this message translates to:
  /// **'사용 언어'**
  String get communityLanguageLabel;

  /// No description provided for @characterViewTabInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get characterViewTabInfo;

  /// No description provided for @characterViewTabChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get characterViewTabChat;

  /// No description provided for @characterViewTagline.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개'**
  String get characterViewTagline;

  /// No description provided for @characterViewKeywords.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get characterViewKeywords;

  /// No description provided for @characterViewPersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나'**
  String get characterViewPersona;

  /// No description provided for @characterViewStartSetting.
  ///
  /// In ko, this message translates to:
  /// **'시작 설정'**
  String get characterViewStartSetting;

  /// No description provided for @characterViewStartContext.
  ///
  /// In ko, this message translates to:
  /// **'시작 상황'**
  String get characterViewStartContext;

  /// No description provided for @characterViewStartMessage.
  ///
  /// In ko, this message translates to:
  /// **'시작 메시지'**
  String get characterViewStartMessage;

  /// No description provided for @characterViewNewChat.
  ///
  /// In ko, this message translates to:
  /// **'새 채팅'**
  String get characterViewNewChat;

  /// No description provided for @characterViewChatCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 생성 중 오류가 발생했습니다'**
  String get characterViewChatCreateFailed;

  /// No description provided for @characterViewNoChats.
  ///
  /// In ko, this message translates to:
  /// **'채팅방이 없습니다'**
  String get characterViewNoChats;

  /// No description provided for @characterViewStartNewChat.
  ///
  /// In ko, this message translates to:
  /// **'새 채팅을 시작해보세요'**
  String get characterViewStartNewChat;

  /// No description provided for @agentChatErrorPrefix.
  ///
  /// In ko, this message translates to:
  /// **'오류: {error}'**
  String agentChatErrorPrefix(String error);

  /// No description provided for @agentChatResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'대화 초기화'**
  String get agentChatResetTitle;

  /// No description provided for @agentChatResetContent.
  ///
  /// In ko, this message translates to:
  /// **'모든 대화 내용이 삭제됩니다. 계속하시겠습니까?'**
  String get agentChatResetContent;

  /// No description provided for @agentChatResetTooltip.
  ///
  /// In ko, this message translates to:
  /// **'대화 초기화'**
  String get agentChatResetTooltip;

  /// No description provided for @agentChatIntro.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 생성, 수정, 편집을 도와드립니다'**
  String get agentChatIntro;

  /// No description provided for @agentChatUserLabel.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get agentChatUserLabel;

  /// No description provided for @agentChatUsedModel.
  ///
  /// In ko, this message translates to:
  /// **'사용 모델'**
  String get agentChatUsedModel;

  /// No description provided for @agentChatModelPreset.
  ///
  /// In ko, this message translates to:
  /// **'모델설정'**
  String get agentChatModelPreset;

  /// No description provided for @agentChatProvider.
  ///
  /// In ko, this message translates to:
  /// **'제조사'**
  String get agentChatProvider;

  /// No description provided for @agentChatModel.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델'**
  String get agentChatModel;

  /// No description provided for @agentChatWaiting.
  ///
  /// In ko, this message translates to:
  /// **'응답 대기 중...'**
  String get agentChatWaiting;

  /// No description provided for @agentChatHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요'**
  String get agentChatHint;

  /// No description provided for @diaryGenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'일기 생성 실패: {error}'**
  String diaryGenerateFailed(String error);

  /// No description provided for @diaryGenerateTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 생성'**
  String get diaryGenerateTitle;

  /// No description provided for @diaryGenerateContent.
  ///
  /// In ko, this message translates to:
  /// **'{date}의 일기를 생성할까요?'**
  String diaryGenerateContent(String date);

  /// No description provided for @diaryDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 삭제'**
  String get diaryDeleteTitle;

  /// No description provided for @diaryDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'이 일기를 삭제할까요?'**
  String get diaryDeleteContent;

  /// No description provided for @diaryRegenerateTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 재생성'**
  String get diaryRegenerateTitle;

  /// No description provided for @diaryRegenerateContent.
  ///
  /// In ko, this message translates to:
  /// **'{date}의 일기를 모두 삭제하고 다시 생성할까요?'**
  String diaryRegenerateContent(String date);

  /// No description provided for @diarySettingsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get diarySettingsTooltip;

  /// No description provided for @diaryDaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get diaryDaySun;

  /// No description provided for @diaryDayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get diaryDayMon;

  /// No description provided for @diaryDayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get diaryDayTue;

  /// No description provided for @diaryDayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get diaryDayWed;

  /// No description provided for @diaryDayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get diaryDayThu;

  /// No description provided for @diaryDayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get diaryDayFri;

  /// No description provided for @diaryDaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get diaryDaySat;

  /// No description provided for @diarySelectDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하세요'**
  String get diarySelectDate;

  /// No description provided for @diaryGenerating.
  ///
  /// In ko, this message translates to:
  /// **'일기를 생성하고 있습니다...'**
  String get diaryGenerating;

  /// No description provided for @diaryNoEntries.
  ///
  /// In ko, this message translates to:
  /// **'아직 일기가 없습니다'**
  String get diaryNoEntries;

  /// No description provided for @diaryRegenerateTooltip.
  ///
  /// In ko, this message translates to:
  /// **'재생성'**
  String get diaryRegenerateTooltip;

  /// No description provided for @diaryUsedModel.
  ///
  /// In ko, this message translates to:
  /// **'사용 모델'**
  String get diaryUsedModel;

  /// No description provided for @diaryModelPreset.
  ///
  /// In ko, this message translates to:
  /// **'모델설정'**
  String get diaryModelPreset;

  /// No description provided for @diaryProvider.
  ///
  /// In ko, this message translates to:
  /// **'제조사'**
  String get diaryProvider;

  /// No description provided for @diaryChatModel.
  ///
  /// In ko, this message translates to:
  /// **'채팅 모델'**
  String get diaryChatModel;

  /// No description provided for @diarySettingsSection.
  ///
  /// In ko, this message translates to:
  /// **'다이어리 설정'**
  String get diarySettingsSection;

  /// No description provided for @diaryAutoGenerate.
  ///
  /// In ko, this message translates to:
  /// **'자동 생성'**
  String get diaryAutoGenerate;

  /// No description provided for @diaryAutoGenerateDesc.
  ///
  /// In ko, this message translates to:
  /// **'채팅 내 날짜가 변경되면 자동으로 일기를 생성합니다.'**
  String get diaryAutoGenerateDesc;

  /// No description provided for @characterBookInvalidFormat.
  ///
  /// In ko, this message translates to:
  /// **'올바른 설정집 형식이 아닙니다'**
  String get characterBookInvalidFormat;

  /// No description provided for @characterBookNoImport.
  ///
  /// In ko, this message translates to:
  /// **'가져올 설정이 없습니다'**
  String get characterBookNoImport;

  /// No description provided for @characterBookImportFailed.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 실패: {error}'**
  String characterBookImportFailed(String error);

  /// No description provided for @characterBookNoExport.
  ///
  /// In ko, this message translates to:
  /// **'내보낼 설정이 없습니다'**
  String get characterBookNoExport;

  /// No description provided for @characterBookSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다'**
  String get characterBookSaveFailed;

  /// No description provided for @characterBookExportFailed.
  ///
  /// In ko, this message translates to:
  /// **'내보내기 실패: {error}'**
  String characterBookExportFailed(String error);

  /// No description provided for @characterBookNewFolder.
  ///
  /// In ko, this message translates to:
  /// **'새 폴더'**
  String get characterBookNewFolder;

  /// No description provided for @characterBookNewItem.
  ///
  /// In ko, this message translates to:
  /// **'새 설정'**
  String get characterBookNewItem;

  /// No description provided for @characterBookFolderDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'폴더 삭제'**
  String get characterBookFolderDeleteTitle;

  /// No description provided for @characterBookSection.
  ///
  /// In ko, this message translates to:
  /// **'설정집'**
  String get characterBookSection;

  /// No description provided for @characterBookSectionHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 세계관과 관련된 정보를 설정집에 추가할 수 있습니다.\n\n길게 눌러 순서를 변경할 수 있습니다.'**
  String get characterBookSectionHelp;

  /// No description provided for @characterBookAddItem.
  ///
  /// In ko, this message translates to:
  /// **'설정 추가'**
  String get characterBookAddItem;

  /// No description provided for @characterBookAddFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 추가'**
  String get characterBookAddFolder;

  /// No description provided for @characterBookEmpty.
  ///
  /// In ko, this message translates to:
  /// **'설정집 항목이 없습니다'**
  String get characterBookEmpty;

  /// No description provided for @characterBookNameHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 이름'**
  String get characterBookNameHint;

  /// No description provided for @characterBookActivationCondition.
  ///
  /// In ko, this message translates to:
  /// **'활성화 조건'**
  String get characterBookActivationCondition;

  /// No description provided for @characterBookActivationKey.
  ///
  /// In ko, this message translates to:
  /// **'활성화 키'**
  String get characterBookActivationKey;

  /// No description provided for @characterBookKeysHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분하여 입력 (예: 마법, 전투)'**
  String get characterBookKeysHint;

  /// No description provided for @characterBookSecondaryKey.
  ///
  /// In ko, this message translates to:
  /// **'두번째 키'**
  String get characterBookSecondaryKey;

  /// No description provided for @characterBookInsertionOrder.
  ///
  /// In ko, this message translates to:
  /// **'배치 순서'**
  String get characterBookInsertionOrder;

  /// No description provided for @characterBookContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get characterBookContent;

  /// No description provided for @characterBookContentHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 내용을 입력해주세요'**
  String get characterBookContentHint;

  /// No description provided for @newsArticleDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'기사 삭제'**
  String get newsArticleDeleteTitle;

  /// No description provided for @newsArticleDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'이 기사를 삭제하시겠습니까?'**
  String get newsArticleDeleteContent;

  /// No description provided for @newsEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 기사가 없습니다'**
  String get newsEmptyTitle;

  /// No description provided for @newsEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'당겨서 뉴스를 불러오세요'**
  String get newsEmptySubtitle;

  /// No description provided for @newsRefreshTooltip.
  ///
  /// In ko, this message translates to:
  /// **'새 기사 생성'**
  String get newsRefreshTooltip;

  /// No description provided for @promptItemsTitle.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 항목'**
  String get promptItemsTitle;

  /// No description provided for @promptItemsTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'AI에게 전달될 프롬프트 항목들을 추가하세요. 순서대로 전달됩니다.\n\n길게 눌러 순서를 변경할 수 있습니다.'**
  String get promptItemsTitleHelp;

  /// No description provided for @promptItemsAddItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get promptItemsAddItem;

  /// No description provided for @promptItemsAddFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 추가'**
  String get promptItemsAddFolder;

  /// No description provided for @promptItemsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 항목이 없습니다'**
  String get promptItemsEmpty;

  /// No description provided for @promptItemsNameHint.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름 (예: 시스템 설정, 캐릭터 성격)'**
  String get promptItemsNameHint;

  /// No description provided for @promptItemsLabelEnable.
  ///
  /// In ko, this message translates to:
  /// **'활성화'**
  String get promptItemsLabelEnable;

  /// No description provided for @promptItemsLabelRole.
  ///
  /// In ko, this message translates to:
  /// **'역할'**
  String get promptItemsLabelRole;

  /// No description provided for @promptItemsLabelPrompt.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트'**
  String get promptItemsLabelPrompt;

  /// No description provided for @promptItemsPromptHint.
  ///
  /// In ko, this message translates to:
  /// **'AI의 역할과 응답 방식을 정의하세요'**
  String get promptItemsPromptHint;

  /// No description provided for @promptItemsConditionSelect.
  ///
  /// In ko, this message translates to:
  /// **'조건 선택'**
  String get promptItemsConditionSelect;

  /// No description provided for @promptItemsConditionSelectHint.
  ///
  /// In ko, this message translates to:
  /// **'조건을 선택하세요'**
  String get promptItemsConditionSelectHint;

  /// No description provided for @promptItemsConditionNoName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get promptItemsConditionNoName;

  /// No description provided for @promptItemsConditionValue.
  ///
  /// In ko, this message translates to:
  /// **'조건 값'**
  String get promptItemsConditionValue;

  /// No description provided for @promptItemsConditionEnabled.
  ///
  /// In ko, this message translates to:
  /// **'활성화'**
  String get promptItemsConditionEnabled;

  /// No description provided for @promptItemsConditionDisabled.
  ///
  /// In ko, this message translates to:
  /// **'비활성화'**
  String get promptItemsConditionDisabled;

  /// No description provided for @promptItemsSingleSelectItems.
  ///
  /// In ko, this message translates to:
  /// **'선택 항목'**
  String get promptItemsSingleSelectItems;

  /// No description provided for @promptItemsSingleSelectHint.
  ///
  /// In ko, this message translates to:
  /// **'항목을 선택하세요'**
  String get promptItemsSingleSelectHint;

  /// No description provided for @promptItemsChatSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get promptItemsChatSettings;

  /// No description provided for @promptItemsRecentChatCount.
  ///
  /// In ko, this message translates to:
  /// **'최근 채팅 포함 개수'**
  String get promptItemsRecentChatCount;

  /// No description provided for @promptItemsRecentChatCountHint.
  ///
  /// In ko, this message translates to:
  /// **'개수'**
  String get promptItemsRecentChatCountHint;

  /// No description provided for @promptItemsChatStartPos.
  ///
  /// In ko, this message translates to:
  /// **'이전 채팅 시작 위치'**
  String get promptItemsChatStartPos;

  /// No description provided for @promptItemsChatStartPosHint.
  ///
  /// In ko, this message translates to:
  /// **'시작 위치'**
  String get promptItemsChatStartPosHint;

  /// No description provided for @promptItemsChatEndPos.
  ///
  /// In ko, this message translates to:
  /// **'이전 채팅 마지막 위치'**
  String get promptItemsChatEndPos;

  /// No description provided for @promptItemsChatEndPosHint.
  ///
  /// In ko, this message translates to:
  /// **'마지막 위치'**
  String get promptItemsChatEndPosHint;

  /// No description provided for @promptConditionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 조건'**
  String get promptConditionsTitle;

  /// No description provided for @promptConditionsTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트에 적용할 조건을 설정합니다.\n\n• 토글: ON/OFF 스위치\n• 하나만 선택: 여러 항목 중 하나를 선택\n• 변수 치환: 변수명을 선택한 항목으로 치환'**
  String get promptConditionsTitleHelp;

  /// No description provided for @promptConditionsAddButton.
  ///
  /// In ko, this message translates to:
  /// **'조건 추가'**
  String get promptConditionsAddButton;

  /// No description provided for @promptConditionsNewName.
  ///
  /// In ko, this message translates to:
  /// **'새 조건'**
  String get promptConditionsNewName;

  /// No description provided for @promptConditionsNameHint.
  ///
  /// In ko, this message translates to:
  /// **'조건 이름 (예: 말투, 분위기)'**
  String get promptConditionsNameHint;

  /// No description provided for @promptConditionsLabelType.
  ///
  /// In ko, this message translates to:
  /// **'형태'**
  String get promptConditionsLabelType;

  /// No description provided for @promptConditionsLabelVarName.
  ///
  /// In ko, this message translates to:
  /// **'변수 이름'**
  String get promptConditionsLabelVarName;

  /// No description provided for @promptConditionsVarNameHint.
  ///
  /// In ko, this message translates to:
  /// **'변수 이름'**
  String get promptConditionsVarNameHint;

  /// No description provided for @promptConditionsLabelOptions.
  ///
  /// In ko, this message translates to:
  /// **'항목 목록'**
  String get promptConditionsLabelOptions;

  /// No description provided for @promptConditionsOptionsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'항목이 없습니다'**
  String get promptConditionsOptionsEmpty;

  /// No description provided for @promptConditionsOptionAddHint.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름 입력'**
  String get promptConditionsOptionAddHint;

  /// No description provided for @promptPresetsTitle.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 조건 프리셋'**
  String get promptPresetsTitle;

  /// No description provided for @promptPresetsTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트 조건의 값을 미리 설정해둔 프리셋입니다.\n\n채팅 시 프리셋을 선택하면 조건 값이 일괄 적용됩니다.'**
  String get promptPresetsTitleHelp;

  /// No description provided for @promptPresetsAddButton.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 추가'**
  String get promptPresetsAddButton;

  /// No description provided for @promptPresetsNewName.
  ///
  /// In ko, this message translates to:
  /// **'새 프리셋'**
  String get promptPresetsNewName;

  /// No description provided for @promptPresetsLabelName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get promptPresetsLabelName;

  /// No description provided for @promptPresetsNameHint.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름'**
  String get promptPresetsNameHint;

  /// No description provided for @promptPresetsLabelConditions.
  ///
  /// In ko, this message translates to:
  /// **'조건 목록'**
  String get promptPresetsLabelConditions;

  /// No description provided for @promptPresetsConditionNoName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get promptPresetsConditionNoName;

  /// No description provided for @promptPresetsSelectHint.
  ///
  /// In ko, this message translates to:
  /// **'항목을 선택하세요'**
  String get promptPresetsSelectHint;

  /// No description provided for @promptPresetsCustomLabel.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get promptPresetsCustomLabel;

  /// No description provided for @promptPresetsCustomInputLabel.
  ///
  /// In ko, this message translates to:
  /// **'직접입력'**
  String get promptPresetsCustomInputLabel;

  /// No description provided for @promptPresetsCustomInputHint.
  ///
  /// In ko, this message translates to:
  /// **'값을 입력하세요'**
  String get promptPresetsCustomInputHint;

  /// No description provided for @promptRegexTitle.
  ///
  /// In ko, this message translates to:
  /// **'정규식 규칙'**
  String get promptRegexTitle;

  /// No description provided for @promptRegexTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'정규식(RegExp)을 사용하여 텍스트를 변환합니다.\n\n속성에 따라 적용 시점이 달라집니다:\n• 입력문 수정: 사용자 입력 텍스트에 적용\n• 출력문 수정: AI 응답 텍스트에 적용\n• 전송데이터 수정: API 전송 데이터에 적용\n• 출력화면 수정: 화면 표시 시에만 적용'**
  String get promptRegexTitleHelp;

  /// No description provided for @promptRegexEmpty.
  ///
  /// In ko, this message translates to:
  /// **'정규식 규칙이 없습니다'**
  String get promptRegexEmpty;

  /// No description provided for @promptRegexRuleDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'규칙 {index}'**
  String promptRegexRuleDefaultName(int index);

  /// No description provided for @promptRegexNameHint.
  ///
  /// In ko, this message translates to:
  /// **'규칙 이름 (예: OOC 제거, 태그 변환)'**
  String get promptRegexNameHint;

  /// No description provided for @promptRegexLabelTarget.
  ///
  /// In ko, this message translates to:
  /// **'속성'**
  String get promptRegexLabelTarget;

  /// No description provided for @promptRegexLabelPattern.
  ///
  /// In ko, this message translates to:
  /// **'정규식 패턴'**
  String get promptRegexLabelPattern;

  /// No description provided for @promptRegexPatternHint.
  ///
  /// In ko, this message translates to:
  /// **'예: \\(OOC:.*?\\)'**
  String get promptRegexPatternHint;

  /// No description provided for @promptRegexLabelReplacement.
  ///
  /// In ko, this message translates to:
  /// **'변환 형식'**
  String get promptRegexLabelReplacement;

  /// No description provided for @promptRegexReplacementHint.
  ///
  /// In ko, this message translates to:
  /// **'정규식에 매칭된 텍스트가 이 형식으로 변환됩니다\n\n캡처 그룹: \$1, \$2, ...'**
  String get promptRegexReplacementHint;

  /// No description provided for @promptRegexAddButton.
  ///
  /// In ko, this message translates to:
  /// **'규칙 추가'**
  String get promptRegexAddButton;

  /// No description provided for @backupTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 및 복구'**
  String get backupTitle;

  /// No description provided for @backupSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 생성'**
  String get backupSectionTitle;

  /// No description provided for @backupSectionDesc.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터(이미지 포함), 채팅 기록, 프롬프트, 커스텀 모델, 설정 등 모든 데이터를 하나의 백업 파일로 내보냅니다.'**
  String get backupSectionDesc;

  /// No description provided for @backupCreateButton.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일 생성'**
  String get backupCreateButton;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 복구'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreDesc.
  ///
  /// In ko, this message translates to:
  /// **'백업 .zip 파일을 선택하여 데이터를 복원합니다. (기존 .db 파일도 지원)'**
  String get backupRestoreDesc;

  /// No description provided for @backupRestoreWarning.
  ///
  /// In ko, this message translates to:
  /// **'주의: 기존 데이터가 모두 삭제됩니다. 복구 후 앱 재시작이 필요합니다.'**
  String get backupRestoreWarning;

  /// No description provided for @backupRestoreButton.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일 선택'**
  String get backupRestoreButton;

  /// No description provided for @backupProcessing.
  ///
  /// In ko, this message translates to:
  /// **'처리 중...'**
  String get backupProcessing;

  /// No description provided for @backupSuccessDownloads.
  ///
  /// In ko, this message translates to:
  /// **'백업 완료: Downloads/{fileName}'**
  String backupSuccessDownloads(String fileName);

  /// No description provided for @backupSuccessIos.
  ///
  /// In ko, this message translates to:
  /// **'백업 완료: {fileName}'**
  String backupSuccessIos(String fileName);

  /// No description provided for @backupSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일 저장에 실패했습니다'**
  String get backupSaveFailed;

  /// No description provided for @backupFailed.
  ///
  /// In ko, this message translates to:
  /// **'백업 실패: {error}'**
  String backupFailed(String error);

  /// No description provided for @backupInvalidFile.
  ///
  /// In ko, this message translates to:
  /// **'.zip 또는 .db 백업 파일을 선택해주세요'**
  String get backupInvalidFile;

  /// No description provided for @backupZipNoDb.
  ///
  /// In ko, this message translates to:
  /// **'ZIP 파일에서 backup.db를 찾을 수 없습니다'**
  String get backupZipNoDb;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 복구'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmContent.
  ///
  /// In ko, this message translates to:
  /// **'백업 일시: {createdAt}\n\n기존 데이터가 모두 삭제되고 백업 데이터로 대체됩니다.\n계속하시겠습니까?'**
  String backupRestoreConfirmContent(String createdAt);

  /// No description provided for @backupRestoreConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'복구'**
  String get backupRestoreConfirmButton;

  /// No description provided for @backupRestoreSuccessTitle.
  ///
  /// In ko, this message translates to:
  /// **'복구 완료'**
  String get backupRestoreSuccessTitle;

  /// No description provided for @backupRestoreSuccessContent.
  ///
  /// In ko, this message translates to:
  /// **'백업 데이터가 복구되었습니다.\n변경사항을 완전히 적용하려면 앱을 재시작해주세요.'**
  String get backupRestoreSuccessContent;

  /// No description provided for @backupRestoreFailed.
  ///
  /// In ko, this message translates to:
  /// **'복구 실패: {error}'**
  String backupRestoreFailed(String error);

  /// No description provided for @backupCreatedAtUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get backupCreatedAtUnknown;

  /// No description provided for @logTitle.
  ///
  /// In ko, this message translates to:
  /// **'API 로그'**
  String get logTitle;

  /// No description provided for @logDeleteAllTooltip.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get logDeleteAllTooltip;

  /// No description provided for @logInfoMessage.
  ///
  /// In ko, this message translates to:
  /// **'API 요청/응답 로그를 확인할 수 있습니다.\n7일이 지난 로그는 자동으로 삭제됩니다.'**
  String get logInfoMessage;

  /// No description provided for @logEmpty.
  ///
  /// In ko, this message translates to:
  /// **'로그가 없습니다'**
  String get logEmpty;

  /// No description provided for @logAutoSummaryLabel.
  ///
  /// In ko, this message translates to:
  /// **'자동 요약'**
  String get logAutoSummaryLabel;

  /// No description provided for @logDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그 삭제'**
  String get logDeleteTitle;

  /// No description provided for @logDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'이 로그를 삭제하시겠습니까?'**
  String get logDeleteContent;

  /// No description provided for @logDeleteSuccess.
  ///
  /// In ko, this message translates to:
  /// **'로그가 삭제되었습니다'**
  String get logDeleteSuccess;

  /// No description provided for @logDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그 삭제 실패: {error}'**
  String logDeleteFailed(String error);

  /// No description provided for @logDeleteAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'전체 로그 삭제'**
  String get logDeleteAllTitle;

  /// No description provided for @logDeleteAllContent.
  ///
  /// In ko, this message translates to:
  /// **'모든 로그를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'**
  String get logDeleteAllContent;

  /// No description provided for @logDeleteAllSuccess.
  ///
  /// In ko, this message translates to:
  /// **'모든 로그가 삭제되었습니다'**
  String get logDeleteAllSuccess;

  /// No description provided for @logLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그 불러오기 실패: {error}'**
  String logLoadFailed(String error);

  /// No description provided for @logDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그 상세'**
  String get logDetailTitle;

  /// No description provided for @logDetailInfoSection.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get logDetailInfoSection;

  /// No description provided for @logDetailTime.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get logDetailTime;

  /// No description provided for @logDetailType.
  ///
  /// In ko, this message translates to:
  /// **'타입'**
  String get logDetailType;

  /// No description provided for @logDetailModel.
  ///
  /// In ko, this message translates to:
  /// **'모델'**
  String get logDetailModel;

  /// No description provided for @logDetailChatRoomId.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 ID'**
  String get logDetailChatRoomId;

  /// No description provided for @logDetailCharacterId.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 ID'**
  String get logDetailCharacterId;

  /// No description provided for @logDetailCopied.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에 복사되었습니다'**
  String get logDetailCopied;

  /// No description provided for @logDetailFormatLabel.
  ///
  /// In ko, this message translates to:
  /// **'포맷'**
  String get logDetailFormatLabel;

  /// No description provided for @statisticsTitle.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statisticsTitle;

  /// No description provided for @statisticsNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get statisticsNoData;

  /// No description provided for @statisticsPeriod7Days.
  ///
  /// In ko, this message translates to:
  /// **'7일'**
  String get statisticsPeriod7Days;

  /// No description provided for @statisticsPeriod30Days.
  ///
  /// In ko, this message translates to:
  /// **'30일'**
  String get statisticsPeriod30Days;

  /// No description provided for @statisticsPeriodAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get statisticsPeriodAll;

  /// No description provided for @statisticsCost.
  ///
  /// In ko, this message translates to:
  /// **'예상 비용'**
  String get statisticsCost;

  /// No description provided for @statisticsTokens.
  ///
  /// In ko, this message translates to:
  /// **'총 토큰'**
  String get statisticsTokens;

  /// No description provided for @statisticsMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get statisticsMessages;

  /// No description provided for @statisticsDailyTokens.
  ///
  /// In ko, this message translates to:
  /// **'{tokens} 토큰'**
  String statisticsDailyTokens(String tokens);

  /// No description provided for @statisticsDailyMessages.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 메시지'**
  String statisticsDailyMessages(int count);

  /// No description provided for @statisticsModelMessages.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String statisticsModelMessages(int count);

  /// No description provided for @statisticsDailyModels.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 모델'**
  String statisticsDailyModels(int count);

  /// No description provided for @statisticsDateFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String statisticsDateFormat(String year, String month, String day);

  /// No description provided for @statisticsTokenInput.
  ///
  /// In ko, this message translates to:
  /// **'입력'**
  String get statisticsTokenInput;

  /// No description provided for @statisticsTokenOutput.
  ///
  /// In ko, this message translates to:
  /// **'출력'**
  String get statisticsTokenOutput;

  /// No description provided for @statisticsTokenCached.
  ///
  /// In ko, this message translates to:
  /// **'캐시'**
  String get statisticsTokenCached;

  /// No description provided for @statisticsTokenThinking.
  ///
  /// In ko, this message translates to:
  /// **'사고'**
  String get statisticsTokenThinking;

  /// No description provided for @tokenizerTitle.
  ///
  /// In ko, this message translates to:
  /// **'토크나이저'**
  String get tokenizerTitle;

  /// No description provided for @tokenizerSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'토크나이저 선택'**
  String get tokenizerSectionTitle;

  /// No description provided for @tokenizerLabel.
  ///
  /// In ko, this message translates to:
  /// **'토크나이저'**
  String get tokenizerLabel;

  /// No description provided for @tokenizerDescription.
  ///
  /// In ko, this message translates to:
  /// **'토크나이저는 텍스트를 토큰으로 변환하는 방식을 결정합니다. 모델에 따라 적합한 토크나이저가 다를 수 있습니다.'**
  String get tokenizerDescription;

  /// No description provided for @profileTabLabelName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get profileTabLabelName;

  /// No description provided for @profileTabNameHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 고유한 이름을 입력해주세요.'**
  String get profileTabNameHelp;

  /// No description provided for @profileTabNameHint.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 이름을 입력해주세요.'**
  String get profileTabNameHint;

  /// No description provided for @profileTabNameValidation.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 이름을 입력해주세요'**
  String get profileTabNameValidation;

  /// No description provided for @profileTabLabelNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get profileTabLabelNickname;

  /// No description provided for @profileTabNicknameHelp.
  ///
  /// In ko, this message translates to:
  /// **'프롬프트에서 char 변수 대신 사용할 호칭입니다. 비워두면 이름이 사용됩니다.'**
  String get profileTabNicknameHelp;

  /// No description provided for @profileTabNicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 닉네임을 입력해주세요.'**
  String get profileTabNicknameHint;

  /// No description provided for @profileTabLabelCreatorNotes.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개'**
  String get profileTabLabelCreatorNotes;

  /// No description provided for @profileTabCreatorNotesHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터를 간단히 설명하는 한 문장을 작성해주세요.'**
  String get profileTabCreatorNotesHelp;

  /// No description provided for @profileTabCreatorNotesHint.
  ///
  /// In ko, this message translates to:
  /// **'어떤 캐릭터인지 설명할 수 있는 간단한 소개를 입력해주세요.'**
  String get profileTabCreatorNotesHint;

  /// No description provided for @profileTabLabelKeywords.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get profileTabLabelKeywords;

  /// No description provided for @profileTabKeywordsHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터를 나타내는 키워드를 쉼표(,)로 구분하여 입력해주세요.'**
  String get profileTabKeywordsHelp;

  /// No description provided for @profileTabKeywordsHint.
  ///
  /// In ko, this message translates to:
  /// **'키워드 입력 예시: 판타지, 남자'**
  String get profileTabKeywordsHint;

  /// No description provided for @startScenarioTitle.
  ///
  /// In ko, this message translates to:
  /// **'시작설정'**
  String get startScenarioTitle;

  /// No description provided for @startScenarioTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'대화의 시작 설정 정보를 추가할 수 있습니다.'**
  String get startScenarioTitleHelp;

  /// No description provided for @startScenarioEmpty.
  ///
  /// In ko, this message translates to:
  /// **'시작설정 항목이 없습니다'**
  String get startScenarioEmpty;

  /// No description provided for @startScenarioAddButton.
  ///
  /// In ko, this message translates to:
  /// **'시작설정 추가'**
  String get startScenarioAddButton;

  /// No description provided for @startScenarioNewName.
  ///
  /// In ko, this message translates to:
  /// **'새 시작설정'**
  String get startScenarioNewName;

  /// No description provided for @startScenarioNameHint.
  ///
  /// In ko, this message translates to:
  /// **'시작설정 이름'**
  String get startScenarioNameHint;

  /// No description provided for @startScenarioStartSettingLabel.
  ///
  /// In ko, this message translates to:
  /// **'시작 설정'**
  String get startScenarioStartSettingLabel;

  /// No description provided for @startScenarioStartSettingInfo.
  ///
  /// In ko, this message translates to:
  /// **'해당 내용은 요약 이전에 삽입되고 삭제되지 않습니다.'**
  String get startScenarioStartSettingInfo;

  /// No description provided for @startScenarioStartSettingHint.
  ///
  /// In ko, this message translates to:
  /// **'시작 설정 내용을 입력해주세요'**
  String get startScenarioStartSettingHint;

  /// No description provided for @startScenarioStartMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'시작 메시지'**
  String get startScenarioStartMessageLabel;

  /// No description provided for @startScenarioStartMessageHint.
  ///
  /// In ko, this message translates to:
  /// **'시작 메시지를 입력해주세요'**
  String get startScenarioStartMessageHint;

  /// No description provided for @personaTitle.
  ///
  /// In ko, this message translates to:
  /// **'페르소나'**
  String get personaTitle;

  /// No description provided for @personaTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 페르소나 정보를 추가할 수 있습니다.'**
  String get personaTitleHelp;

  /// No description provided for @personaEmpty.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 항목이 없습니다'**
  String get personaEmpty;

  /// No description provided for @personaAddButton.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 추가'**
  String get personaAddButton;

  /// No description provided for @personaNewName.
  ///
  /// In ko, this message translates to:
  /// **'새 페르소나'**
  String get personaNewName;

  /// No description provided for @personaNameHint.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 이름'**
  String get personaNameHint;

  /// No description provided for @personaContentLabel.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get personaContentLabel;

  /// No description provided for @personaContentHint.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 내용을 입력해주세요'**
  String get personaContentHint;

  /// No description provided for @coverImageTitle.
  ///
  /// In ko, this message translates to:
  /// **'표지'**
  String get coverImageTitle;

  /// No description provided for @coverImageTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터의 표지 이미지를 추가할 수 있습니다.'**
  String get coverImageTitleHelp;

  /// No description provided for @coverImageEmpty.
  ///
  /// In ko, this message translates to:
  /// **'표지 이미지가 없습니다'**
  String get coverImageEmpty;

  /// No description provided for @coverImageAddButton.
  ///
  /// In ko, this message translates to:
  /// **'표지 이미지 추가'**
  String get coverImageAddButton;

  /// No description provided for @coverImageDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'표지 {index}'**
  String coverImageDefaultName(int index);

  /// No description provided for @coverImageSaveError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 저장 중 오류가 발생했습니다: {error}'**
  String coverImageSaveError(String error);

  /// No description provided for @additionalImageTitle.
  ///
  /// In ko, this message translates to:
  /// **'추가 이미지'**
  String get additionalImageTitle;

  /// No description provided for @additionalImageTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터에 관련된 참고 이미지를 추가할 수 있습니다.'**
  String get additionalImageTitleHelp;

  /// No description provided for @additionalImageEmpty.
  ///
  /// In ko, this message translates to:
  /// **'추가 이미지가 없습니다'**
  String get additionalImageEmpty;

  /// No description provided for @additionalImageAddButton.
  ///
  /// In ko, this message translates to:
  /// **'이미지 추가'**
  String get additionalImageAddButton;

  /// No description provided for @additionalImageDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'이미지 {index}'**
  String additionalImageDefaultName(int index);

  /// No description provided for @additionalImageSaveError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 저장 중 오류가 발생했습니다: {error}'**
  String additionalImageSaveError(String error);

  /// No description provided for @detailSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'세계관 설정'**
  String get detailSettingsTitle;

  /// No description provided for @detailSettingsTitleHelp.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터가 속한 세계관이나 배경 설정을 자유롭게 작성해주세요.'**
  String get detailSettingsTitleHelp;

  /// No description provided for @detailSettingsHint.
  ///
  /// In ko, this message translates to:
  /// **'세계관 설정을 입력해주세요.'**
  String get detailSettingsHint;

  /// No description provided for @chatBottomPanelTitle.
  ///
  /// In ko, this message translates to:
  /// **'뷰어'**
  String get chatBottomPanelTitle;

  /// No description provided for @chatBottomPanelFontSize.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기'**
  String get chatBottomPanelFontSize;

  /// No description provided for @chatBottomPanelLineHeight.
  ///
  /// In ko, this message translates to:
  /// **'줄 간격'**
  String get chatBottomPanelLineHeight;

  /// No description provided for @chatBottomPanelParagraphSpacing.
  ///
  /// In ko, this message translates to:
  /// **'문단 간격'**
  String get chatBottomPanelParagraphSpacing;

  /// No description provided for @chatBottomPanelParagraphWidth.
  ///
  /// In ko, this message translates to:
  /// **'문단 너비'**
  String get chatBottomPanelParagraphWidth;

  /// No description provided for @chatBottomPanelParagraphAlign.
  ///
  /// In ko, this message translates to:
  /// **'문단 정렬'**
  String get chatBottomPanelParagraphAlign;

  /// No description provided for @chatBottomPanelAlignLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽'**
  String get chatBottomPanelAlignLeft;

  /// No description provided for @chatBottomPanelAlignJustify.
  ///
  /// In ko, this message translates to:
  /// **'양쪽'**
  String get chatBottomPanelAlignJustify;

  /// No description provided for @tutorialStepGoogleAiAccess.
  ///
  /// In ko, this message translates to:
  /// **'Google AI Studio 접속'**
  String get tutorialStepGoogleAiAccess;

  /// No description provided for @tutorialStepGoogleAiPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 계정 생성 (유료 모델 사용 시 필요)'**
  String get tutorialStepGoogleAiPayment;

  /// No description provided for @tutorialStepGetApiKey.
  ///
  /// In ko, this message translates to:
  /// **'Get API Key 클릭'**
  String get tutorialStepGetApiKey;

  /// No description provided for @tutorialStepCreateApiKey.
  ///
  /// In ko, this message translates to:
  /// **'Create API Key 선택'**
  String get tutorialStepCreateApiKey;

  /// No description provided for @tutorialStepCopyKey.
  ///
  /// In ko, this message translates to:
  /// **'생성된 키를 복사하여 위에 붙여넣기'**
  String get tutorialStepCopyKey;

  /// No description provided for @tutorialStepVertexAccess.
  ///
  /// In ko, this message translates to:
  /// **'Google Cloud Console 접속'**
  String get tutorialStepVertexAccess;

  /// No description provided for @tutorialStepVertexBilling.
  ///
  /// In ko, this message translates to:
  /// **'결제 계정 생성 및 프로젝트에 연결'**
  String get tutorialStepVertexBilling;

  /// No description provided for @tutorialStepVertexServiceAccount.
  ///
  /// In ko, this message translates to:
  /// **'IAM → 서비스 계정 → 계정 생성'**
  String get tutorialStepVertexServiceAccount;

  /// No description provided for @tutorialStepVertexRole.
  ///
  /// In ko, this message translates to:
  /// **'Vertex AI User 역할 부여'**
  String get tutorialStepVertexRole;

  /// No description provided for @tutorialStepVertexCreateKey.
  ///
  /// In ko, this message translates to:
  /// **'키 만들기 → JSON → 다운로드'**
  String get tutorialStepVertexCreateKey;

  /// No description provided for @tutorialStepOpenaiAccess.
  ///
  /// In ko, this message translates to:
  /// **'OpenAI Platform 접속'**
  String get tutorialStepOpenaiAccess;

  /// No description provided for @tutorialStepApiKeysMenu.
  ///
  /// In ko, this message translates to:
  /// **'API Keys 메뉴 선택'**
  String get tutorialStepApiKeysMenu;

  /// No description provided for @tutorialStepCreateSecretKey.
  ///
  /// In ko, this message translates to:
  /// **'Create new secret key 클릭'**
  String get tutorialStepCreateSecretKey;

  /// No description provided for @tutorialStepAnthropicAccess.
  ///
  /// In ko, this message translates to:
  /// **'Anthropic Console 접속'**
  String get tutorialStepAnthropicAccess;

  /// No description provided for @tutorialStepAnthropicCreate.
  ///
  /// In ko, this message translates to:
  /// **'Create Key 클릭'**
  String get tutorialStepAnthropicCreate;

  /// No description provided for @tutorialModelPrice.
  ///
  /// In ko, this message translates to:
  /// **'입력 {inputPrice}/1M · 출력 {outputPrice}/1M'**
  String tutorialModelPrice(String inputPrice, String outputPrice);

  /// No description provided for @legalDocumentKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get legalDocumentKorean;

  /// No description provided for @newsTopicPolitics.
  ///
  /// In ko, this message translates to:
  /// **'정치'**
  String get newsTopicPolitics;

  /// No description provided for @newsTopicSociety.
  ///
  /// In ko, this message translates to:
  /// **'사회'**
  String get newsTopicSociety;

  /// No description provided for @newsTopicEntertainment.
  ///
  /// In ko, this message translates to:
  /// **'연예'**
  String get newsTopicEntertainment;

  /// No description provided for @newsTopicEconomy.
  ///
  /// In ko, this message translates to:
  /// **'경제'**
  String get newsTopicEconomy;

  /// No description provided for @newsTopicCulture.
  ///
  /// In ko, this message translates to:
  /// **'문화'**
  String get newsTopicCulture;

  /// No description provided for @toolListCharacters.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 목록 조회'**
  String get toolListCharacters;

  /// No description provided for @toolGetCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 상세 조회'**
  String get toolGetCharacter;

  /// No description provided for @toolCreateCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 생성'**
  String get toolCreateCharacter;

  /// No description provided for @toolUpdateCharacter.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 수정'**
  String get toolUpdateCharacter;

  /// No description provided for @toolCreatePersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 생성'**
  String get toolCreatePersona;

  /// No description provided for @toolUpdatePersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 수정'**
  String get toolUpdatePersona;

  /// No description provided for @toolDeletePersona.
  ///
  /// In ko, this message translates to:
  /// **'페르소나 삭제'**
  String get toolDeletePersona;

  /// No description provided for @toolCreateStartScenario.
  ///
  /// In ko, this message translates to:
  /// **'시작 시나리오 생성'**
  String get toolCreateStartScenario;

  /// No description provided for @toolUpdateStartScenario.
  ///
  /// In ko, this message translates to:
  /// **'시작 시나리오 수정'**
  String get toolUpdateStartScenario;

  /// No description provided for @toolDeleteStartScenario.
  ///
  /// In ko, this message translates to:
  /// **'시작 시나리오 삭제'**
  String get toolDeleteStartScenario;

  /// No description provided for @toolCreateCharacterBook.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터북 생성'**
  String get toolCreateCharacterBook;

  /// No description provided for @toolUpdateCharacterBook.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터북 수정'**
  String get toolUpdateCharacterBook;

  /// No description provided for @toolDeleteCharacterBook.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터북 삭제'**
  String get toolDeleteCharacterBook;

  /// No description provided for @apiKeyLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'API 키 불러오기 실패: {error}'**
  String apiKeyLoadFailed(String error);

  /// No description provided for @apiKeyServiceAccountLabel.
  ///
  /// In ko, this message translates to:
  /// **'(서비스 계정 JSON)'**
  String get apiKeyServiceAccountLabel;

  /// No description provided for @apiKeyValidationFailed.
  ///
  /// In ko, this message translates to:
  /// **'API 키 검증 실패'**
  String get apiKeyValidationFailed;

  /// No description provided for @apiKeySaved.
  ///
  /// In ko, this message translates to:
  /// **'{apiKeyType} API 키가 저장되었습니다'**
  String apiKeySaved(String apiKeyType);

  /// No description provided for @chatPromptEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'+ 버튼을 눌러 새 프롬프트를 추가해보세요'**
  String get chatPromptEmptyHint;

  /// No description provided for @chatPromptItemCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목'**
  String chatPromptItemCount(int count);

  /// No description provided for @customModelSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'{format} · {count}개 모델'**
  String customModelSubtitle(String format, int count);

  /// No description provided for @agentChatDescription.
  ///
  /// In ko, this message translates to:
  /// **'Flan Agent는 캐릭터를 생성하거나 편집할 수 있습니다. 원하는 캐릭터 제작 및 수정을 요청해 보세요.'**
  String get agentChatDescription;

  /// No description provided for @diaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'{author}의 일기'**
  String diaryTitle(String author);

  /// No description provided for @characterCardOutfitLabel.
  ///
  /// In ko, this message translates to:
  /// **'의상 '**
  String get characterCardOutfitLabel;

  /// No description provided for @characterCardMemoLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모 '**
  String get characterCardMemoLabel;

  /// No description provided for @modelPresetPrimary.
  ///
  /// In ko, this message translates to:
  /// **'주 모델'**
  String get modelPresetPrimary;

  /// No description provided for @modelPresetSecondary.
  ///
  /// In ko, this message translates to:
  /// **'보조 모델'**
  String get modelPresetSecondary;

  /// No description provided for @modelPresetCustom.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get modelPresetCustom;

  /// No description provided for @agentEntryTypeEpisode.
  ///
  /// In ko, this message translates to:
  /// **'요약'**
  String get agentEntryTypeEpisode;

  /// No description provided for @agentEntryTypeCharacter.
  ///
  /// In ko, this message translates to:
  /// **'등장인물'**
  String get agentEntryTypeCharacter;

  /// No description provided for @agentEntryTypeLocation.
  ///
  /// In ko, this message translates to:
  /// **'지역/장소'**
  String get agentEntryTypeLocation;

  /// No description provided for @agentEntryTypeItem.
  ///
  /// In ko, this message translates to:
  /// **'물품'**
  String get agentEntryTypeItem;

  /// No description provided for @agentEntryTypeEvent.
  ///
  /// In ko, this message translates to:
  /// **'업적/사건'**
  String get agentEntryTypeEvent;

  /// No description provided for @settingsAiResponseLanguageOthers.
  ///
  /// In ko, this message translates to:
  /// **'기타 (직접 입력)'**
  String get settingsAiResponseLanguageOthers;

  /// No description provided for @settingsAiResponseLanguageOthersTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 응답 언어 입력'**
  String get settingsAiResponseLanguageOthersTitle;

  /// No description provided for @settingsAiResponseLanguageOthersHint.
  ///
  /// In ko, this message translates to:
  /// **'언어 이름 입력 (예: French)'**
  String get settingsAiResponseLanguageOthersHint;

  /// No description provided for @settingsAiResponseLanguageOthersLabel.
  ///
  /// In ko, this message translates to:
  /// **'언어 이름'**
  String get settingsAiResponseLanguageOthersLabel;
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
