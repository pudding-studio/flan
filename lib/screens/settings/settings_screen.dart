import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/common_appbar.dart';
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
    return Scaffold(
      appBar: const CommonAppBar(
        title: '설정',
        showBackButton: false,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('일반'),
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
                title: '테마',
                trailing: DropdownButton<String>(
                  value: themeModeValue,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('시스템 설정')),
                    DropdownMenuItem(value: 'light', child: Text('라이트 모드')),
                    DropdownMenuItem(value: 'dark', child: Text('다크 모드')),
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
                title: '테마 색상',
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
                          Text(color.displayName),
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
          const Divider(),
          _buildSectionHeader('채팅'),
          _buildListTile(
            icon: Icons.key,
            title: 'API 키 등록',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiKeyScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.psychology,
            title: '채팅 모델',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatModelScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.token,
            title: '토크나이저',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TokenizerScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.chat_bubble_outline,
            title: '채팅 프롬프트',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPromptScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.auto_awesome,
            title: '자동 요약',
            subtitle: '전역 자동 요약 설정',
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
          _buildSectionHeader('데이터'),
          _buildListTile(
            icon: Icons.backup,
            title: '백업 및 복구',
            subtitle: '데이터 내보내기/가져오기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.bar_chart,
            title: '통계',
            subtitle: '날짜별 모델 사용량 및 비용',
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
            title: '로그',
            subtitle: 'API 요청/응답 로그 확인',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('정보'),
          _buildListTile(
            icon: Icons.info,
            title: '앱 정보',
            subtitle: '버전 $_version',
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildListTile(
            icon: Icons.description,
            title: '이용약관',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalDocumentScreen(
                    title: '이용약관',
                    koreanUrl: 'https://github.com/pudding-studio/Flan_official/wiki/이용약관',
                    englishUrl: 'https://github.com/pudding-studio/Flan_official/wiki/Terms-of-Service',
                  ),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip,
            title: '개인정보 처리방침',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalDocumentScreen(
                    title: '개인정보 처리방침',
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

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Flan',
      applicationVersion: _version,
      applicationIcon: const Icon(Icons.chat_bubble, size: 48),
      children: [
        const Text('AI 캐릭터와 대화할 수 있는 앱입니다.'),
        const SizedBox(height: 16),
        const Text('© 2026 Flan Team'),
      ],
    );
  }
}
