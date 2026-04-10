import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/localization_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/common_appbar.dart';
import '../tutorial/tutorial_screen.dart';
import 'api_key_screen.dart';
import 'chat_model_screen.dart';
import 'chat_prompt_screen.dart';
import 'auto_summary_screen.dart';
import 'tokenizer_screen.dart';
import 'backup_screen.dart';
import 'log_screen.dart';
import 'legal_document_screen.dart';
import 'statistics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.settingsTitle,
        showBackButton: false,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(l10n.settingsSectionGeneral),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              String themeModeValue;
              switch (themeProvider.themeMode) {
                case ThemeMode.light:
                  themeModeValue = 'light';
                  break;
                case ThemeMode.dark:
                  themeModeValue = 'dark';
                  break;
                case ThemeMode.system:
                  themeModeValue = 'system';
                  break;
              }

              return _buildListTile(
                icon: Icons.brightness_6,
                title: l10n.settingsTheme,
                trailing: DropdownButton<String>(
                  value: themeModeValue,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: [
                    DropdownMenuItem(
                        value: 'system', child: Text(l10n.settingsThemeSystem)),
                    DropdownMenuItem(
                        value: 'light', child: Text(l10n.settingsThemeLight)),
                    DropdownMenuItem(
                        value: 'dark', child: Text(l10n.settingsThemeDark)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ThemeMode newMode;
                      switch (value) {
                        case 'light':
                          newMode = ThemeMode.light;
                          break;
                        case 'dark':
                          newMode = ThemeMode.dark;
                          break;
                        case 'system':
                        default:
                          newMode = ThemeMode.system;
                          break;
                      }
                      themeProvider.setThemeMode(newMode);
                    }
                  },
                ),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildListTile(
                icon: Icons.palette,
                title: l10n.settingsThemeColor,
                trailing: DropdownButton<ThemeColor>(
                  value: themeProvider.themeColor,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: ThemeColor.values.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_localizedColorName(color, l10n)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeColor(value);
                    }
                  },
                ),
              );
            },
          ),
          Consumer<LocalizationProvider>(
            builder: (context, l10nProvider, child) {
              return _buildListTile(
                icon: Icons.language,
                title: l10n.settingsLanguage,
                trailing: DropdownButton<String>(
                  value: l10nProvider.appLocale?.languageCode ?? 'system',
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: [
                    DropdownMenuItem(
                        value: 'system',
                        child: Text(l10n.settingsLanguageSystem)),
                    DropdownMenuItem(
                        value: 'ko', child: Text(l10n.languageKorean)),
                    DropdownMenuItem(
                        value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(
                        value: 'ja', child: Text(l10n.languageJapanese)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    l10nProvider.setAppLocale(
                        value == 'system' ? null : Locale(value));
                  },
                ),
              );
            },
          ),
          Consumer<LocalizationProvider>(
            builder: (context, l10nProvider, child) {
              return _buildListTile(
                icon: Icons.translate,
                title: l10n.settingsAiResponseLanguage,
                trailing: DropdownButton<String>(
                  value: l10nProvider.aiResponseLocale ?? 'auto',
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: [
                    DropdownMenuItem(
                        value: 'auto',
                        child: Text(l10n.settingsAiResponseLanguageAuto)),
                    DropdownMenuItem(
                        value: 'ko', child: Text(l10n.languageKorean)),
                    DropdownMenuItem(
                        value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(
                        value: 'ja', child: Text(l10n.languageJapanese)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    l10nProvider
                        .setAiResponseLocale(value == 'auto' ? null : value);
                  },
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(l10n.settingsSectionChat),
          _buildListTile(
            icon: Icons.key,
            title: l10n.settingsApiKey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiKeyScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.psychology,
            title: l10n.settingsChatModel,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatModelScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.token,
            title: l10n.settingsTokenizer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TokenizerScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.chat_bubble_outline,
            title: l10n.settingsChatPrompt,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPromptScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.auto_awesome,
            title: l10n.settingsAutoSummary,
            subtitle: l10n.settingsAutoSummarySubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AutoSummaryScreen(
                    chatRoomId: 0,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(l10n.settingsSectionData),
          _buildListTile(
            icon: Icons.backup,
            title: l10n.settingsBackup,
            subtitle: l10n.settingsBackupSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.bar_chart,
            title: l10n.settingsStatistics,
            subtitle: l10n.settingsStatisticsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StatisticsScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.article_outlined,
            title: l10n.settingsLog,
            subtitle: l10n.settingsLogSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(l10n.settingsSectionEtc),
          _buildListTile(
            icon: Icons.school_outlined,
            title: l10n.settingsTutorial,
            subtitle: l10n.settingsTutorialSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TutorialScreen(
                    onComplete: () => Navigator.pop(context),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(l10n.settingsSectionInfo),
          _buildListTile(
            icon: Icons.info,
            title: l10n.settingsAppInfo,
            subtitle: l10n.settingsAppInfoSubtitle(_version),
            onTap: () {
              _showAboutDialog(l10n);
            },
          ),
          _buildListTile(
            icon: Icons.description,
            title: l10n.settingsTermsOfService,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LegalDocumentScreen(
                    title: l10n.settingsTermsOfService,
                    koreanUrl: 'https://github.com/pudding-studio/Flan_official/wiki/이용약관',
                    englishUrl: 'https://github.com/pudding-studio/Flan_official/wiki/Terms-of-Service',
                  ),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip,
            title: l10n.settingsPrivacyPolicy,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LegalDocumentScreen(
                    title: l10n.settingsPrivacyPolicy,
                    koreanUrl: 'https://github.com/pudding-studio/Flan_official/wiki/개인정보처리방침',
                    englishUrl: 'https://github.com/pudding-studio/Flan_official/wiki/Privacy-Policy',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _localizedColorName(ThemeColor color, AppLocalizations l10n) {
    if (color == ThemeColor.orange) return l10n.settingsThemeColorDefault;
    return color.displayName;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showAboutDialog(AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: 'Flan',
      applicationVersion: _version,
      applicationIcon: const Icon(Icons.chat_bubble, size: 48),
      children: [
        Text(l10n.settingsAboutDescription),
        const SizedBox(height: 16),
        const Text('© 2026 Flan Team'),
      ],
    );
  }
}
