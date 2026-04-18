// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navCharacter => 'キャラクター';

  @override
  String get navChat => 'チャット';

  @override
  String get navSettings => '設定';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonMore => 'もっと見る';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonModify => '修正';

  @override
  String get commonCopyItem => 'コピー';

  @override
  String get commonExport => 'エクスポート';

  @override
  String get commonReset => 'リセット';

  @override
  String get commonDefault => 'デフォルト';

  @override
  String get commonLabelName => '名前';

  @override
  String get commonNumberHint => '数字を入力';

  @override
  String get commonAddItem => '項目を追加';

  @override
  String get commonAddFolder => 'フォルダを追加';

  @override
  String get commonEmptyList => '項目がありません';

  @override
  String get commonDeleteConfirmTitle => '削除の確認';

  @override
  String commonDeleteConfirmContent(String itemName) {
    return '$itemNameを削除しますか？';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionGeneral => '一般';

  @override
  String get settingsSectionChat => 'チャット';

  @override
  String get settingsSectionData => 'データ';

  @override
  String get settingsSectionEtc => 'その他';

  @override
  String get settingsSectionInfo => '情報';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSystem => 'システム設定';

  @override
  String get settingsThemeLight => 'ライトモード';

  @override
  String get settingsThemeDark => 'ダークモード';

  @override
  String get settingsThemeColor => 'テーマカラー';

  @override
  String get settingsThemeColorDefault => 'デフォルト';

  @override
  String get settingsLanguage => 'アプリ言語';

  @override
  String get settingsLanguageSystem => 'システム設定';

  @override
  String get settingsAiResponseLanguage => 'AI応答言語';

  @override
  String get settingsAiResponseLanguageAuto => 'アプリ言語と同じ';

  @override
  String get settingsBackgroundImage => '背景画像';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settingsApiKey => 'APIキー登録';

  @override
  String get settingsChatModel => 'チャットモデル';

  @override
  String get settingsTokenizer => 'トークナイザー';

  @override
  String get settingsChatPrompt => 'チャットプロンプト';

  @override
  String get settingsAutoSummary => '自動要約';

  @override
  String get settingsAutoSummarySubtitle => 'グローバル自動要約設定';

  @override
  String get settingsBackup => 'バックアップと復元';

  @override
  String get settingsBackupSubtitle => 'データのエクスポート／インポート';

  @override
  String get settingsStatistics => '統計';

  @override
  String get settingsStatisticsSubtitle => '日付別モデル使用量とコスト';

  @override
  String get settingsLog => 'ログ';

  @override
  String get settingsLogSubtitle => 'APIリクエスト／レスポンスログの確認';

  @override
  String get settingsTutorial => '初期設定をやり直す';

  @override
  String get settingsTutorialSubtitle => 'APIキー登録とモデル設定のチュートリアル';

  @override
  String get settingsAppInfo => 'アプリ情報';

  @override
  String settingsAppInfoSubtitle(String version) {
    return 'バージョン $version';
  }

  @override
  String get settingsTermsOfService => '利用規約';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsAboutDescription => 'AIキャラクターとチャットできるアプリです。';

  @override
  String get characterTitle => 'キャラクター';

  @override
  String characterSelectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get characterEmptyTitle => 'キャラクターがありません';

  @override
  String get characterEmptySubtitle => '+ ボタンを押して新しいキャラクターを追加しよう';

  @override
  String get characterDeleteSelectedTitle => 'キャラクターを削除';

  @override
  String characterDeleteSelectedContent(int count) {
    return '選択した$count件のキャラクターを削除しますか？関連データもすべて削除されます。';
  }

  @override
  String get characterDeleteOneContent => 'このキャラクターを削除しますか？関連データもすべて削除されます。';

  @override
  String get characterDeletedSelected => '選択したキャラクターを削除しました';

  @override
  String get characterDeleted => 'キャラクターを削除しました';

  @override
  String characterDeleteFailed(String error) {
    return 'キャラクターの削除に失敗しました: $error';
  }

  @override
  String get characterCopied => 'キャラクターをコピーしました';

  @override
  String characterCopyFailed(String error) {
    return 'キャラクターのコピーに失敗しました: $error';
  }

  @override
  String characterLoadFailed(String error) {
    return 'キャラクター一覧の読み込みに失敗しました: $error';
  }

  @override
  String characterReorderFailed(String error) {
    return '並び替えに失敗しました: $error';
  }

  @override
  String get characterImportSuccess => 'キャラクターをインポートしました';

  @override
  String characterImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get characterImport => 'インポート';

  @override
  String get characterViewMode => '表示形式';

  @override
  String get characterViewGrid => 'グリッド';

  @override
  String get characterViewList => 'リスト';

  @override
  String get characterThemeSelect => 'テーマを選択';

  @override
  String get characterFlanAgentTooltip => 'Flan Agent';

  @override
  String get characterAgentHighlightTooltip => 'ここをタップしてキャラクターを作ろう！';

  @override
  String characterSortLabel(String label) {
    return '並び替え: $label';
  }

  @override
  String get characterSortNameAsc => '名前 (昇順)';

  @override
  String get characterSortNameDesc => '名前 (降順)';

  @override
  String get characterSortUpdatedAtAsc => '更新日時 (古い順)';

  @override
  String get characterSortUpdatedAtDesc => '更新日時 (新しい順)';

  @override
  String get characterSortCreatedAtAsc => '作成日時 (古い順)';

  @override
  String get characterSortCreatedAtDesc => '作成日時 (新しい順)';

  @override
  String get characterSortCustom => 'カスタム';

  @override
  String get chatTitle => 'チャット';

  @override
  String chatSelectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get chatEmptyTitle => 'チャットルームがありません';

  @override
  String get chatEmptySubtitle => 'キャラクターを選んで新しいチャットを始めよう';

  @override
  String get chatNoMessages => 'メッセージがありません';

  @override
  String get chatSortMethod => '並び替え';

  @override
  String get chatSortRecent => '最近の更新順';

  @override
  String get chatSortName => '名前順';

  @override
  String get chatSortMessageCount => 'メッセージ数';

  @override
  String get chatRoomDeleteTitle => 'チャットを削除';

  @override
  String chatRoomDeleteSelectedContent(int count) {
    return '選択した$count件のチャットを削除しますか？\nすべてのメッセージが削除されます。';
  }

  @override
  String chatRoomDeleteOneContent(String name) {
    return '\'$name\' を削除しますか？\nすべてのメッセージが削除されます。';
  }

  @override
  String get chatRoomDeletedSelected => '選択したチャットを削除しました';

  @override
  String get chatRoomDeleted => 'チャットを削除しました';

  @override
  String get chatRoomDeleteFailed => 'チャットの削除に失敗しました';

  @override
  String get chatRoomRenameTitle => 'チャット名を変更';

  @override
  String get chatRoomRenameHint => 'チャット名';

  @override
  String get chatRoomRenameFailed => 'チャット名の変更に失敗しました';

  @override
  String get chatDateToday => '今日';

  @override
  String get chatDateYesterday => '昨日';

  @override
  String chatDateDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String chatDateWeeksAgo(int weeks) {
    return '$weeks週間前';
  }

  @override
  String chatDateMonthsAgo(int months) {
    return '$monthsヶ月前';
  }

  @override
  String chatDateYearsAgo(int years) {
    return '$years年前';
  }

  @override
  String get tutorialPrevious => '戻る';

  @override
  String get tutorialNext => '次へ';

  @override
  String get tutorialStart => 'はじめる';

  @override
  String tutorialStep(int step) {
    return 'STEP $step';
  }

  @override
  String get tutorialWelcomeTitle => 'Flanへようこそ';

  @override
  String get tutorialWelcomeBody => 'AIキャラクターと会話して、自分だけの世界を作ろう。\n簡単な初期設定を行います。';

  @override
  String get tutorialApiKeyTitle => 'APIキー登録';

  @override
  String get tutorialApiKeyDesc => 'AIモデルを使うにはAPIキーが必要です。\n使うサービスを選んでキーを登録してください。';

  @override
  String get tutorialApiKeyHint => 'APIキーを入力してください';

  @override
  String get tutorialApiKeyEmpty => 'APIキーを入力してください';

  @override
  String tutorialApiKeySaved(String provider) {
    return '$provider APIキーを保存しました';
  }

  @override
  String get tutorialVertexSaved => 'Vertex AIサービスアカウントを登録しました';

  @override
  String tutorialApiKeySaveFailed(String error) {
    return 'APIキーの保存に失敗しました: $error';
  }

  @override
  String get tutorialVertexImport => 'サービスアカウントJSONをインポート';

  @override
  String get tutorialVertexValidationFailed => 'サービスアカウントの検証に失敗しました';

  @override
  String tutorialJsonReadFailed(String error) {
    return 'JSONファイルの読み込みに失敗しました: $error';
  }

  @override
  String get tutorialReRegister => '再登録';

  @override
  String get tutorialReInput => '再入力';

  @override
  String get tutorialModelTitle => 'モデル設定';

  @override
  String get tutorialModelDesc => 'チャットと補助機能に使うAIモデルを選んでください。';

  @override
  String get tutorialMainModel => 'メインモデル';

  @override
  String get tutorialSubModel => 'サブモデル';

  @override
  String get tutorialMainDescGemini => 'チャットに使うモデルです。Gemini 3.1 Pro推奨。';

  @override
  String get tutorialSubDescGemini => '要約・SNS・ニュースなどに使います。Gemini 3 Flash推奨。';

  @override
  String get tutorialMainDescOpenai => 'チャットに使うモデルです。GPT-5.4推奨。';

  @override
  String get tutorialSubDescOpenai => '要約・SNS・ニュースなどに使います。GPT-5.4 Mini推奨。';

  @override
  String get tutorialMainDescAnthropic => 'チャットに使うモデルです。Claude Sonnet 4.6推奨。';

  @override
  String get tutorialSubDescAnthropic => '要約・SNS・ニュースなどに使います。Claude Haiku 4.5推奨。';

  @override
  String get tutorialModelRecommended => 'おすすめ';

  @override
  String get tutorialCompleteTitle => '設定が完了しました！';

  @override
  String get tutorialCompleteSubtitle => 'キャラクターを作ってみましょう';

  @override
  String get tutorialAgentBoxTitle => 'Flan Agent';

  @override
  String get tutorialAgentBoxSubtitle => 'キャラクタータブ上部の光るアイコンをタップしてみて';

  @override
  String get tutorialAgentBoxBody => 'Agentに作りたいキャラクターを伝えてみよう！\n「ファンタジー世界のエルフの魔法使いを作って」のように自由にリクエストできます。';

  @override
  String get tutorialHelpGoogleAi => 'Google AI Studio APIキーを取得';

  @override
  String get tutorialHelpVertex => 'Vertex AIサービスアカウントを設定';

  @override
  String get tutorialHelpOpenai => 'OpenAI APIキーを取得';

  @override
  String get tutorialHelpAnthropic => 'Anthropic APIキーを取得';

  @override
  String get drawerTabInfo => '基本情報';

  @override
  String get drawerTabPersona => 'ペルソナ';

  @override
  String get drawerTabCharacter => 'キャラクター情報';

  @override
  String get drawerTabLorebook => '設定集';

  @override
  String get drawerTabSummary => '要約';

  @override
  String get drawerChatMemo => 'チャットメモ';

  @override
  String get drawerMemoHint => 'メモを入力';

  @override
  String get drawerChatSettings => 'チャット設定';

  @override
  String get drawerModelPreset => 'モデル設定';

  @override
  String get drawerProvider => 'プロバイダー';

  @override
  String get drawerChatModel => 'チャットモデル';

  @override
  String get drawerChatPrompt => 'チャットプロンプト';

  @override
  String get drawerNone => 'なし';

  @override
  String get drawerPromptPreset => 'プロンプトプリセット';

  @override
  String get drawerShowImages => '画像を表示';

  @override
  String get drawerNoName => '名前なし';

  @override
  String get drawerSelectItem => '項目を選択';

  @override
  String get drawerOther => 'その他';

  @override
  String get drawerEnterValue => '値を入力';

  @override
  String get drawerSelectPersona => 'ペルソナを選択';

  @override
  String get drawerCreateNewPersona => '+ 新しいペルソナを作成';

  @override
  String get drawerNewPersona => '新しいペルソナ';

  @override
  String get drawerPersonaName => 'ペルソナ名';

  @override
  String get drawerPersonaDescription => 'ペルソナの説明';

  @override
  String get drawerPersonaDescriptionHint => 'ペルソナの説明を入力';

  @override
  String get drawerCharacter => 'キャラクター';

  @override
  String get drawerCharacterDescriptionHint => 'キャラクター設定を入力';

  @override
  String get drawerLorebookEmpty => '設定集の項目がありません';

  @override
  String get drawerBookNameHint => '設定名';

  @override
  String get drawerBookActivationCondition => '発動条件';

  @override
  String get drawerBookSecondaryKey => 'セカンダリキー';

  @override
  String get drawerBookActivationKey => 'アクティベーションキー';

  @override
  String get drawerBookKeysHint => 'カンマ区切りで入力';

  @override
  String get drawerBookSecondaryKeysHint => 'カンマ区切りで入力 (例: 魔法, 戦闘)';

  @override
  String get drawerBookInsertionOrder => '挿入順';

  @override
  String get drawerBookContent => '内容';

  @override
  String get drawerBookContentHint => '設定内容を入力';

  @override
  String get drawerAutoSummary => '自動要約';

  @override
  String get drawerAgentMode => 'エージェントモード';

  @override
  String get drawerSummaryMessageCount => '要約メッセージ数';

  @override
  String get drawerMessageCountHint => 'メッセージ数';

  @override
  String get drawerAutoSummaryList => '自動要約一覧';

  @override
  String drawerSummaryCount(int count) {
    return '$count件';
  }

  @override
  String get drawerNoSummaries => '自動要約がありません。\n設定から自動要約を有効にしてください。';

  @override
  String get drawerSummaryContentHint => '要約内容';

  @override
  String get drawerGenerating => '生成中...';

  @override
  String get drawerRegenerate => '再生成';

  @override
  String get drawerActive => '有効';

  @override
  String get drawerInactive => '無効';

  @override
  String get drawerNameLabel => '名前';

  @override
  String get drawerNameHint => '名前';

  @override
  String get drawerAddSummaryButton => '現在のメッセージ位置で要約を追加';

  @override
  String get drawerNoMessages => 'メッセージがありません';

  @override
  String get drawerNoNewMessages => '要約する新しいメッセージがありません';

  @override
  String get drawerSummaryAdded => '要約を追加しました。内容を入力してください。';

  @override
  String drawerSummaryAddFailed(String error) {
    return '要約の追加に失敗しました: $error';
  }

  @override
  String get drawerSummaryRegenerated => '要約を再生成しました';

  @override
  String drawerSummaryRegenerateFailed(String error) {
    return '要約の再生成に失敗しました: $error';
  }

  @override
  String get drawerSummaryItemName => 'この要約';

  @override
  String get drawerSummaryDeleted => '要約を削除しました';

  @override
  String drawerSummaryDeleteFailed(String error) {
    return '要約の削除に失敗しました: $error';
  }

  @override
  String drawerAgentEntryEmpty(String type) {
    return '$typeデータがありません。\nチャットを進めると自動的に生成されます。';
  }

  @override
  String drawerAgentEntrySaved(String name) {
    return '$name を保存しました';
  }

  @override
  String drawerAgentEntryDeleted(String name) {
    return '$name を削除しました';
  }

  @override
  String get agentFieldDateRange => '日時';

  @override
  String get agentFieldCharacters => '登場人物';

  @override
  String get agentFieldCharactersList => '登場人物 (カンマ区切り)';

  @override
  String get agentFieldLocations => '場所';

  @override
  String get agentFieldLocationsList => '場所 (カンマ区切り)';

  @override
  String get agentFieldSummary => '要約';

  @override
  String get agentFieldAppearance => '外見';

  @override
  String get agentFieldPersonality => '性格';

  @override
  String get agentFieldPast => '過去';

  @override
  String get agentFieldAbilities => '能力';

  @override
  String get agentFieldStoryActions => '作中の行動';

  @override
  String get agentFieldDialogueStyle => '台詞スタイル';

  @override
  String get agentFieldPossessions => '所持品';

  @override
  String get agentFieldPossessionsList => '所持品 (カンマ区切り)';

  @override
  String get agentFieldParentLocation => '場所';

  @override
  String get agentFieldFeatures => '特徴';

  @override
  String get agentFieldAsciiMap => 'マップ';

  @override
  String get agentFieldRelatedEpisodes => '関連エピソード';

  @override
  String get agentFieldRelatedEpisodesList => '関連エピソード (カンマ区切り)';

  @override
  String get agentFieldKeywords => 'キーワード';

  @override
  String get agentFieldDatetime => '日時';

  @override
  String get agentFieldOverview => '概要';

  @override
  String get agentFieldResult => '結果';

  @override
  String get chatRoomNotFound => 'チャットが見つかりません';

  @override
  String get chatRoomCannotLoad => 'チャットを読み込めません';

  @override
  String chatRoomMessageSendFailed(String error) {
    return 'メッセージの送信に失敗しました: $error';
  }

  @override
  String get chatRoomMessageItemName => 'このメッセージ';

  @override
  String get chatRoomMessageDeleted => 'メッセージを削除しました';

  @override
  String get chatRoomMessageDeleteFailed => 'メッセージの削除に失敗しました';

  @override
  String get chatRoomMessageEdited => 'メッセージを編集しました';

  @override
  String get chatRoomMessageEditFailed => 'メッセージの編集に失敗しました';

  @override
  String chatRoomMessageRetryFailed(String error) {
    return 'メッセージの再送信に失敗しました: $error';
  }

  @override
  String chatRoomMessageRegenerateFailed(String error) {
    return 'メッセージの再生成に失敗しました: $error';
  }

  @override
  String chatRoomMainModelLoadFailed(String modelId) {
    return 'メインモデル \'$modelId\' を読み込めませんでした。チャットモデル設定で再選択してください。';
  }

  @override
  String chatRoomSubModelLoadFailed(String modelId) {
    return 'サブモデル \'$modelId\' を読み込めませんでした。チャットモデル設定で再選択してください。';
  }

  @override
  String chatRoomCustomModelLoadFailed(String modelId) {
    return 'このチャットルームに指定されたモデル \'$modelId\' を読み込めませんでした。チャットルーム設定でモデルを再選択してください。';
  }

  @override
  String chatRoomPromptLoadFailed(String promptId) {
    return 'チャットプロンプト (id: $promptId) を読み込めませんでした。チャットルーム設定でプロンプトを再選択してください。';
  }

  @override
  String get chatRoomTextSettings => 'テキスト設定';

  @override
  String get chatRoomBranchTitle => '分岐を作成';

  @override
  String get chatRoomBranchContent => 'このメッセージまでの内容で新しい分岐を作成しますか？';

  @override
  String get chatRoomBranchConfirm => '作成';

  @override
  String get chatRoomBranchCreated => '分岐を作成しました';

  @override
  String get chatRoomBranchFailed => '分岐の作成に失敗しました';

  @override
  String get chatRoomWarningTitle => '注意';

  @override
  String get chatRoomWarningDesc => 'すべてのAI応答は自動生成されており、偏りや不正確な内容を含む場合があります。';

  @override
  String get chatRoomStartSetting => '開始設定';

  @override
  String get chatRoomNoStats => '統計情報がありません';

  @override
  String get chatRoomStatsTitle => '応答統計';

  @override
  String get chatRoomStatModel => 'モデル';

  @override
  String get chatRoomStatInputTokens => '入力トークン';

  @override
  String get chatRoomStatCachedTokens => 'キャッシュトークン';

  @override
  String get chatRoomStatCacheRatio => 'キャッシュ率';

  @override
  String get chatRoomStatOutputTokens => '出力トークン';

  @override
  String get chatRoomStatThoughtTokens => '思考トークン';

  @override
  String get chatRoomStatThoughtRatio => '思考率';

  @override
  String get chatRoomStatTotalTokens => '合計トークン';

  @override
  String get chatRoomStatEstimatedCost => '推定コスト';

  @override
  String get chatRoomMessageSearch => 'メッセージを検索...';

  @override
  String get chatRoomSearchTooltip => '検索';

  @override
  String get chatRoomNewMessages => '新しいメッセージ';

  @override
  String get chatRoomGenerating => '生成中...';

  @override
  String chatRoomRetrying(int attempt) {
    return '再送信中($attempt)...';
  }

  @override
  String get chatRoomWaiting => '応答を待っています...';

  @override
  String get chatRoomSummarizing => '要約中...';

  @override
  String get chatRoomMessageHint => 'メッセージを入力';

  @override
  String get chatRoomDayMon => '月';

  @override
  String get chatRoomDayTue => '火';

  @override
  String get chatRoomDayWed => '水';

  @override
  String get chatRoomDayThu => '木';

  @override
  String get chatRoomDayFri => '金';

  @override
  String get chatRoomDaySat => '土';

  @override
  String get chatRoomDaySun => '日';

  @override
  String get chatRoomDay => '昼';

  @override
  String get chatRoomNight => '夜';

  @override
  String characterEditDataLoadFailed(String error) {
    return 'データの読み込みに失敗しました: $error';
  }

  @override
  String get characterEditDraftFoundTitle => '未保存の下書きが見つかりました';

  @override
  String characterEditDraftFoundContent(String timestamp) {
    return '保存されていない下書きがあります。\n最終編集日時: $timestamp\n\n復元しますか？';
  }

  @override
  String get characterEditDraftLoad => '復元';

  @override
  String get characterEditJustNow => 'たった今';

  @override
  String characterEditMinutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String characterEditHoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String characterEditDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String get characterEditNameRequired => 'キャラクター名を入力してください';

  @override
  String get characterEditCreated => 'キャラクターを作成しました';

  @override
  String get characterEditUpdated => 'キャラクターを更新しました';

  @override
  String characterEditSaveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get characterEditTitleNew => 'キャラクターを作成';

  @override
  String get characterEditTitleEdit => 'キャラクターを編集';

  @override
  String get characterEditTabProfile => 'プロフィール';

  @override
  String get characterEditTabCharacter => 'キャラクター設定';

  @override
  String get characterEditTabLorebook => '設定集';

  @override
  String get characterEditTabPersona => 'ペルソナ';

  @override
  String get characterEditTabStartSetting => '開始設定';

  @override
  String get characterEditTabCoverImage => 'カバー画像';

  @override
  String get characterEditTabBackgroundImage => '背景画像';

  @override
  String get characterEditTabAdditionalImage => '追加画像';

  @override
  String get characterEditWorldDateTitle => '世界開始日';

  @override
  String get characterEditWorldDateHelp => 'このキャラクターの世界の基準日です。プロンプトの[world_date]キーワードとして使用され、ニュース/SNS生成の基準時刻になります。';

  @override
  String get characterEditWorldDateHint => '日付を選択してください';

  @override
  String get characterEditWorldDateClear => '日付をリセット';

  @override
  String get characterEditSnsHelp => 'このキャラクターのSNS掲示板設定を行います。';

  @override
  String get characterEditSnsBoardHint => '例: 自由掲示板、冒険者広場';

  @override
  String get characterEditSnsToneHint => '例: ユーモラスで親しみやすい雰囲気';

  @override
  String get characterEditSnsLanguageHint => '使用言語 (現在は韓国語のみ対応)';

  @override
  String get characterEditNameLabel => '名前';

  @override
  String get characterEditNameHelpText => 'キャラクターの固有名を入力してください。';

  @override
  String get characterEditNameHintText => 'キャラクターの名前を入力してください。';

  @override
  String get characterEditNicknameLabel => 'ニックネーム';

  @override
  String get characterEditNicknameHelp => 'プロンプトのchar変数の代わりに使う呼称です。空白の場合は名前が使われます。';

  @override
  String get characterEditNicknameHint => 'キャラクターのニックネームを入力してください。';

  @override
  String get characterEditTaglineLabel => '一言紹介';

  @override
  String get characterEditTaglineHelp => 'キャラクターを一言で表す文を書いてください。';

  @override
  String get characterEditTaglineHint => 'キャラクターの簡単な紹介を入力してください。';

  @override
  String get characterEditKeywordsLabel => 'キーワード';

  @override
  String get characterEditKeywordsHelp => 'キャラクターを表すキーワードをカンマ(,)区切りで入力してください。';

  @override
  String get characterEditKeywordsHint => '例: ファンタジー, 男性';

  @override
  String get characterEditWorldSetting => '世界観設定';

  @override
  String get characterEditWorldSettingHelp => 'このキャラクターが属する世界観や背景を自由に記述してください。';

  @override
  String get characterEditWorldSettingHint => '世界観設定を入力してください。';

  @override
  String get characterExportFormatTitle => 'エクスポート形式を選択';

  @override
  String get characterExportFlanFormat => 'Flan形式';

  @override
  String get characterExportFlanSubtitle => 'アプリ専用JSON (画像含む)';

  @override
  String get characterExportV2Card => 'キャラクターカード v2';

  @override
  String get characterExportV2Subtitle => 'PNG — 一部データが切り捨てられる場合あり';

  @override
  String get characterExportV3Card => 'キャラクターカード v3';

  @override
  String characterExportSuccessAndroid(String fileName) {
    return 'エクスポート完了: /storage/emulated/0/Download/$fileName';
  }

  @override
  String characterExportSuccessIos(String path) {
    return 'エクスポート完了: $path';
  }

  @override
  String get characterExportSaveFailed => 'ファイルの保存に失敗しました';

  @override
  String get characterCoverDefault => 'カバー 1';

  @override
  String characterCopyName(String name) {
    return '$name (コピー)';
  }

  @override
  String get autoSummaryTitle => '自動要約';

  @override
  String get autoSummarySaveFailed => '保存に失敗しました';

  @override
  String autoSummaryExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get autoSummaryResetTitle => 'リセット';

  @override
  String get autoSummaryResetContent => '要約プロンプトを最新のデフォルトに戻しますか？';

  @override
  String get autoSummaryResetConfirm => 'リセット';

  @override
  String get autoSummaryResetSuccess => '要約プロンプトをリセットしました';

  @override
  String autoSummaryResetFailed(String error) {
    return '要約プロンプトのリセットに失敗しました: $error';
  }

  @override
  String get autoSummaryInvalidFormat => '無効な要約プロンプト形式です';

  @override
  String get autoSummaryEmptyItems => 'プロンプト項目が空です';

  @override
  String get autoSummaryImportSuccess => '要約プロンプトをインポートしました';

  @override
  String autoSummaryImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get autoSummaryTabBasic => '基本情報';

  @override
  String get autoSummaryTabParameters => 'パラメーター';

  @override
  String get autoSummaryTabPrompt => 'プロンプト';

  @override
  String get autoSummarySection => '自動要約設定';

  @override
  String get autoSummaryEnableTitle => '自動要約';

  @override
  String get autoSummaryEnableSubtitle => 'トークン上限を超えると自動で要約を生成します';

  @override
  String get autoSummaryAgentTitle => 'エージェントモード';

  @override
  String get autoSummaryAgentSubtitle => '構造化された世界観データを自動管理します';

  @override
  String get autoSummaryModelSection => '要約モデル';

  @override
  String get autoSummaryUseSubModel => 'サブモデルを使用';

  @override
  String get autoSummaryUseSubModelSubtitle => 'チャットモデル設定のサブモデルを使用します';

  @override
  String get autoSummaryStartCondition => '自動要約の開始条件';

  @override
  String get autoSummaryTokenHint => 'トークン数を入力';

  @override
  String get autoSummaryPeriod => '要約の間隔';

  @override
  String get autoSummaryMaxResponseSize => '最大応答サイズ';

  @override
  String get autoSummaryMaxResponseHelp => '生成できる最大トークン数です。';

  @override
  String get autoSummaryTemperature => '温度';

  @override
  String get autoSummaryTemperatureHelp => '高い値ほど創造的で多様な応答を生成します。';

  @override
  String get autoSummaryTopPHelp => '累積確率のしきい値です。低い値ほど集中した応答を生成します。';

  @override
  String get autoSummaryTopKHelp => '考慮する上位トークンの数です。';

  @override
  String get autoSummaryPresencePenalty => 'プレゼンスペナルティ';

  @override
  String get autoSummaryPresencePenaltyHelp => '正の値は新しいトピックを促し、負の値は既存のトピックに集中します。';

  @override
  String get autoSummaryFrequencyPenalty => '頻度ペナルティ';

  @override
  String get autoSummaryFrequencyPenaltyHelp => '正の値は繰り返しを減らし、負の値は繰り返しを増やします。';

  @override
  String get autoSummaryPromptHelp => '要約プロンプトの項目を設定します。「要約対象」の役割位置に要約するメッセージが自動で挿入されます。\n\n長押しで順番を変更できます。';

  @override
  String get autoSummaryNoItems => 'プロンプト項目がありません';

  @override
  String get autoSummaryAddItem => '項目を追加';

  @override
  String get autoSummaryResetDefault => 'デフォルトプロンプトにリセット';

  @override
  String get autoSummaryImport => 'インポート';

  @override
  String get autoSummaryExport => 'エクスポート';

  @override
  String get autoSummaryItemNameHint => '項目名 (例: システム設定)';

  @override
  String get autoSummaryItemRole => '役割';

  @override
  String get autoSummaryTargetMessageInfo => '要約するメッセージがここに自動挿入されます';

  @override
  String get autoSummaryItemPrompt => 'プロンプト';

  @override
  String get autoSummaryItemPromptHint => 'プロンプト内容を入力';

  @override
  String get autoSummaryNoModel => 'モデルなし';

  @override
  String get customModelTitle => 'カスタムモデル';

  @override
  String get customModelEmpty => 'カスタムプロバイダーがありません';

  @override
  String get customModelAddProvider => 'プロバイダーを追加';

  @override
  String get customModelEditProvider => 'プロバイダーを編集';

  @override
  String get customModelDeleteProviderTitle => 'プロバイダーを削除';

  @override
  String get customModelDeleteModelTitle => 'モデルを削除';

  @override
  String get customModelNoExportable => 'エクスポートできるカスタムモデルがありません';

  @override
  String get customModelSaveFailed => '保存に失敗しました';

  @override
  String customModelExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String customModelImportSuccess(int providerCount, int modelCount) {
    return 'プロバイダー$providerCount件、モデル$modelCount件をインポートしました';
  }

  @override
  String customModelImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get customModelAddModel => 'モデルを追加';

  @override
  String get customModelEditModel => 'モデルを編集';

  @override
  String get customModelProviderUpdated => 'プロバイダーを更新しました';

  @override
  String get customModelProviderAdded => 'プロバイダーを追加しました';

  @override
  String get customModelProviderName => 'プロバイダー名';

  @override
  String get customModelProviderNameHint => '例: OpenRouter';

  @override
  String get customModelProviderNameRequired => 'プロバイダー名を入力してください';

  @override
  String get customModelEndpointHint => '例: https://openrouter.ai/api';

  @override
  String get customModelRetrySection => '失敗時の再試行';

  @override
  String get customModelRetryCount => '再試行回数';

  @override
  String get customModelEdit => '編集';

  @override
  String get customModelAdd => '追加';

  @override
  String get customModelUpdated => 'モデルを更新しました';

  @override
  String get customModelAdded => 'モデルを追加しました';

  @override
  String get customModelName => 'モデル名';

  @override
  String get customModelNameHint => '例: GPT-4o';

  @override
  String get customModelNameRequired => 'モデル名を入力してください';

  @override
  String get customModelId => 'モデルID';

  @override
  String get customModelIdHint => '例: openai/gpt-4o';

  @override
  String get customModelIdRequired => 'モデルIDを入力してください';

  @override
  String get customModelPriceSection => '価格 (任意)';

  @override
  String customModelDeleteProviderWithModels(String name, int count) {
    return 'プロバイダー \'$name\' とその配下の$count件のモデルを削除しますか？';
  }

  @override
  String customModelDeleteProvider(String name) {
    return 'プロバイダー \'$name\' を削除しますか？';
  }

  @override
  String customModelDeleteModel(String name) {
    return 'モデル \'$name\' を削除しますか？';
  }

  @override
  String get promptEditDefaultName => 'デフォルト';

  @override
  String get promptEditNewFolderName => '新しいフォルダ';

  @override
  String get promptEditDefaultRuleName => '正規表現ルール';

  @override
  String get promptEditDefaultPresetName => 'プリセット';

  @override
  String get promptEditDefaultConditionName => '条件';

  @override
  String get promptEditUpdated => 'プロンプトを更新しました';

  @override
  String get promptEditCreated => 'プロンプトを作成しました';

  @override
  String promptEditSaveFailed(String error) {
    return 'プロンプトの保存に失敗しました: $error';
  }

  @override
  String get promptEditTitleView => 'プロンプトを表示';

  @override
  String get promptEditTitleEdit => 'プロンプトを編集';

  @override
  String get promptEditTitleNew => '新しいプロンプト';

  @override
  String get promptEditTabBasic => '基本情報';

  @override
  String get promptEditTabParameters => 'パラメーター';

  @override
  String get promptEditTabPrompt => 'プロンプト';

  @override
  String get promptEditTabRegex => '正規表現';

  @override
  String get promptEditTabOther => 'その他';

  @override
  String get promptEditNameLabel => 'プロンプト名';

  @override
  String get promptEditNameHint => '例: フレンドリーアシスタント、専門家モード';

  @override
  String get promptEditNameRequired => 'プロンプト名を入力してください';

  @override
  String get promptEditDescriptionTitle => '説明';

  @override
  String get promptEditDescriptionHint => 'このプロンプトの説明を入力してください';

  @override
  String get promptEditMaxInputSize => '最大入力サイズ';

  @override
  String get promptEditMaxInputHelp => '入力できる最大トークン数です。';

  @override
  String get promptEditThinkingTokens => '思考トークン';

  @override
  String get promptEditThinkingHelp => '思考に使うトークン数です。';

  @override
  String get promptEditStopStrings => '停止文字列';

  @override
  String get promptEditStopStringsHint => '文字列を入力して追加';

  @override
  String get promptEditThinkingConfig => '思考機能の設定';

  @override
  String get promptEditThinkingTokenCount => '思考トークン数';

  @override
  String get promptEditThinkingTokenHelp => '思考に使う最大トークン数です。';

  @override
  String get promptEditThinkingLevel => '思考レベル';

  @override
  String get chatModelTitle => 'チャットモデル';

  @override
  String get chatModelTabMain => 'メインモデル';

  @override
  String get chatModelTabSub => 'サブモデル';

  @override
  String get chatModelSubInfo => 'サブモデルはSNS要約などに使われます。\n設定するとそれらの機能のデフォルトモデルが変更されます。';

  @override
  String get chatModelProviderSection => 'プロバイダー';

  @override
  String get chatModelUsedModelSection => '使用中モデル';

  @override
  String get chatModelInfoSection => 'モデル情報';

  @override
  String get chatModelManagement => 'カスタムモデル管理';

  @override
  String get chatModelApiKeyDeleteContent => 'このAPIキーを削除しますか？';

  @override
  String get chatModelVertexValidationFailed => 'サービスアカウントの検証に失敗しました';

  @override
  String get chatModelNewApiKey => '新しいAPIキー';

  @override
  String get chatModelJsonAdd => 'JSONを追加';

  @override
  String get chatModelKeyAdd => 'キーを追加';

  @override
  String get chatModelNoApiKey => '登録されたAPIキーがありません';

  @override
  String get apiKeyMultiInfo => 'プロバイダーごとに複数のAPIキーを登録できます。';

  @override
  String chatPromptListLoadFailed(String error) {
    return 'プロンプト一覧の読み込みに失敗しました: $error';
  }

  @override
  String chatPromptSelectFailed(String error) {
    return 'プロンプトの選択に失敗しました: $error';
  }

  @override
  String get chatPromptDeleted => 'プロンプトを削除しました';

  @override
  String chatPromptDeleteFailed(String error) {
    return 'プロンプトの削除に失敗しました: $error';
  }

  @override
  String get chatPromptDefaultSelect => 'デフォルトプロンプトを選択';

  @override
  String get chatPromptEmpty => '空のプロンプト';

  @override
  String get chatPromptCopied => 'プロンプトをコピーしました';

  @override
  String chatPromptCopyFailed(String error) {
    return 'プロンプトのコピーに失敗しました: $error';
  }

  @override
  String get chatPromptResetTitle => 'リセット';

  @override
  String get chatPromptResetContent => 'すべてのデフォルトプロンプトを初期状態に戻しますか？';

  @override
  String get chatPromptResetSuccess => 'デフォルトプロンプトをリセットしました';

  @override
  String chatPromptResetFailed(String error) {
    return 'デフォルトプロンプトのリセットに失敗しました: $error';
  }

  @override
  String chatPromptExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get chatPromptImportSuccess => 'プロンプトをインポートしました';

  @override
  String chatPromptImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get chatPromptListEmpty => 'プロンプトがありません';

  @override
  String get communityAnonymous => '匿名';

  @override
  String get communityNeedDescription => '先にキャラクターの説明または要約を記入してください。';

  @override
  String communityGenerateFailed(String error) {
    return '生成に失敗しました: $error';
  }

  @override
  String communityRegisterFailed(String error) {
    return '投稿に失敗しました: $error';
  }

  @override
  String get communityWritePost => '投稿を書く';

  @override
  String get communityNickname => 'ニックネーム';

  @override
  String get communityTitle => 'タイトル';

  @override
  String get communityContent => '内容';

  @override
  String get communityRegister => '投稿';

  @override
  String get communityWriteComment => 'コメントを書く';

  @override
  String get communityCommentContent => 'コメント';

  @override
  String get communityCommentDeleteTitle => 'コメントを削除';

  @override
  String get communityCommentDeleteContent => 'このコメントを削除しますか？';

  @override
  String get communityPostDeleteTitle => '投稿を削除';

  @override
  String get communityPostDeleteContent => 'この投稿を削除しますか？';

  @override
  String get communityDefaultName => '自由掲示板';

  @override
  String get communitySettingsTooltip => '設定';

  @override
  String get communityRefreshTooltip => '新しい投稿を生成';

  @override
  String get communityNoPostsTitle => 'まだ投稿がありません';

  @override
  String get communityNoPostsSubtitle => '引っ張って更新してください';

  @override
  String get communityCommentLabel => 'コメントを追加';

  @override
  String get communityUsedModelSection => '使用中モデル';

  @override
  String get communityModelPreset => 'モデル設定';

  @override
  String get communityProvider => 'プロバイダー';

  @override
  String get communityChatModel => 'チャットモデル';

  @override
  String get communitySettingsSection => 'コミュニティ設定';

  @override
  String get communityNameLabel => 'コミュニティ名';

  @override
  String get communityToneLabel => 'コミュニティの雰囲気';

  @override
  String get communityLanguageLabel => '使用言語';

  @override
  String get characterViewTabInfo => '情報';

  @override
  String get characterViewTabChat => 'チャット';

  @override
  String get characterViewTagline => '一言紹介';

  @override
  String get characterViewKeywords => 'キーワード';

  @override
  String get characterViewPersona => 'ペルソナ';

  @override
  String get characterViewStartSetting => '開始設定';

  @override
  String get characterViewStartContext => '開始状況';

  @override
  String get characterViewStartMessage => '開始メッセージ';

  @override
  String get characterViewNewChat => '新しいチャット';

  @override
  String get characterViewChatCreateFailed => 'チャットの作成に失敗しました';

  @override
  String get characterViewNoChats => 'チャットがありません';

  @override
  String get characterViewStartNewChat => '新しいチャットを始めよう';

  @override
  String agentChatErrorPrefix(String error) {
    return 'エラー: $error';
  }

  @override
  String get agentChatResetTitle => '会話をリセット';

  @override
  String get agentChatResetContent => 'すべての会話履歴が削除されます。続けますか？';

  @override
  String get agentChatResetTooltip => '会話をリセット';

  @override
  String get agentChatIntro => 'キャラクターの作成・編集・修正をお手伝いします';

  @override
  String get agentChatUserLabel => '私';

  @override
  String get agentChatUsedModel => '使用中モデル';

  @override
  String get agentChatModelPreset => 'モデル設定';

  @override
  String get agentChatProvider => 'プロバイダー';

  @override
  String get agentChatModel => 'チャットモデル';

  @override
  String get agentChatWaiting => '応答を待っています...';

  @override
  String get agentChatHint => 'メッセージを入力';

  @override
  String diaryGenerateFailed(String error) {
    return '日記の生成に失敗しました: $error';
  }

  @override
  String get diaryGenerateTitle => '日記を生成';

  @override
  String diaryGenerateContent(String date) {
    return '$dateの日記を生成しますか？';
  }

  @override
  String get diaryDeleteTitle => '日記を削除';

  @override
  String get diaryDeleteContent => 'この日記を削除しますか？';

  @override
  String get diaryRegenerateTitle => '日記を再生成';

  @override
  String diaryRegenerateContent(String date) {
    return '$dateの日記をすべて削除して再生成しますか？';
  }

  @override
  String get diarySettingsTooltip => '設定';

  @override
  String get diaryDaySun => '日';

  @override
  String get diaryDayMon => '月';

  @override
  String get diaryDayTue => '火';

  @override
  String get diaryDayWed => '水';

  @override
  String get diaryDayThu => '木';

  @override
  String get diaryDayFri => '金';

  @override
  String get diaryDaySat => '土';

  @override
  String get diarySelectDate => '日付を選択してください';

  @override
  String get diaryGenerating => '日記を生成しています...';

  @override
  String get diaryNoEntries => 'まだ日記がありません';

  @override
  String get diaryRegenerateTooltip => '再生成';

  @override
  String get diaryUsedModel => '使用中モデル';

  @override
  String get diaryModelPreset => 'モデル設定';

  @override
  String get diaryProvider => 'プロバイダー';

  @override
  String get diaryChatModel => 'チャットモデル';

  @override
  String get diarySettingsSection => '日記設定';

  @override
  String get diaryAutoGenerate => '自動生成';

  @override
  String get diaryAutoGenerateDesc => 'チャット内の日付が変わると自動で日記を生成します。';

  @override
  String get characterBookInvalidFormat => '無効な設定集の形式です';

  @override
  String get characterBookNoImport => 'インポートする設定がありません';

  @override
  String characterBookImportFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get characterBookNoExport => 'エクスポートする設定がありません';

  @override
  String get characterBookSaveFailed => '保存に失敗しました';

  @override
  String characterBookExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get characterBookNewFolder => '新しいフォルダ';

  @override
  String get characterBookNewItem => '新しい設定';

  @override
  String get characterBookFolderDeleteTitle => 'フォルダを削除';

  @override
  String get characterBookSection => '設定集';

  @override
  String get characterBookSectionHelp => 'このキャラクターの世界観に関する情報を設定集に追加できます。\n\n長押しで順番を変更できます。';

  @override
  String get characterBookAddItem => '設定を追加';

  @override
  String get characterBookAddFolder => 'フォルダを追加';

  @override
  String get characterBookEmpty => '設定集の項目がありません';

  @override
  String get characterBookNameHint => '設定名';

  @override
  String get characterBookActivationCondition => '発動条件';

  @override
  String get characterBookActivationKey => 'アクティベーションキー';

  @override
  String get characterBookKeysHint => 'カンマ区切りで入力 (例: 魔法, 戦闘)';

  @override
  String get characterBookSecondaryKey => 'セカンダリキー';

  @override
  String get characterBookInsertionOrder => '挿入順';

  @override
  String get characterBookContent => '内容';

  @override
  String get characterBookContentHint => '設定内容を入力してください';

  @override
  String get newsArticleDeleteTitle => '記事を削除';

  @override
  String get newsArticleDeleteContent => 'この記事を削除しますか？';

  @override
  String get newsEmptyTitle => 'まだ記事がありません';

  @override
  String get newsEmptySubtitle => '引っ張ってニュースを読み込んでください';

  @override
  String get newsRefreshTooltip => '新しい記事を生成';

  @override
  String get promptItemsTitle => 'プロンプト項目';

  @override
  String get promptItemsTitleHelp => 'AIに送るプロンプト項目を追加してください。順番通りに送信されます。\n\n長押しで順番を変更できます。';

  @override
  String get promptItemsAddItem => '項目を追加';

  @override
  String get promptItemsAddFolder => 'フォルダを追加';

  @override
  String get promptItemsEmpty => 'プロンプト項目がありません';

  @override
  String get promptItemsNameHint => '項目名 (例: システム設定, キャラクターの性格)';

  @override
  String get promptItemsLabelEnable => '有効';

  @override
  String get promptItemsLabelRole => '役割';

  @override
  String get promptItemsLabelPrompt => 'プロンプト';

  @override
  String get promptItemsPromptHint => 'AIの役割と応答スタイルを定義してください';

  @override
  String get promptItemsConditionSelect => '条件を選択';

  @override
  String get promptItemsConditionSelectHint => '条件を選択してください';

  @override
  String get promptItemsConditionNoName => '名前なし';

  @override
  String get promptItemsConditionValue => '条件の値';

  @override
  String get promptItemsConditionEnabled => '有効';

  @override
  String get promptItemsConditionDisabled => '無効';

  @override
  String get promptItemsSingleSelectItems => '選択項目';

  @override
  String get promptItemsSingleSelectHint => '項目を選択してください';

  @override
  String get promptItemsChatSettings => '設定';

  @override
  String get promptItemsRecentChatCount => '直近チャットの件数';

  @override
  String get promptItemsRecentChatCountHint => '件数';

  @override
  String get promptItemsChatStartPos => '以前のチャット開始位置';

  @override
  String get promptItemsChatStartPosHint => '開始位置';

  @override
  String get promptItemsChatEndPos => '以前のチャット終了位置';

  @override
  String get promptItemsChatEndPosHint => '終了位置';

  @override
  String get promptConditionsTitle => 'プロンプト条件';

  @override
  String get promptConditionsTitleHelp => 'プロンプトに適用する条件を設定します。\n\n• トグル: ON/OFFスイッチ\n• 一択選択: 複数の項目から一つを選択\n• 変数置換: 変数名を選択した項目に置き換える';

  @override
  String get promptConditionsAddButton => '条件を追加';

  @override
  String get promptConditionsNewName => '新しい条件';

  @override
  String get promptConditionsNameHint => '条件名 (例: 話し方, 雰囲気)';

  @override
  String get promptConditionsLabelType => 'タイプ';

  @override
  String get promptConditionsLabelVarName => '変数名';

  @override
  String get promptConditionsVarNameHint => '変数名';

  @override
  String get promptConditionsLabelOptions => '選択肢';

  @override
  String get promptConditionsOptionsEmpty => '選択肢がありません';

  @override
  String get promptConditionsOptionAddHint => '選択肢名を入力';

  @override
  String get promptPresetsTitle => 'プロンプト条件プリセット';

  @override
  String get promptPresetsTitleHelp => 'プロンプト条件の値をあらかじめ設定したプリセットです。\n\nチャット中にプリセットを選ぶと条件値が一括適用されます。';

  @override
  String get promptPresetsAddButton => 'プリセットを追加';

  @override
  String get promptPresetsNewName => '新しいプリセット';

  @override
  String get promptPresetsLabelName => '名前';

  @override
  String get promptPresetsNameHint => 'プリセット名';

  @override
  String get promptPresetsLabelConditions => '条件一覧';

  @override
  String get promptPresetsConditionNoName => '名前なし';

  @override
  String get promptPresetsSelectHint => '項目を選択してください';

  @override
  String get promptPresetsCustomLabel => 'その他';

  @override
  String get promptPresetsCustomInputLabel => '直接入力';

  @override
  String get promptPresetsCustomInputHint => '値を入力してください';

  @override
  String get promptRegexTitle => '正規表現ルール';

  @override
  String get promptRegexTitleHelp => '正規表現(RegExp)を使ってテキストを変換します。\n\nプロパティによって適用タイミングが異なります:\n• 入力文の修正: ユーザー入力テキストに適用\n• 出力文の修正: AI応答テキストに適用\n• 送信データの修正: API送信データに適用\n• 表示画面の修正: 画面表示時のみ適用';

  @override
  String get promptRegexEmpty => '正規表現ルールがありません';

  @override
  String promptRegexRuleDefaultName(int index) {
    return 'ルール $index';
  }

  @override
  String get promptRegexNameHint => 'ルール名 (例: OOC除去, タグ変換)';

  @override
  String get promptRegexLabelTarget => '対象';

  @override
  String get promptRegexLabelPattern => '正規表現パターン';

  @override
  String get promptRegexPatternHint => '例: \\(OOC:.*?\\)';

  @override
  String get promptRegexLabelReplacement => '変換形式';

  @override
  String get promptRegexReplacementHint => 'マッチしたテキストがこの形式に変換されます\n\nキャプチャグループ: \$1, \$2, ...';

  @override
  String get promptRegexAddButton => 'ルールを追加';

  @override
  String get backupTitle => 'バックアップと復元';

  @override
  String get backupSectionTitle => 'バックアップを作成';

  @override
  String get backupSectionDesc => 'キャラクター(画像含む)、チャット履歴、プロンプト、カスタムモデル、設定など、すべてのデータを一つのファイルにエクスポートします。';

  @override
  String get backupCreateButton => 'バックアップファイルを作成';

  @override
  String get backupRestoreTitle => 'バックアップを復元';

  @override
  String get backupRestoreDesc => 'バックアップの.zipファイルを選んでデータを復元します。(旧.dbファイルも対応)';

  @override
  String get backupRestoreWarning => '注意: 既存のデータはすべて削除されます。復元後はアプリの再起動が必要です。';

  @override
  String get backupRestoreButton => 'バックアップファイルを選択';

  @override
  String get backupProcessing => '処理中...';

  @override
  String get backupProgressDb => 'データベース準備中...';

  @override
  String backupProgressFiles(int current, int total) {
    return 'ファイル圧縮中... ($current/$total)';
  }

  @override
  String get backupProgressSaving => 'バックアップファイル保存中...';

  @override
  String get backupRestoreProgressReading => 'バックアップファイル読み込み中...';

  @override
  String backupRestoreProgressFiles(int current, int total) {
    return 'ファイル復元中... ($current/$total)';
  }

  @override
  String get backupRestoreProgressDb => 'データベース復元中...';

  @override
  String backupSuccessDownloads(String fileName) {
    return 'バックアップ完了: Downloads/$fileName';
  }

  @override
  String backupSuccessIos(String fileName) {
    return 'バックアップ完了: $fileName';
  }

  @override
  String get backupSaveFailed => 'ファイルの保存に失敗しました';

  @override
  String backupFailed(String error) {
    return 'バックアップに失敗しました: $error';
  }

  @override
  String get backupInvalidFile => '.zipまたは.dbのバックアップファイルを選択してください';

  @override
  String get backupZipNoDb => 'ZIPファイルにbackup.dbが見つかりません';

  @override
  String get backupRestoreConfirmTitle => 'バックアップを復元';

  @override
  String backupRestoreConfirmContent(String createdAt) {
    return 'バックアップ日時: $createdAt\n\n既存のデータがすべて削除され、バックアップデータに置き換えられます。\n続けますか？';
  }

  @override
  String get backupRestoreConfirmButton => '復元';

  @override
  String get backupRestoreSuccessTitle => '復元完了';

  @override
  String get backupRestoreSuccessContent => 'バックアップデータを復元しました。\n変更を完全に反映するにはアプリを再起動してください。';

  @override
  String backupRestoreFailed(String error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get backupCreatedAtUnknown => '不明';

  @override
  String get logTitle => 'APIログ';

  @override
  String get logDeleteAllTooltip => 'すべて削除';

  @override
  String get logInfoMessage => 'APIリクエストとレスポンスのログを確認できます。\n7日以上経過したログは自動削除されます。';

  @override
  String get logEmpty => 'ログがありません';

  @override
  String get logAutoSummaryLabel => '自動要約';

  @override
  String get logDeleteTitle => 'ログを削除';

  @override
  String get logDeleteContent => 'このログを削除しますか？';

  @override
  String get logDeleteSuccess => 'ログを削除しました';

  @override
  String logDeleteFailed(String error) {
    return 'ログの削除に失敗しました: $error';
  }

  @override
  String get logDeleteAllTitle => 'すべてのログを削除';

  @override
  String get logDeleteAllContent => 'すべてのログを削除しますか？この操作は元に戻せません。';

  @override
  String get logDeleteAllSuccess => 'すべてのログを削除しました';

  @override
  String logLoadFailed(String error) {
    return 'ログの読み込みに失敗しました: $error';
  }

  @override
  String get logDetailTitle => 'ログ詳細';

  @override
  String get logDetailInfoSection => '基本情報';

  @override
  String get logDetailTime => '時間';

  @override
  String get logDetailType => 'タイプ';

  @override
  String get logDetailModel => 'モデル';

  @override
  String get logDetailChatRoomId => 'チャットルームID';

  @override
  String get logDetailCharacterId => 'キャラクターID';

  @override
  String get logDetailCopied => 'クリップボードにコピーしました';

  @override
  String get logDetailFormatLabel => 'フォーマット';

  @override
  String get statisticsTitle => '統計';

  @override
  String get statisticsNoData => 'データがありません';

  @override
  String get statisticsPeriod7Days => '7日';

  @override
  String get statisticsPeriod30Days => '30日';

  @override
  String get statisticsPeriodAll => '全期間';

  @override
  String get statisticsCost => '推定コスト';

  @override
  String get statisticsTokens => '合計トークン';

  @override
  String get statisticsMessages => 'メッセージ';

  @override
  String statisticsDailyTokens(String tokens) {
    return '$tokensトークン';
  }

  @override
  String statisticsDailyMessages(int count) {
    return '$count件のメッセージ';
  }

  @override
  String statisticsModelMessages(int count) {
    return '$count件';
  }

  @override
  String statisticsDailyModels(int count) {
    return '$count件のモデル';
  }

  @override
  String statisticsDateFormat(String year, String month, String day) {
    return '$year年$month月$day日';
  }

  @override
  String get statisticsTokenInput => '入力';

  @override
  String get statisticsTokenOutput => '出力';

  @override
  String get statisticsTokenCached => 'キャッシュ';

  @override
  String get statisticsTokenThinking => '思考';

  @override
  String get tokenizerTitle => 'トークナイザー';

  @override
  String get tokenizerSectionTitle => 'トークナイザーを選択';

  @override
  String get tokenizerLabel => 'トークナイザー';

  @override
  String get tokenizerDescription => 'トークナイザーはテキストをトークンに変換する方式を決定します。モデルによって適切なトークナイザーが異なる場合があります。';

  @override
  String get profileTabLabelName => '名前';

  @override
  String get profileTabNameHelp => 'キャラクターの固有名を入力してください。';

  @override
  String get profileTabNameHint => 'キャラクターの名前を入力してください。';

  @override
  String get profileTabNameValidation => 'キャラクター名を入力してください';

  @override
  String get profileTabLabelNickname => 'ニックネーム';

  @override
  String get profileTabNicknameHelp => 'プロンプトのchar変数の代わりに使う呼称です。空白の場合は名前が使われます。';

  @override
  String get profileTabNicknameHint => 'キャラクターのニックネームを入力してください。';

  @override
  String get profileTabLabelCreatorNotes => '一言紹介';

  @override
  String get profileTabCreatorNotesHelp => 'キャラクターを一言で表す文を書いてください。';

  @override
  String get profileTabCreatorNotesHint => 'キャラクターの簡単な紹介を入力してください。';

  @override
  String get profileTabLabelKeywords => 'キーワード';

  @override
  String get profileTabKeywordsHelp => 'キャラクターを表すキーワードをカンマ(,)区切りで入力してください。';

  @override
  String get profileTabKeywordsHint => '例: ファンタジー, 男性';

  @override
  String get startScenarioTitle => '開始設定';

  @override
  String get startScenarioTitleHelp => '会話の開始設定情報を追加できます。';

  @override
  String get startScenarioEmpty => '開始設定がありません';

  @override
  String get startScenarioAddButton => '開始設定を追加';

  @override
  String get startScenarioNewName => '新しい開始設定';

  @override
  String get startScenarioNameHint => '開始設定名';

  @override
  String get startScenarioStartSettingLabel => '開始設定';

  @override
  String get startScenarioStartSettingInfo => 'この内容は要約の前に挿入され、削除されません。';

  @override
  String get startScenarioStartSettingHint => '開始設定の内容を入力してください';

  @override
  String get startScenarioStartMessageLabel => '開始メッセージ';

  @override
  String get startScenarioStartMessageHint => '開始メッセージを入力してください';

  @override
  String get personaTitle => 'ペルソナ';

  @override
  String get personaTitleHelp => 'キャラクターのペルソナ情報を追加できます。';

  @override
  String get personaEmpty => 'ペルソナがありません';

  @override
  String get personaAddButton => 'ペルソナを追加';

  @override
  String get personaNewName => '新しいペルソナ';

  @override
  String get personaNameHint => 'ペルソナ名';

  @override
  String get personaContentLabel => '内容';

  @override
  String get personaContentHint => 'ペルソナの内容を入力してください';

  @override
  String get coverImageTitle => 'カバー';

  @override
  String get coverImageTitleHelp => 'キャラクターのカバー画像を追加できます。';

  @override
  String get coverImageEmpty => 'カバー画像がありません';

  @override
  String get coverImageAddButton => 'カバー画像を追加';

  @override
  String coverImageDefaultName(int index) {
    return 'カバー $index';
  }

  @override
  String coverImageSaveError(String error) {
    return '画像の保存に失敗しました: $error';
  }

  @override
  String get additionalImageTitle => '追加画像';

  @override
  String get additionalImageTitleHelp => 'キャラクターに関連する参考画像を追加できます。';

  @override
  String get additionalImageEmpty => '追加画像がありません';

  @override
  String get additionalImageAddButton => '画像を追加';

  @override
  String additionalImageDefaultName(int index) {
    return '画像 $index';
  }

  @override
  String additionalImageSaveError(String error) {
    return '画像の保存に失敗しました: $error';
  }

  @override
  String get backgroundImageTitle => '背景画像';

  @override
  String get backgroundImageTitleHelp => 'チャットルームに透かしとして表示する背景画像を追加できます。';

  @override
  String get backgroundImageEmpty => '背景画像がありません';

  @override
  String get backgroundImageAddButton => '画像を追加';

  @override
  String backgroundImageDefaultName(int index) {
    return '背景 $index';
  }

  @override
  String backgroundImageSaveError(String error) {
    return '画像の保存に失敗しました: $error';
  }

  @override
  String get detailSettingsTitle => '世界観設定';

  @override
  String get detailSettingsTitleHelp => 'このキャラクターが属する世界観や背景を自由に記述してください。';

  @override
  String get detailSettingsHint => '世界観設定を入力してください。';

  @override
  String get chatBottomPanelTitle => 'ビューアー';

  @override
  String get chatBottomPanelFontSize => '文字サイズ';

  @override
  String get chatBottomPanelLineHeight => '行間';

  @override
  String get chatBottomPanelParagraphSpacing => '段落間隔';

  @override
  String get chatBottomPanelParagraphWidth => '段落幅';

  @override
  String get chatBottomPanelParagraphAlign => '段落揃え';

  @override
  String get chatBottomPanelAlignLeft => '左揃え';

  @override
  String get chatBottomPanelAlignJustify => '両端揃え';

  @override
  String get tutorialStepGoogleAiAccess => 'Google AI Studioにアクセス';

  @override
  String get tutorialStepGoogleAiPayment => '支払いアカウントを作成 (有料モデル使用時に必要)';

  @override
  String get tutorialStepGetApiKey => 'Get API Keyをクリック';

  @override
  String get tutorialStepCreateApiKey => 'Create API Keyを選択';

  @override
  String get tutorialStepCopyKey => '生成されたキーをコピーして上に貼り付け';

  @override
  String get tutorialStepVertexAccess => 'Google Cloud Consoleにアクセス';

  @override
  String get tutorialStepVertexBilling => '支払いアカウントを作成してプロジェクトに連携';

  @override
  String get tutorialStepVertexServiceAccount => 'IAM → サービスアカウント → アカウント作成';

  @override
  String get tutorialStepVertexRole => 'Vertex AI Userロールを付与';

  @override
  String get tutorialStepVertexCreateKey => 'キーを作成 → JSON → ダウンロード';

  @override
  String get tutorialStepOpenaiAccess => 'OpenAI Platformにアクセス';

  @override
  String get tutorialStepApiKeysMenu => 'API Keysメニューを選択';

  @override
  String get tutorialStepCreateSecretKey => 'Create new secret keyをクリック';

  @override
  String get tutorialStepAnthropicAccess => 'Anthropic Consoleにアクセス';

  @override
  String get tutorialStepAnthropicCreate => 'Create Keyをクリック';

  @override
  String tutorialModelPrice(String inputPrice, String outputPrice) {
    return '入力 $inputPrice/1M · 出力 $outputPrice/1M';
  }

  @override
  String get legalDocumentKorean => '韓国語';

  @override
  String get newsTopicPolitics => '政治';

  @override
  String get newsTopicSociety => '社会';

  @override
  String get newsTopicEntertainment => 'エンタメ';

  @override
  String get newsTopicEconomy => '経済';

  @override
  String get newsTopicCulture => '文化';

  @override
  String get toolListCharacters => 'キャラクター一覧';

  @override
  String get toolGetCharacter => 'キャラクター取得';

  @override
  String get toolCreateCharacter => 'キャラクター作成';

  @override
  String get toolUpdateCharacter => 'キャラクター更新';

  @override
  String get toolCreatePersona => 'ペルソナ作成';

  @override
  String get toolUpdatePersona => 'ペルソナ更新';

  @override
  String get toolDeletePersona => 'ペルソナ削除';

  @override
  String get toolCreateStartScenario => '開始シナリオ作成';

  @override
  String get toolUpdateStartScenario => '開始シナリオ更新';

  @override
  String get toolDeleteStartScenario => '開始シナリオ削除';

  @override
  String get toolCreateCharacterBook => '設定集エントリ作成';

  @override
  String get toolUpdateCharacterBook => '設定集エントリ更新';

  @override
  String get toolDeleteCharacterBook => '設定集エントリ削除';

  @override
  String apiKeyLoadFailed(String error) {
    return 'APIキーの読み込みに失敗しました: $error';
  }

  @override
  String get apiKeyServiceAccountLabel => '(サービスアカウントJSON)';

  @override
  String get apiKeyValidationFailed => 'APIキーの検証に失敗しました';

  @override
  String apiKeySaved(String apiKeyType) {
    return '$apiKeyType APIキーを保存しました';
  }

  @override
  String get chatPromptEmptyHint => '+ ボタンを押して新しいプロンプトを追加しよう';

  @override
  String chatPromptItemCount(int count) {
    return '$count件の項目';
  }

  @override
  String customModelSubtitle(String format, int count) {
    return '$format · $count件のモデル';
  }

  @override
  String get agentChatDescription => 'Flan Agentはキャラクターの作成・編集ができます。作りたいキャラクターや修正したい内容をリクエストしてみてください。';

  @override
  String diaryTitle(String author) {
    return '$authorの日記';
  }

  @override
  String get characterCardOutfitLabel => '衣装 ';

  @override
  String get characterCardMemoLabel => 'メモ ';

  @override
  String get modelPresetPrimary => 'メインモデル';

  @override
  String get modelPresetSecondary => 'サブモデル';

  @override
  String get modelPresetCustom => 'カスタム';

  @override
  String get agentEntryTypeEpisode => '要約';

  @override
  String get agentEntryTypeCharacter => '登場人物';

  @override
  String get agentEntryTypeLocation => '地域/場所';

  @override
  String get agentEntryTypeItem => 'アイテム';

  @override
  String get agentEntryTypeEvent => '実績/出来事';

  @override
  String get settingsAiResponseLanguageOthers => 'その他 (カスタム)';

  @override
  String get settingsAiResponseLanguageOthersTitle => 'AI応答言語の入力';

  @override
  String get settingsAiResponseLanguageOthersHint => '言語名を入力 (例: French)';

  @override
  String get settingsAiResponseLanguageOthersLabel => '言語名';
}
