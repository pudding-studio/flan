import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/common_dialog.dart';
import 'api_key_screen.dart';
import 'chat_prompt_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _language = 'ko';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('일반'),
          _buildListTile(
            icon: Icons.language,
            title: '언어',
            trailing: DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(16),
              items: const [
                DropdownMenuItem(value: 'ko', child: Text('한국어')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ja', child: Text('日本語')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                }
              },
            ),
          ),
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
          const Divider(),
          _buildSectionHeader('알림'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: '알림 받기',
            subtitle: '새로운 메시지 알림을 받습니다',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: '사운드',
            subtitle: '알림 소리를 재생합니다',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          const Divider(),
          _buildSectionHeader('모델'),
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
            icon: Icons.chat_bubble_outline,
            title: '채팅 프롬프트',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPromptScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('데이터'),
          _buildListTile(
            icon: Icons.storage,
            title: '저장공간',
            subtitle: '캐시 및 데이터 관리',
            onTap: () {
              _showClearCacheDialog();
            },
          ),
          _buildListTile(
            icon: Icons.cloud_download,
            title: '백업 및 복원',
            onTap: () {
              // TODO: 백업/복원 페이지로 이동
            },
          ),
          const Divider(),
          _buildSectionHeader('정보'),
          _buildListTile(
            icon: Icons.help,
            title: '도움말',
            onTap: () {
              // TODO: 도움말 페이지로 이동
            },
          ),
          _buildListTile(
            icon: Icons.info,
            title: '앱 정보',
            subtitle: '버전 1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildListTile(
            icon: Icons.description,
            title: '이용약관',
            onTap: () {
              // TODO: 이용약관 페이지로 이동
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip,
            title: '개인정보 처리방침',
            onTap: () {
              // TODO: 개인정보 처리방침 페이지로 이동
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '캐시 삭제',
      content: '캐시를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed == true) {
      // TODO: 캐시 삭제 로직
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '캐시가 삭제되었습니다',
        );
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Flan',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.chat_bubble, size: 48),
      children: [
        const Text('AI 캐릭터와 대화할 수 있는 앱입니다.'),
        const SizedBox(height: 16),
        const Text('© 2026 Flan Team'),
      ],
    );
  }
}
