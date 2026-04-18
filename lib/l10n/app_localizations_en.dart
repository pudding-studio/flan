// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navCharacter => 'Characters';

  @override
  String get navChat => 'Chats';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonMore => 'More';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonModify => 'Modify';

  @override
  String get commonCopyItem => 'Copy';

  @override
  String get commonExport => 'Export';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonDefault => 'Default';

  @override
  String get commonLabelName => 'Name';

  @override
  String get commonNumberHint => 'Enter a number';

  @override
  String get commonAddItem => 'Add Item';

  @override
  String get commonAddFolder => 'Add Folder';

  @override
  String get commonEmptyList => 'No items';

  @override
  String get commonDeleteConfirmTitle => 'Confirm Delete';

  @override
  String commonDeleteConfirmContent(String itemName) {
    return 'Delete $itemName?';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionChat => 'Chat';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionEtc => 'Other';

  @override
  String get settingsSectionInfo => 'Info';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get settingsThemeLight => 'Light Mode';

  @override
  String get settingsThemeDark => 'Dark Mode';

  @override
  String get settingsThemeColor => 'Theme Color';

  @override
  String get settingsThemeColorDefault => 'Default';

  @override
  String get settingsLanguage => 'App Language';

  @override
  String get settingsLanguageSystem => 'System Default';

  @override
  String get settingsAiResponseLanguage => 'AI Response';

  @override
  String get settingsAiResponseLanguageAuto => 'App Language';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settingsApiKey => 'API Key';

  @override
  String get settingsChatModel => 'Chat Model';

  @override
  String get settingsTokenizer => 'Tokenizer';

  @override
  String get settingsChatPrompt => 'Chat Prompt';

  @override
  String get settingsAutoSummary => 'Auto Summary';

  @override
  String get settingsAutoSummarySubtitle => 'Global auto summary settings';

  @override
  String get settingsBackup => 'Backup & Restore';

  @override
  String get settingsBackupSubtitle => 'Export / Import data';

  @override
  String get settingsStatistics => 'Statistics';

  @override
  String get settingsStatisticsSubtitle => 'Model usage and cost by date';

  @override
  String get settingsLog => 'Logs';

  @override
  String get settingsLogSubtitle => 'View API request/response logs';

  @override
  String get settingsTutorial => 'Run Initial Setup Again';

  @override
  String get settingsTutorialSubtitle => 'API key and model setup tutorial';

  @override
  String get settingsAppInfo => 'App Info';

  @override
  String settingsAppInfoSubtitle(String version) {
    return 'Version $version';
  }

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsAboutDescription => 'An app for chatting with AI characters.';

  @override
  String get characterTitle => 'Characters';

  @override
  String characterSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get characterEmptyTitle => 'No characters';

  @override
  String get characterEmptySubtitle => 'Tap + to add a new character';

  @override
  String get characterDeleteSelectedTitle => 'Delete Characters';

  @override
  String characterDeleteSelectedContent(int count) {
    return 'Delete $count selected character(s)? All related data will be removed.';
  }

  @override
  String get characterDeleteOneContent => 'Delete this character? All related data will be removed.';

  @override
  String get characterDeletedSelected => 'Selected characters deleted';

  @override
  String get characterDeleted => 'Character deleted';

  @override
  String characterDeleteFailed(String error) {
    return 'Failed to delete character: $error';
  }

  @override
  String get characterCopied => 'Character copied';

  @override
  String characterCopyFailed(String error) {
    return 'Failed to copy character: $error';
  }

  @override
  String characterLoadFailed(String error) {
    return 'Failed to load characters: $error';
  }

  @override
  String characterReorderFailed(String error) {
    return 'Failed to reorder: $error';
  }

  @override
  String get characterImportSuccess => 'Character imported successfully';

  @override
  String characterImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get characterImport => 'Import';

  @override
  String get characterViewMode => 'View Mode';

  @override
  String get characterViewGrid => 'Grid';

  @override
  String get characterViewList => 'List';

  @override
  String get characterThemeSelect => 'Select Theme';

  @override
  String get characterFlanAgentTooltip => 'Flan Agent';

  @override
  String get characterAgentHighlightTooltip => 'Tap here to create a character!';

  @override
  String characterSortLabel(String label) {
    return 'Sort: $label';
  }

  @override
  String get characterSortNameAsc => 'Name (A → Z)';

  @override
  String get characterSortNameDesc => 'Name (Z → A)';

  @override
  String get characterSortUpdatedAtAsc => 'Last Modified (Oldest)';

  @override
  String get characterSortUpdatedAtDesc => 'Last Modified (Newest)';

  @override
  String get characterSortCreatedAtAsc => 'Created (Oldest)';

  @override
  String get characterSortCreatedAtDesc => 'Created (Newest)';

  @override
  String get characterSortCustom => 'Custom';

  @override
  String get chatTitle => 'Chats';

  @override
  String chatSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get chatEmptyTitle => 'No chats';

  @override
  String get chatEmptySubtitle => 'Select a character to start a new chat';

  @override
  String get chatNoMessages => 'No messages';

  @override
  String get chatSortMethod => 'Sort By';

  @override
  String get chatSortRecent => 'Recently Updated';

  @override
  String get chatSortName => 'Name';

  @override
  String get chatSortMessageCount => 'Message Count';

  @override
  String get chatRoomDeleteTitle => 'Delete Chat';

  @override
  String chatRoomDeleteSelectedContent(int count) {
    return 'Delete $count selected chat(s)?\nAll messages will be removed.';
  }

  @override
  String chatRoomDeleteOneContent(String name) {
    return 'Delete \'$name\'?\nAll messages will be removed.';
  }

  @override
  String get chatRoomDeletedSelected => 'Selected chats deleted';

  @override
  String get chatRoomDeleted => 'Chat deleted';

  @override
  String get chatRoomDeleteFailed => 'Failed to delete chat';

  @override
  String get chatRoomRenameTitle => 'Rename Chat';

  @override
  String get chatRoomRenameHint => 'Chat name';

  @override
  String get chatRoomRenameFailed => 'Failed to rename chat';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String chatDateDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String chatDateWeeksAgo(int weeks) {
    return '${weeks}w ago';
  }

  @override
  String chatDateMonthsAgo(int months) {
    return '${months}mo ago';
  }

  @override
  String chatDateYearsAgo(int years) {
    return '${years}y ago';
  }

  @override
  String get tutorialPrevious => 'Back';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialStart => 'Get Started';

  @override
  String tutorialStep(int step) {
    return 'STEP $step';
  }

  @override
  String get tutorialWelcomeTitle => 'Welcome to Flan';

  @override
  String get tutorialWelcomeBody => 'Chat with AI characters and build your own world.\nLet\'s get you set up quickly.';

  @override
  String get tutorialApiKeyTitle => 'API Key Setup';

  @override
  String get tutorialApiKeyDesc => 'An API key is required to use AI models.\nSelect a service and enter your key.';

  @override
  String get tutorialApiKeyHint => 'Enter your API key';

  @override
  String get tutorialApiKeyEmpty => 'Please enter an API key';

  @override
  String tutorialApiKeySaved(String provider) {
    return '$provider API key saved';
  }

  @override
  String get tutorialVertexSaved => 'Vertex AI service account registered';

  @override
  String tutorialApiKeySaveFailed(String error) {
    return 'Failed to save API key: $error';
  }

  @override
  String get tutorialVertexImport => 'Import Service Account JSON';

  @override
  String get tutorialVertexValidationFailed => 'Service account validation failed';

  @override
  String tutorialJsonReadFailed(String error) {
    return 'Failed to read JSON: $error';
  }

  @override
  String get tutorialReRegister => 'Re-register';

  @override
  String get tutorialReInput => 'Re-enter';

  @override
  String get tutorialModelTitle => 'Model Setup';

  @override
  String get tutorialModelDesc => 'Choose AI models for chat and assistant features.';

  @override
  String get tutorialMainModel => 'Main Model';

  @override
  String get tutorialSubModel => 'Sub Model';

  @override
  String get tutorialMainDescGemini => 'Used for chat. Gemini 3.1 Pro recommended.';

  @override
  String get tutorialSubDescGemini => 'Used for summaries, SNS, news, etc. Gemini 3 Flash recommended.';

  @override
  String get tutorialMainDescOpenai => 'Used for chat. GPT-5.4 recommended.';

  @override
  String get tutorialSubDescOpenai => 'Used for summaries, SNS, news, etc. GPT-5.4 Mini recommended.';

  @override
  String get tutorialMainDescAnthropic => 'Used for chat. Claude Sonnet 4.6 recommended.';

  @override
  String get tutorialSubDescAnthropic => 'Used for summaries, SNS, news, etc. Claude Haiku 4.5 recommended.';

  @override
  String get tutorialModelRecommended => 'Recommended';

  @override
  String get tutorialCompleteTitle => 'You\'re all set!';

  @override
  String get tutorialCompleteSubtitle => 'Ready to create your first character?';

  @override
  String get tutorialAgentBoxTitle => 'Flan Agent';

  @override
  String get tutorialAgentBoxSubtitle => 'Tap the glowing icon at the top of the Characters tab';

  @override
  String get tutorialAgentBoxBody => 'Ask the Agent to create any character you want!\nTry something like \"Create an elven mage from a fantasy world\".';

  @override
  String get tutorialHelpGoogleAi => 'Get a Google AI Studio API key';

  @override
  String get tutorialHelpVertex => 'Set up a Vertex AI service account';

  @override
  String get tutorialHelpOpenai => 'Get an OpenAI API key';

  @override
  String get tutorialHelpAnthropic => 'Get an Anthropic API key';

  @override
  String get drawerTabInfo => 'Info';

  @override
  String get drawerTabPersona => 'Persona';

  @override
  String get drawerTabCharacter => 'Character';

  @override
  String get drawerTabLorebook => 'Lorebook';

  @override
  String get drawerTabSummary => 'Summary';

  @override
  String get drawerChatMemo => 'Chat Memo';

  @override
  String get drawerMemoHint => 'Enter a memo';

  @override
  String get drawerChatSettings => 'Chat Settings';

  @override
  String get drawerModelPreset => 'Model Settings';

  @override
  String get drawerProvider => 'Provider';

  @override
  String get drawerChatModel => 'Chat Model';

  @override
  String get drawerChatPrompt => 'Chat Prompt';

  @override
  String get drawerNone => 'None';

  @override
  String get drawerPromptPreset => 'Prompt Preset';

  @override
  String get drawerShowImages => 'Show Images';

  @override
  String get drawerNoName => 'No Name';

  @override
  String get drawerSelectItem => 'Select an item';

  @override
  String get drawerOther => 'Other';

  @override
  String get drawerEnterValue => 'Enter a value';

  @override
  String get drawerSelectPersona => 'Select Persona';

  @override
  String get drawerCreateNewPersona => '+ Create New Persona';

  @override
  String get drawerNewPersona => 'New Persona';

  @override
  String get drawerPersonaName => 'Persona Name';

  @override
  String get drawerPersonaDescription => 'Persona Description';

  @override
  String get drawerPersonaDescriptionHint => 'Enter a persona description';

  @override
  String get drawerCharacter => 'Character';

  @override
  String get drawerCharacterDescriptionHint => 'Enter character settings';

  @override
  String get drawerLorebookEmpty => 'No lorebook entries';

  @override
  String get drawerBookNameHint => 'Entry name';

  @override
  String get drawerBookActivationCondition => 'Activation Condition';

  @override
  String get drawerBookSecondaryKey => 'Secondary Key';

  @override
  String get drawerBookActivationKey => 'Activation Key';

  @override
  String get drawerBookKeysHint => 'Separate with commas';

  @override
  String get drawerBookSecondaryKeysHint => 'Separate with commas (e.g. magic, battle)';

  @override
  String get drawerBookInsertionOrder => 'Insertion Order';

  @override
  String get drawerBookContent => 'Content';

  @override
  String get drawerBookContentHint => 'Enter entry content';

  @override
  String get drawerAutoSummary => 'Auto Summary';

  @override
  String get drawerAgentMode => 'Agent Mode';

  @override
  String get drawerSummaryMessageCount => 'Summary Message Count';

  @override
  String get drawerMessageCountHint => 'Message count';

  @override
  String get drawerAutoSummaryList => 'Auto Summary List';

  @override
  String drawerSummaryCount(int count) {
    return '$count';
  }

  @override
  String get drawerNoSummaries => 'No auto summaries.\nEnable auto summary in settings.';

  @override
  String get drawerSummaryContentHint => 'Summary content';

  @override
  String get drawerGenerating => 'Generating...';

  @override
  String get drawerRegenerate => 'Regenerate';

  @override
  String get drawerActive => 'Active';

  @override
  String get drawerInactive => 'Inactive';

  @override
  String get drawerNameLabel => 'Name';

  @override
  String get drawerNameHint => 'Name';

  @override
  String get drawerAddSummaryButton => 'Add Summary at Current Message';

  @override
  String get drawerNoMessages => 'No messages';

  @override
  String get drawerNoNewMessages => 'No new messages to summarize';

  @override
  String get drawerSummaryAdded => 'Summary added. Please enter the content.';

  @override
  String drawerSummaryAddFailed(String error) {
    return 'Failed to add summary: $error';
  }

  @override
  String get drawerSummaryRegenerated => 'Summary regenerated';

  @override
  String drawerSummaryRegenerateFailed(String error) {
    return 'Failed to regenerate summary: $error';
  }

  @override
  String get drawerSummaryItemName => 'This Summary';

  @override
  String get drawerSummaryDeleted => 'Summary deleted';

  @override
  String drawerSummaryDeleteFailed(String error) {
    return 'Failed to delete summary: $error';
  }

  @override
  String drawerAgentEntryEmpty(String type) {
    return 'No $type data.\nIt will be generated automatically as the chat progresses.';
  }

  @override
  String drawerAgentEntrySaved(String name) {
    return '$name saved';
  }

  @override
  String drawerAgentEntryDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get agentFieldDateRange => 'Date/Time';

  @override
  String get agentFieldCharacters => 'Characters';

  @override
  String get agentFieldCharactersList => 'Characters (comma-separated)';

  @override
  String get agentFieldLocations => 'Locations';

  @override
  String get agentFieldLocationsList => 'Locations (comma-separated)';

  @override
  String get agentFieldSummary => 'Summary';

  @override
  String get agentFieldAppearance => 'Appearance';

  @override
  String get agentFieldPersonality => 'Personality';

  @override
  String get agentFieldPast => 'Background';

  @override
  String get agentFieldAbilities => 'Abilities';

  @override
  String get agentFieldStoryActions => 'Story Actions';

  @override
  String get agentFieldDialogueStyle => 'Dialogue Style';

  @override
  String get agentFieldPossessions => 'Possessions';

  @override
  String get agentFieldPossessionsList => 'Possessions (comma-separated)';

  @override
  String get agentFieldParentLocation => 'Location';

  @override
  String get agentFieldFeatures => 'Features';

  @override
  String get agentFieldAsciiMap => 'Map';

  @override
  String get agentFieldRelatedEpisodes => 'Related Episodes';

  @override
  String get agentFieldRelatedEpisodesList => 'Related Episodes (comma-separated)';

  @override
  String get agentFieldKeywords => 'Keywords';

  @override
  String get agentFieldDatetime => 'Date & Time';

  @override
  String get agentFieldOverview => 'Overview';

  @override
  String get agentFieldResult => 'Result';

  @override
  String get chatRoomNotFound => 'Chat not found';

  @override
  String get chatRoomCannotLoad => 'Failed to load chat';

  @override
  String chatRoomMessageSendFailed(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String get chatRoomMessageItemName => 'This Message';

  @override
  String get chatRoomMessageDeleted => 'Message deleted';

  @override
  String get chatRoomMessageDeleteFailed => 'Failed to delete message';

  @override
  String get chatRoomMessageEdited => 'Message edited';

  @override
  String get chatRoomMessageEditFailed => 'Failed to edit message';

  @override
  String chatRoomMessageRetryFailed(String error) {
    return 'Failed to retry message: $error';
  }

  @override
  String chatRoomMessageRegenerateFailed(String error) {
    return 'Failed to regenerate message: $error';
  }

  @override
  String chatRoomMainModelLoadFailed(String modelId) {
    return 'Failed to load the main model \'$modelId\'. Please re-select it in chat model settings.';
  }

  @override
  String chatRoomSubModelLoadFailed(String modelId) {
    return 'Failed to load the sub model \'$modelId\'. Please re-select it in chat model settings.';
  }

  @override
  String chatRoomCustomModelLoadFailed(String modelId) {
    return 'Failed to load this chat room\'s assigned model \'$modelId\'. Please re-select a model in the chat room settings.';
  }

  @override
  String chatRoomPromptLoadFailed(String promptId) {
    return 'Failed to load the chat prompt (id: $promptId). Please re-select a prompt in the chat room settings.';
  }

  @override
  String get chatRoomTextSettings => 'Text Settings';

  @override
  String get chatRoomBranchTitle => 'Create Branch';

  @override
  String get chatRoomBranchContent => 'Create a new branch up to this message?';

  @override
  String get chatRoomBranchConfirm => 'Create';

  @override
  String get chatRoomBranchCreated => 'Branch created';

  @override
  String get chatRoomBranchFailed => 'Failed to create branch';

  @override
  String get chatRoomWarningTitle => 'Notice';

  @override
  String get chatRoomWarningDesc => 'All AI responses are auto-generated and may be biased or inaccurate.';

  @override
  String get chatRoomStartSetting => 'Start Setting';

  @override
  String get chatRoomNoStats => 'No stats available';

  @override
  String get chatRoomStatsTitle => 'Response Stats';

  @override
  String get chatRoomStatModel => 'Model';

  @override
  String get chatRoomStatInputTokens => 'Input Tokens';

  @override
  String get chatRoomStatCachedTokens => 'Cached Tokens';

  @override
  String get chatRoomStatCacheRatio => 'Cache Ratio';

  @override
  String get chatRoomStatOutputTokens => 'Output Tokens';

  @override
  String get chatRoomStatThoughtTokens => 'Thinking Tokens';

  @override
  String get chatRoomStatThoughtRatio => 'Thinking Ratio';

  @override
  String get chatRoomStatTotalTokens => 'Total Tokens';

  @override
  String get chatRoomStatEstimatedCost => 'Estimated Cost';

  @override
  String get chatRoomMessageSearch => 'Search messages...';

  @override
  String get chatRoomSearchTooltip => 'Search';

  @override
  String get chatRoomNewMessages => 'New messages';

  @override
  String get chatRoomGenerating => 'Generating...';

  @override
  String chatRoomRetrying(int attempt) {
    return 'Retrying ($attempt)...';
  }

  @override
  String get chatRoomWaiting => 'Waiting for response...';

  @override
  String get chatRoomSummarizing => 'Summarizing...';

  @override
  String get chatRoomMessageHint => 'Type a message';

  @override
  String get chatRoomDayMon => 'Mon';

  @override
  String get chatRoomDayTue => 'Tue';

  @override
  String get chatRoomDayWed => 'Wed';

  @override
  String get chatRoomDayThu => 'Thu';

  @override
  String get chatRoomDayFri => 'Fri';

  @override
  String get chatRoomDaySat => 'Sat';

  @override
  String get chatRoomDaySun => 'Sun';

  @override
  String get chatRoomDay => 'Day';

  @override
  String get chatRoomNight => 'Night';

  @override
  String characterEditDataLoadFailed(String error) {
    return 'Failed to load data: $error';
  }

  @override
  String get characterEditDraftFoundTitle => 'Unsaved Draft Found';

  @override
  String characterEditDraftFoundContent(String timestamp) {
    return 'There is unsaved draft data.\nLast edited: $timestamp\n\nWould you like to restore it?';
  }

  @override
  String get characterEditDraftLoad => 'Restore';

  @override
  String get characterEditJustNow => 'Just now';

  @override
  String characterEditMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String characterEditHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String characterEditDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get characterEditNameRequired => 'Please enter a character name';

  @override
  String get characterEditCreated => 'Character created';

  @override
  String get characterEditUpdated => 'Character updated';

  @override
  String characterEditSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get characterEditTitleNew => 'Create Character';

  @override
  String get characterEditTitleEdit => 'Edit Character';

  @override
  String get characterEditTabProfile => 'Profile';

  @override
  String get characterEditTabCharacter => 'Character';

  @override
  String get characterEditTabLorebook => 'Lorebook';

  @override
  String get characterEditTabPersona => 'Persona';

  @override
  String get characterEditTabStartSetting => 'Start Setting';

  @override
  String get characterEditTabCoverImage => 'Cover Image';

  @override
  String get characterEditTabAdditionalImage => 'Extra Images';

  @override
  String get characterEditWorldDateTitle => 'World Start Date';

  @override
  String get characterEditWorldDateHelp => 'The reference date for this character\'s world. Used as the [world_date] keyword in prompts and as the base time for news/SNS generation.';

  @override
  String get characterEditWorldDateHint => 'Select a date';

  @override
  String get characterEditWorldDateClear => 'Clear date';

  @override
  String get characterEditSnsHelp => 'Configure the SNS board settings for this character.';

  @override
  String get characterEditSnsBoardHint => 'e.g. Free Board, Adventurers\' Plaza';

  @override
  String get characterEditSnsToneHint => 'e.g. Humorous and friendly';

  @override
  String get characterEditSnsLanguageHint => 'Language (currently Korean only)';

  @override
  String get characterEditNameLabel => 'Name';

  @override
  String get characterEditNameHelpText => 'Enter the character\'s unique name.';

  @override
  String get characterEditNameHintText => 'Enter the character\'s name.';

  @override
  String get characterEditNicknameLabel => 'Nickname';

  @override
  String get characterEditNicknameHelp => 'Used instead of the char variable in prompts. If empty, the name is used.';

  @override
  String get characterEditNicknameHint => 'Enter the character\'s nickname.';

  @override
  String get characterEditTaglineLabel => 'Tagline';

  @override
  String get characterEditTaglineHelp => 'Write a short sentence describing the character.';

  @override
  String get characterEditTaglineHint => 'Enter a brief intro for this character.';

  @override
  String get characterEditKeywordsLabel => 'Keywords';

  @override
  String get characterEditKeywordsHelp => 'Enter keywords separated by commas (,).';

  @override
  String get characterEditKeywordsHint => 'e.g. fantasy, male';

  @override
  String get characterEditWorldSetting => 'World Setting';

  @override
  String get characterEditWorldSettingHelp => 'Describe the world or background this character belongs to.';

  @override
  String get characterEditWorldSettingHint => 'Enter world setting details.';

  @override
  String get characterExportFormatTitle => 'Select Export Format';

  @override
  String get characterExportFlanFormat => 'Flan Format';

  @override
  String get characterExportFlanSubtitle => 'App-native JSON (includes images)';

  @override
  String get characterExportV2Card => 'Character Card v2';

  @override
  String get characterExportV2Subtitle => 'PNG — some data may be truncated';

  @override
  String get characterExportV3Card => 'Character Card v3';

  @override
  String characterExportSuccessAndroid(String fileName) {
    return 'Exported: /storage/emulated/0/Download/$fileName';
  }

  @override
  String characterExportSuccessIos(String path) {
    return 'Exported: $path';
  }

  @override
  String get characterExportSaveFailed => 'Failed to save file';

  @override
  String get characterCoverDefault => 'Cover 1';

  @override
  String characterCopyName(String name) {
    return '$name (Copy)';
  }

  @override
  String get autoSummaryTitle => 'Auto Summary';

  @override
  String get autoSummarySaveFailed => 'Save failed';

  @override
  String autoSummaryExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get autoSummaryResetTitle => 'Reset';

  @override
  String get autoSummaryResetContent => 'Reset the summary prompt to the latest default?';

  @override
  String get autoSummaryResetConfirm => 'Reset';

  @override
  String get autoSummaryResetSuccess => 'Summary prompt reset';

  @override
  String autoSummaryResetFailed(String error) {
    return 'Failed to reset summary prompt: $error';
  }

  @override
  String get autoSummaryInvalidFormat => 'Invalid summary prompt format';

  @override
  String get autoSummaryEmptyItems => 'Prompt items are empty';

  @override
  String get autoSummaryImportSuccess => 'Summary prompt imported';

  @override
  String autoSummaryImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get autoSummaryTabBasic => 'Basic';

  @override
  String get autoSummaryTabParameters => 'Parameters';

  @override
  String get autoSummaryTabPrompt => 'Prompt';

  @override
  String get autoSummarySection => 'Auto Summary Settings';

  @override
  String get autoSummaryEnableTitle => 'Auto Summary';

  @override
  String get autoSummaryEnableSubtitle => 'Automatically summarizes when token limit is exceeded';

  @override
  String get autoSummaryAgentTitle => 'Agent Mode';

  @override
  String get autoSummaryAgentSubtitle => 'Automatically manages structured world data';

  @override
  String get autoSummaryModelSection => 'Summary Model';

  @override
  String get autoSummaryUseSubModel => 'Use Sub Model';

  @override
  String get autoSummaryUseSubModelSubtitle => 'Uses the sub model from chat model settings';

  @override
  String get autoSummaryStartCondition => 'Auto Summary Trigger';

  @override
  String get autoSummaryTokenHint => 'Enter token count';

  @override
  String get autoSummaryPeriod => 'Summary Interval';

  @override
  String get autoSummaryMaxResponseSize => 'Max Response Size';

  @override
  String get autoSummaryMaxResponseHelp => 'Maximum tokens the model can generate.';

  @override
  String get autoSummaryTemperature => 'Temperature';

  @override
  String get autoSummaryTemperatureHelp => 'Higher values produce more creative and varied responses.';

  @override
  String get autoSummaryTopPHelp => 'Cumulative probability threshold. Lower values produce more focused responses.';

  @override
  String get autoSummaryTopKHelp => 'Number of top tokens to consider.';

  @override
  String get autoSummaryPresencePenalty => 'Presence Penalty';

  @override
  String get autoSummaryPresencePenaltyHelp => 'Positive values encourage new topics; negative values focus on existing ones.';

  @override
  String get autoSummaryFrequencyPenalty => 'Frequency Penalty';

  @override
  String get autoSummaryFrequencyPenaltyHelp => 'Positive values reduce repetition; negative values increase it.';

  @override
  String get autoSummaryPromptHelp => 'Configure summary prompt items. Messages to summarize are inserted automatically at the \'Summary Target\' role position.\n\nLong-press to reorder.';

  @override
  String get autoSummaryNoItems => 'No prompt items';

  @override
  String get autoSummaryAddItem => 'Add Item';

  @override
  String get autoSummaryResetDefault => 'Reset to Default Prompt';

  @override
  String get autoSummaryImport => 'Import';

  @override
  String get autoSummaryExport => 'Export';

  @override
  String get autoSummaryItemNameHint => 'Item name (e.g. System Prompt)';

  @override
  String get autoSummaryItemRole => 'Role';

  @override
  String get autoSummaryTargetMessageInfo => 'Messages to summarize will be inserted here automatically';

  @override
  String get autoSummaryItemPrompt => 'Prompt';

  @override
  String get autoSummaryItemPromptHint => 'Enter prompt content';

  @override
  String get autoSummaryNoModel => 'No model';

  @override
  String get customModelTitle => 'Custom Models';

  @override
  String get customModelEmpty => 'No custom providers';

  @override
  String get customModelAddProvider => 'Add Provider';

  @override
  String get customModelEditProvider => 'Edit Provider';

  @override
  String get customModelDeleteProviderTitle => 'Delete Provider';

  @override
  String get customModelDeleteModelTitle => 'Delete Model';

  @override
  String get customModelNoExportable => 'No custom models to export';

  @override
  String get customModelSaveFailed => 'Save failed';

  @override
  String customModelExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String customModelImportSuccess(int providerCount, int modelCount) {
    return '$providerCount provider(s), $modelCount model(s) imported';
  }

  @override
  String customModelImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get customModelAddModel => 'Add Model';

  @override
  String get customModelEditModel => 'Edit Model';

  @override
  String get customModelProviderUpdated => 'Provider updated';

  @override
  String get customModelProviderAdded => 'Provider added';

  @override
  String get customModelProviderName => 'Provider Name';

  @override
  String get customModelProviderNameHint => 'e.g. OpenRouter';

  @override
  String get customModelProviderNameRequired => 'Please enter a provider name';

  @override
  String get customModelEndpointHint => 'e.g. https://openrouter.ai/api';

  @override
  String get customModelRetrySection => 'Retry on Failure';

  @override
  String get customModelRetryCount => 'Retry Count';

  @override
  String get customModelEdit => 'Edit';

  @override
  String get customModelAdd => 'Add';

  @override
  String get customModelUpdated => 'Model updated';

  @override
  String get customModelAdded => 'Model added';

  @override
  String get customModelName => 'Model Name';

  @override
  String get customModelNameHint => 'e.g. GPT-4o';

  @override
  String get customModelNameRequired => 'Please enter a model name';

  @override
  String get customModelId => 'Model ID';

  @override
  String get customModelIdHint => 'e.g. openai/gpt-4o';

  @override
  String get customModelIdRequired => 'Please enter a model ID';

  @override
  String get customModelPriceSection => 'Pricing (Optional)';

  @override
  String customModelDeleteProviderWithModels(String name, int count) {
    return 'Delete provider \'$name\' and its $count model(s)?';
  }

  @override
  String customModelDeleteProvider(String name) {
    return 'Delete provider \'$name\'?';
  }

  @override
  String customModelDeleteModel(String name) {
    return 'Delete model \'$name\'?';
  }

  @override
  String get promptEditDefaultName => 'Default';

  @override
  String get promptEditNewFolderName => 'New Folder';

  @override
  String get promptEditDefaultRuleName => 'Regex Rule';

  @override
  String get promptEditDefaultPresetName => 'Preset';

  @override
  String get promptEditDefaultConditionName => 'Condition';

  @override
  String get promptEditUpdated => 'Prompt updated';

  @override
  String get promptEditCreated => 'Prompt created';

  @override
  String promptEditSaveFailed(String error) {
    return 'Failed to save prompt: $error';
  }

  @override
  String get promptEditTitleView => 'View Prompt';

  @override
  String get promptEditTitleEdit => 'Edit Prompt';

  @override
  String get promptEditTitleNew => 'New Prompt';

  @override
  String get promptEditTabBasic => 'Basic';

  @override
  String get promptEditTabParameters => 'Parameters';

  @override
  String get promptEditTabPrompt => 'Prompt';

  @override
  String get promptEditTabRegex => 'Regex';

  @override
  String get promptEditTabOther => 'Other';

  @override
  String get promptEditNameLabel => 'Prompt Name';

  @override
  String get promptEditNameHint => 'e.g. Friendly Helper, Expert Mode';

  @override
  String get promptEditNameRequired => 'Please enter a prompt name';

  @override
  String get promptEditDescriptionTitle => 'Description';

  @override
  String get promptEditDescriptionHint => 'Enter a description for this prompt';

  @override
  String get promptEditMaxInputSize => 'Max Input Size';

  @override
  String get promptEditMaxInputHelp => 'Maximum number of input tokens.';

  @override
  String get promptEditThinkingTokens => 'Thinking Tokens';

  @override
  String get promptEditThinkingHelp => 'Tokens allocated for thinking.';

  @override
  String get promptEditStopStrings => 'Stop Strings';

  @override
  String get promptEditStopStringsHint => 'Enter a string and add';

  @override
  String get promptEditThinkingConfig => 'Thinking Config';

  @override
  String get promptEditThinkingTokenCount => 'Thinking Token Count';

  @override
  String get promptEditThinkingTokenHelp => 'Maximum tokens for thinking.';

  @override
  String get promptEditThinkingLevel => 'Thinking Level';

  @override
  String get chatModelTitle => 'Chat Model';

  @override
  String get chatModelTabMain => 'Main Model';

  @override
  String get chatModelTabSub => 'Sub Model';

  @override
  String get chatModelSubInfo => 'The sub model is used for SNS summaries and similar features.\nChanging it updates the default model for those features.';

  @override
  String get chatModelProviderSection => 'Provider';

  @override
  String get chatModelUsedModelSection => 'Active Model';

  @override
  String get chatModelInfoSection => 'Model Info';

  @override
  String get chatModelManagement => 'Manage Custom Models';

  @override
  String get chatModelApiKeyDeleteContent => 'Delete this API key?';

  @override
  String get chatModelVertexValidationFailed => 'Service account validation failed';

  @override
  String get chatModelNewApiKey => 'New API Key';

  @override
  String get chatModelJsonAdd => 'Add JSON';

  @override
  String get chatModelKeyAdd => 'Add Key';

  @override
  String get chatModelNoApiKey => 'No API keys registered';

  @override
  String get apiKeyMultiInfo => 'You can register multiple API keys per provider.';

  @override
  String chatPromptListLoadFailed(String error) {
    return 'Failed to load prompts: $error';
  }

  @override
  String chatPromptSelectFailed(String error) {
    return 'Failed to select prompt: $error';
  }

  @override
  String get chatPromptDeleted => 'Prompt deleted';

  @override
  String chatPromptDeleteFailed(String error) {
    return 'Failed to delete prompt: $error';
  }

  @override
  String get chatPromptDefaultSelect => 'Select Default Prompt';

  @override
  String get chatPromptEmpty => 'Empty Prompt';

  @override
  String get chatPromptCopied => 'Prompt copied';

  @override
  String chatPromptCopyFailed(String error) {
    return 'Failed to copy prompt: $error';
  }

  @override
  String get chatPromptResetTitle => 'Reset';

  @override
  String get chatPromptResetContent => 'Reset all default prompts to their initial state?';

  @override
  String get chatPromptResetSuccess => 'Default prompts reset';

  @override
  String chatPromptResetFailed(String error) {
    return 'Failed to reset default prompts: $error';
  }

  @override
  String chatPromptExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get chatPromptImportSuccess => 'Prompt imported';

  @override
  String chatPromptImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get chatPromptListEmpty => 'No prompts';

  @override
  String get communityAnonymous => 'Anonymous';

  @override
  String get communityNeedDescription => 'Please write a character description or summary first.';

  @override
  String communityGenerateFailed(String error) {
    return 'Generation failed: $error';
  }

  @override
  String communityRegisterFailed(String error) {
    return 'Registration failed: $error';
  }

  @override
  String get communityWritePost => 'Write Post';

  @override
  String get communityNickname => 'Nickname';

  @override
  String get communityTitle => 'Title';

  @override
  String get communityContent => 'Content';

  @override
  String get communityRegister => 'Post';

  @override
  String get communityWriteComment => 'Write Comment';

  @override
  String get communityCommentContent => 'Comment';

  @override
  String get communityCommentDeleteTitle => 'Delete Comment';

  @override
  String get communityCommentDeleteContent => 'Delete this comment?';

  @override
  String get communityPostDeleteTitle => 'Delete Post';

  @override
  String get communityPostDeleteContent => 'Delete this post?';

  @override
  String get communityDefaultName => 'General';

  @override
  String get communitySettingsTooltip => 'Settings';

  @override
  String get communityRefreshTooltip => 'Generate new posts';

  @override
  String get communityNoPostsTitle => 'No posts yet';

  @override
  String get communityNoPostsSubtitle => 'Pull down to refresh';

  @override
  String get communityCommentLabel => 'Add a comment';

  @override
  String get communityUsedModelSection => 'Active Model';

  @override
  String get communityModelPreset => 'Model Settings';

  @override
  String get communityProvider => 'Provider';

  @override
  String get communityChatModel => 'Chat Model';

  @override
  String get communitySettingsSection => 'Community Settings';

  @override
  String get communityNameLabel => 'Community Name';

  @override
  String get communityToneLabel => 'Community Tone';

  @override
  String get communityLanguageLabel => 'Language';

  @override
  String get characterViewTabInfo => 'Info';

  @override
  String get characterViewTabChat => 'Chats';

  @override
  String get characterViewTagline => 'Tagline';

  @override
  String get characterViewKeywords => 'Keywords';

  @override
  String get characterViewPersona => 'Persona';

  @override
  String get characterViewStartSetting => 'Start Setting';

  @override
  String get characterViewStartContext => 'Start Context';

  @override
  String get characterViewStartMessage => 'Start Message';

  @override
  String get characterViewNewChat => 'New Chat';

  @override
  String get characterViewChatCreateFailed => 'Failed to create chat';

  @override
  String get characterViewNoChats => 'No chats';

  @override
  String get characterViewStartNewChat => 'Start a new chat';

  @override
  String agentChatErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get agentChatResetTitle => 'Reset Conversation';

  @override
  String get agentChatResetContent => 'All conversation history will be cleared. Continue?';

  @override
  String get agentChatResetTooltip => 'Reset conversation';

  @override
  String get agentChatIntro => 'I can help you create, edit, and refine characters';

  @override
  String get agentChatUserLabel => 'Me';

  @override
  String get agentChatUsedModel => 'Active Model';

  @override
  String get agentChatModelPreset => 'Model Settings';

  @override
  String get agentChatProvider => 'Provider';

  @override
  String get agentChatModel => 'Chat Model';

  @override
  String get agentChatWaiting => 'Waiting for response...';

  @override
  String get agentChatHint => 'Type a message';

  @override
  String diaryGenerateFailed(String error) {
    return 'Failed to generate diary: $error';
  }

  @override
  String get diaryGenerateTitle => 'Generate Diary';

  @override
  String diaryGenerateContent(String date) {
    return 'Generate a diary entry for $date?';
  }

  @override
  String get diaryDeleteTitle => 'Delete Diary';

  @override
  String get diaryDeleteContent => 'Delete this diary entry?';

  @override
  String get diaryRegenerateTitle => 'Regenerate Diary';

  @override
  String diaryRegenerateContent(String date) {
    return 'Delete and regenerate the diary for $date?';
  }

  @override
  String get diarySettingsTooltip => 'Settings';

  @override
  String get diaryDaySun => 'Sun';

  @override
  String get diaryDayMon => 'Mon';

  @override
  String get diaryDayTue => 'Tue';

  @override
  String get diaryDayWed => 'Wed';

  @override
  String get diaryDayThu => 'Thu';

  @override
  String get diaryDayFri => 'Fri';

  @override
  String get diaryDaySat => 'Sat';

  @override
  String get diarySelectDate => 'Select a date';

  @override
  String get diaryGenerating => 'Generating diary...';

  @override
  String get diaryNoEntries => 'No diary entries yet';

  @override
  String get diaryRegenerateTooltip => 'Regenerate';

  @override
  String get diaryUsedModel => 'Active Model';

  @override
  String get diaryModelPreset => 'Model Settings';

  @override
  String get diaryProvider => 'Provider';

  @override
  String get diaryChatModel => 'Chat Model';

  @override
  String get diarySettingsSection => 'Diary Settings';

  @override
  String get diaryAutoGenerate => 'Auto Generate';

  @override
  String get diaryAutoGenerateDesc => 'Automatically generates a diary entry when the in-chat date changes.';

  @override
  String get characterBookInvalidFormat => 'Invalid lorebook format';

  @override
  String get characterBookNoImport => 'Nothing to import';

  @override
  String characterBookImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get characterBookNoExport => 'Nothing to export';

  @override
  String get characterBookSaveFailed => 'Save failed';

  @override
  String characterBookExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get characterBookNewFolder => 'New Folder';

  @override
  String get characterBookNewItem => 'New Entry';

  @override
  String get characterBookFolderDeleteTitle => 'Delete Folder';

  @override
  String get characterBookSection => 'Lorebook';

  @override
  String get characterBookSectionHelp => 'Add world-building information related to this character.\n\nLong-press to reorder.';

  @override
  String get characterBookAddItem => 'Add Entry';

  @override
  String get characterBookAddFolder => 'Add Folder';

  @override
  String get characterBookEmpty => 'No lorebook entries';

  @override
  String get characterBookNameHint => 'Entry name';

  @override
  String get characterBookActivationCondition => 'Activation Condition';

  @override
  String get characterBookActivationKey => 'Activation Key';

  @override
  String get characterBookKeysHint => 'Separate with commas (e.g. magic, battle)';

  @override
  String get characterBookSecondaryKey => 'Secondary Key';

  @override
  String get characterBookInsertionOrder => 'Insertion Order';

  @override
  String get characterBookContent => 'Content';

  @override
  String get characterBookContentHint => 'Enter entry content';

  @override
  String get newsArticleDeleteTitle => 'Delete Article';

  @override
  String get newsArticleDeleteContent => 'Delete this article?';

  @override
  String get newsEmptyTitle => 'No articles yet';

  @override
  String get newsEmptySubtitle => 'Pull down to load news';

  @override
  String get newsRefreshTooltip => 'Generate new articles';

  @override
  String get promptItemsTitle => 'Prompt Items';

  @override
  String get promptItemsTitleHelp => 'Add prompt items to send to the AI. They are sent in order.\n\nLong-press to reorder.';

  @override
  String get promptItemsAddItem => 'Add Item';

  @override
  String get promptItemsAddFolder => 'Add Folder';

  @override
  String get promptItemsEmpty => 'No prompt items';

  @override
  String get promptItemsNameHint => 'Item name (e.g. System Prompt, Character Personality)';

  @override
  String get promptItemsLabelEnable => 'Enable';

  @override
  String get promptItemsLabelRole => 'Role';

  @override
  String get promptItemsLabelPrompt => 'Prompt';

  @override
  String get promptItemsPromptHint => 'Define the AI\'s role and response style';

  @override
  String get promptItemsConditionSelect => 'Select Condition';

  @override
  String get promptItemsConditionSelectHint => 'Select a condition';

  @override
  String get promptItemsConditionNoName => 'No Name';

  @override
  String get promptItemsConditionValue => 'Condition Value';

  @override
  String get promptItemsConditionEnabled => 'Enabled';

  @override
  String get promptItemsConditionDisabled => 'Disabled';

  @override
  String get promptItemsSingleSelectItems => 'Options';

  @override
  String get promptItemsSingleSelectHint => 'Select an option';

  @override
  String get promptItemsChatSettings => 'Settings';

  @override
  String get promptItemsRecentChatCount => 'Recent Chat Count';

  @override
  String get promptItemsRecentChatCountHint => 'Count';

  @override
  String get promptItemsChatStartPos => 'Chat Start Position';

  @override
  String get promptItemsChatStartPosHint => 'Start position';

  @override
  String get promptItemsChatEndPos => 'Chat End Position';

  @override
  String get promptItemsChatEndPosHint => 'End position';

  @override
  String get promptConditionsTitle => 'Prompt Conditions';

  @override
  String get promptConditionsTitleHelp => 'Set conditions to apply to the prompt.\n\n• Toggle: ON/OFF switch\n• Single select: Choose one from multiple options\n• Variable substitution: Replaces a variable with the selected value';

  @override
  String get promptConditionsAddButton => 'Add Condition';

  @override
  String get promptConditionsNewName => 'New Condition';

  @override
  String get promptConditionsNameHint => 'Condition name (e.g. Tone, Mood)';

  @override
  String get promptConditionsLabelType => 'Type';

  @override
  String get promptConditionsLabelVarName => 'Variable Name';

  @override
  String get promptConditionsVarNameHint => 'Variable name';

  @override
  String get promptConditionsLabelOptions => 'Options';

  @override
  String get promptConditionsOptionsEmpty => 'No options';

  @override
  String get promptConditionsOptionAddHint => 'Enter option name';

  @override
  String get promptPresetsTitle => 'Prompt Condition Presets';

  @override
  String get promptPresetsTitleHelp => 'Presets with pre-configured condition values.\n\nSelecting a preset during chat applies all conditions at once.';

  @override
  String get promptPresetsAddButton => 'Add Preset';

  @override
  String get promptPresetsNewName => 'New Preset';

  @override
  String get promptPresetsLabelName => 'Name';

  @override
  String get promptPresetsNameHint => 'Preset name';

  @override
  String get promptPresetsLabelConditions => 'Conditions';

  @override
  String get promptPresetsConditionNoName => 'No Name';

  @override
  String get promptPresetsSelectHint => 'Select an option';

  @override
  String get promptPresetsCustomLabel => 'Other';

  @override
  String get promptPresetsCustomInputLabel => 'Custom';

  @override
  String get promptPresetsCustomInputHint => 'Enter a value';

  @override
  String get promptRegexTitle => 'Regex Rules';

  @override
  String get promptRegexTitleHelp => 'Transform text using regular expressions (RegExp).\n\nApplication timing varies by property:\n• Modify Input: Applied to user input text\n• Modify Output: Applied to AI response text\n• Modify Send Data: Applied to API payload\n• Modify Display: Applied only when rendering on screen';

  @override
  String get promptRegexEmpty => 'No regex rules';

  @override
  String promptRegexRuleDefaultName(int index) {
    return 'Rule $index';
  }

  @override
  String get promptRegexNameHint => 'Rule name (e.g. Remove OOC, Tag Transform)';

  @override
  String get promptRegexLabelTarget => 'Target';

  @override
  String get promptRegexLabelPattern => 'Regex Pattern';

  @override
  String get promptRegexPatternHint => 'e.g. \\(OOC:.*?\\)';

  @override
  String get promptRegexLabelReplacement => 'Replacement';

  @override
  String get promptRegexReplacementHint => 'Matched text will be replaced with this format\n\nCapture groups: \$1, \$2, ...';

  @override
  String get promptRegexAddButton => 'Add Rule';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupSectionTitle => 'Create Backup';

  @override
  String get backupSectionDesc => 'Export all data — characters (with images), chat history, prompts, custom models, and settings — into a single backup file.';

  @override
  String get backupCreateButton => 'Create Backup File';

  @override
  String get backupRestoreTitle => 'Restore Backup';

  @override
  String get backupRestoreDesc => 'Select a .zip backup file to restore your data. (Legacy .db files also supported)';

  @override
  String get backupRestoreWarning => 'Warning: All existing data will be erased. The app must be restarted after restore.';

  @override
  String get backupRestoreButton => 'Select Backup File';

  @override
  String get backupProcessing => 'Processing...';

  @override
  String get backupProgressDb => 'Preparing database...';

  @override
  String backupProgressFiles(int current, int total) {
    return 'Compressing files... ($current/$total)';
  }

  @override
  String get backupProgressSaving => 'Saving backup file...';

  @override
  String get backupRestoreProgressReading => 'Reading backup file...';

  @override
  String backupRestoreProgressFiles(int current, int total) {
    return 'Restoring files... ($current/$total)';
  }

  @override
  String get backupRestoreProgressDb => 'Restoring database...';

  @override
  String backupSuccessDownloads(String fileName) {
    return 'Backup saved: Downloads/$fileName';
  }

  @override
  String backupSuccessIos(String fileName) {
    return 'Backup saved: $fileName';
  }

  @override
  String get backupSaveFailed => 'Failed to save file';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get backupInvalidFile => 'Please select a .zip or .db backup file';

  @override
  String get backupZipNoDb => 'backup.db not found in the ZIP file';

  @override
  String get backupRestoreConfirmTitle => 'Restore Backup';

  @override
  String backupRestoreConfirmContent(String createdAt) {
    return 'Backup date: $createdAt\n\nAll existing data will be replaced with backup data.\nContinue?';
  }

  @override
  String get backupRestoreConfirmButton => 'Restore';

  @override
  String get backupRestoreSuccessTitle => 'Restore Complete';

  @override
  String get backupRestoreSuccessContent => 'Backup data restored.\nPlease restart the app to apply changes.';

  @override
  String backupRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get backupCreatedAtUnknown => 'Unknown';

  @override
  String get logTitle => 'API Logs';

  @override
  String get logDeleteAllTooltip => 'Delete All';

  @override
  String get logInfoMessage => 'View API request and response logs.\nLogs older than 7 days are automatically deleted.';

  @override
  String get logEmpty => 'No logs';

  @override
  String get logAutoSummaryLabel => 'Auto Summary';

  @override
  String get logDeleteTitle => 'Delete Log';

  @override
  String get logDeleteContent => 'Delete this log?';

  @override
  String get logDeleteSuccess => 'Log deleted';

  @override
  String logDeleteFailed(String error) {
    return 'Failed to delete log: $error';
  }

  @override
  String get logDeleteAllTitle => 'Delete All Logs';

  @override
  String get logDeleteAllContent => 'Delete all logs? This cannot be undone.';

  @override
  String get logDeleteAllSuccess => 'All logs deleted';

  @override
  String logLoadFailed(String error) {
    return 'Failed to load logs: $error';
  }

  @override
  String get logDetailTitle => 'Log Detail';

  @override
  String get logDetailInfoSection => 'Basic Info';

  @override
  String get logDetailTime => 'Time';

  @override
  String get logDetailType => 'Type';

  @override
  String get logDetailModel => 'Model';

  @override
  String get logDetailChatRoomId => 'Chat Room ID';

  @override
  String get logDetailCharacterId => 'Character ID';

  @override
  String get logDetailCopied => 'Copied to clipboard';

  @override
  String get logDetailFormatLabel => 'Format';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get statisticsNoData => 'No data';

  @override
  String get statisticsPeriod7Days => '7 Days';

  @override
  String get statisticsPeriod30Days => '30 Days';

  @override
  String get statisticsPeriodAll => 'All Time';

  @override
  String get statisticsCost => 'Estimated Cost';

  @override
  String get statisticsTokens => 'Total Tokens';

  @override
  String get statisticsMessages => 'Messages';

  @override
  String statisticsDailyTokens(String tokens) {
    return '$tokens tokens';
  }

  @override
  String statisticsDailyMessages(int count) {
    return '$count messages';
  }

  @override
  String statisticsModelMessages(int count) {
    return '$count';
  }

  @override
  String statisticsDailyModels(int count) {
    return '$count models';
  }

  @override
  String statisticsDateFormat(String year, String month, String day) {
    return '$year/$month/$day';
  }

  @override
  String get statisticsTokenInput => 'Input';

  @override
  String get statisticsTokenOutput => 'Output';

  @override
  String get statisticsTokenCached => 'Cached';

  @override
  String get statisticsTokenThinking => 'Thinking';

  @override
  String get tokenizerTitle => 'Tokenizer';

  @override
  String get tokenizerSectionTitle => 'Select Tokenizer';

  @override
  String get tokenizerLabel => 'Tokenizer';

  @override
  String get tokenizerDescription => 'The tokenizer determines how text is converted to tokens. The best tokenizer may vary by model.';

  @override
  String get profileTabLabelName => 'Name';

  @override
  String get profileTabNameHelp => 'Enter the character\'s unique name.';

  @override
  String get profileTabNameHint => 'Enter the character\'s name.';

  @override
  String get profileTabNameValidation => 'Please enter a character name';

  @override
  String get profileTabLabelNickname => 'Nickname';

  @override
  String get profileTabNicknameHelp => 'Used instead of the char variable in prompts. If empty, the name is used.';

  @override
  String get profileTabNicknameHint => 'Enter the character\'s nickname.';

  @override
  String get profileTabLabelCreatorNotes => 'Tagline';

  @override
  String get profileTabCreatorNotesHelp => 'Write a short sentence describing the character.';

  @override
  String get profileTabCreatorNotesHint => 'Enter a brief intro for this character.';

  @override
  String get profileTabLabelKeywords => 'Keywords';

  @override
  String get profileTabKeywordsHelp => 'Enter keywords separated by commas (,).';

  @override
  String get profileTabKeywordsHint => 'e.g. fantasy, male';

  @override
  String get startScenarioTitle => 'Start Setting';

  @override
  String get startScenarioTitleHelp => 'Add start setting information for the conversation.';

  @override
  String get startScenarioEmpty => 'No start settings';

  @override
  String get startScenarioAddButton => 'Add Start Setting';

  @override
  String get startScenarioNewName => 'New Start Setting';

  @override
  String get startScenarioNameHint => 'Start setting name';

  @override
  String get startScenarioStartSettingLabel => 'Start Setting';

  @override
  String get startScenarioStartSettingInfo => 'This content is inserted before the summary and will not be deleted.';

  @override
  String get startScenarioStartSettingHint => 'Enter the start setting content';

  @override
  String get startScenarioStartMessageLabel => 'Start Message';

  @override
  String get startScenarioStartMessageHint => 'Enter the start message';

  @override
  String get personaTitle => 'Persona';

  @override
  String get personaTitleHelp => 'Add persona information for the character.';

  @override
  String get personaEmpty => 'No personas';

  @override
  String get personaAddButton => 'Add Persona';

  @override
  String get personaNewName => 'New Persona';

  @override
  String get personaNameHint => 'Persona name';

  @override
  String get personaContentLabel => 'Content';

  @override
  String get personaContentHint => 'Enter persona content';

  @override
  String get coverImageTitle => 'Cover';

  @override
  String get coverImageTitleHelp => 'Add cover images for the character.';

  @override
  String get coverImageEmpty => 'No cover images';

  @override
  String get coverImageAddButton => 'Add Cover Image';

  @override
  String coverImageDefaultName(int index) {
    return 'Cover $index';
  }

  @override
  String coverImageSaveError(String error) {
    return 'Failed to save image: $error';
  }

  @override
  String get additionalImageTitle => 'Extra Images';

  @override
  String get additionalImageTitleHelp => 'Add reference images related to the character.';

  @override
  String get additionalImageEmpty => 'No extra images';

  @override
  String get additionalImageAddButton => 'Add Image';

  @override
  String additionalImageDefaultName(int index) {
    return 'Image $index';
  }

  @override
  String additionalImageSaveError(String error) {
    return 'Failed to save image: $error';
  }

  @override
  String get detailSettingsTitle => 'World Setting';

  @override
  String get detailSettingsTitleHelp => 'Describe the world or background this character belongs to.';

  @override
  String get detailSettingsHint => 'Enter world setting details.';

  @override
  String get chatBottomPanelTitle => 'Viewer';

  @override
  String get chatBottomPanelFontSize => 'Font Size';

  @override
  String get chatBottomPanelLineHeight => 'Line Height';

  @override
  String get chatBottomPanelParagraphSpacing => 'Paragraph Spacing';

  @override
  String get chatBottomPanelParagraphWidth => 'Paragraph Width';

  @override
  String get chatBottomPanelParagraphAlign => 'Text Align';

  @override
  String get chatBottomPanelAlignLeft => 'Left';

  @override
  String get chatBottomPanelAlignJustify => 'Justify';

  @override
  String get tutorialStepGoogleAiAccess => 'Go to Google AI Studio';

  @override
  String get tutorialStepGoogleAiPayment => 'Create a billing account (required for paid models)';

  @override
  String get tutorialStepGetApiKey => 'Click Get API Key';

  @override
  String get tutorialStepCreateApiKey => 'Select Create API Key';

  @override
  String get tutorialStepCopyKey => 'Copy the generated key and paste it above';

  @override
  String get tutorialStepVertexAccess => 'Go to Google Cloud Console';

  @override
  String get tutorialStepVertexBilling => 'Create a billing account and link it to a project';

  @override
  String get tutorialStepVertexServiceAccount => 'IAM → Service Accounts → Create Account';

  @override
  String get tutorialStepVertexRole => 'Grant the Vertex AI User role';

  @override
  String get tutorialStepVertexCreateKey => 'Create Key → JSON → Download';

  @override
  String get tutorialStepOpenaiAccess => 'Go to OpenAI Platform';

  @override
  String get tutorialStepApiKeysMenu => 'Select API Keys menu';

  @override
  String get tutorialStepCreateSecretKey => 'Click Create new secret key';

  @override
  String get tutorialStepAnthropicAccess => 'Go to Anthropic Console';

  @override
  String get tutorialStepAnthropicCreate => 'Click Create Key';

  @override
  String tutorialModelPrice(String inputPrice, String outputPrice) {
    return 'Input $inputPrice/1M · Output $outputPrice/1M';
  }

  @override
  String get legalDocumentKorean => 'Korean';

  @override
  String get newsTopicPolitics => 'Politics';

  @override
  String get newsTopicSociety => 'Society';

  @override
  String get newsTopicEntertainment => 'Entertainment';

  @override
  String get newsTopicEconomy => 'Economy';

  @override
  String get newsTopicCulture => 'Culture';

  @override
  String get toolListCharacters => 'List Characters';

  @override
  String get toolGetCharacter => 'Get Character';

  @override
  String get toolCreateCharacter => 'Create Character';

  @override
  String get toolUpdateCharacter => 'Update Character';

  @override
  String get toolCreatePersona => 'Create Persona';

  @override
  String get toolUpdatePersona => 'Update Persona';

  @override
  String get toolDeletePersona => 'Delete Persona';

  @override
  String get toolCreateStartScenario => 'Create Start Scenario';

  @override
  String get toolUpdateStartScenario => 'Update Start Scenario';

  @override
  String get toolDeleteStartScenario => 'Delete Start Scenario';

  @override
  String get toolCreateCharacterBook => 'Create Lorebook Entry';

  @override
  String get toolUpdateCharacterBook => 'Update Lorebook Entry';

  @override
  String get toolDeleteCharacterBook => 'Delete Lorebook Entry';

  @override
  String apiKeyLoadFailed(String error) {
    return 'Failed to load API key: $error';
  }

  @override
  String get apiKeyServiceAccountLabel => '(Service Account JSON)';

  @override
  String get apiKeyValidationFailed => 'API key validation failed';

  @override
  String apiKeySaved(String apiKeyType) {
    return '$apiKeyType API key saved';
  }

  @override
  String get chatPromptEmptyHint => 'Tap + to add a new prompt';

  @override
  String chatPromptItemCount(int count) {
    return '$count items';
  }

  @override
  String customModelSubtitle(String format, int count) {
    return '$format · $count models';
  }

  @override
  String get agentChatDescription => 'Flan Agent can create and edit characters. Ask it to build or modify any character you have in mind.';

  @override
  String diaryTitle(String author) {
    return '$author\'s Diary';
  }

  @override
  String get characterCardOutfitLabel => 'Outfit ';

  @override
  String get characterCardMemoLabel => 'Memo ';

  @override
  String get modelPresetPrimary => 'Primary Model';

  @override
  String get modelPresetSecondary => 'Secondary Model';

  @override
  String get modelPresetCustom => 'Custom';

  @override
  String get agentEntryTypeEpisode => 'Summary';

  @override
  String get agentEntryTypeCharacter => 'Characters';

  @override
  String get agentEntryTypeLocation => 'Locations';

  @override
  String get agentEntryTypeItem => 'Items';

  @override
  String get agentEntryTypeEvent => 'Events';

  @override
  String get settingsAiResponseLanguageOthers => 'Others (custom)';

  @override
  String get settingsAiResponseLanguageOthersTitle => 'AI Response Language';

  @override
  String get settingsAiResponseLanguageOthersHint => 'Enter language name (e.g. French)';

  @override
  String get settingsAiResponseLanguageOthersLabel => 'Language name';
}
