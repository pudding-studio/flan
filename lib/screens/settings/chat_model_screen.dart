import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_title_medium.dart';
import 'custom_model_screen.dart';

class ChatModelScreen extends StatelessWidget {
  const ChatModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '채팅 모델',
        actions: [
          CommonAppBarIconButton(
            icon: Icons.add,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomModelScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatModelSettingsProvider>(
        builder: (context, provider, child) {
          final availableModels = provider.availableModels;

          // Build provider dropdown items: built-in (except 'custom') + each custom provider
          final dropdownItems = <DropdownMenuItem<String>>[];
          for (final p in ChatModelProvider.values) {
            if (p == ChatModelProvider.custom) continue;
            dropdownItems.add(DropdownMenuItem(
              value: p.name,
              child: Text(p.displayName),
            ));
          }
          for (final cp in provider.customProviders) {
            dropdownItems.add(DropdownMenuItem(
              value: 'custom:${cp.id}',
              child: Text(cp.name),
            ));
          }

          // Current selection key
          final selectedKey = provider.selectedProvider == ChatModelProvider.custom
              && provider.selectedCustomProviderId != null
              ? 'custom:${provider.selectedCustomProviderId}'
              : provider.selectedProvider.name;

          return ListView(
            children: [
              _buildSectionHeader(context, '제조사'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: dropdownItems.any((i) => i.value == selectedKey)
                      ? selectedKey
                      : ChatModelProvider.all.name,
                  isExpanded: true,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: dropdownItems,
                  onChanged: (value) {
                    if (value == null) return;
                    if (value.startsWith('custom:')) {
                      final cpId = value.substring(7);
                      provider.setCustomProviderSelection(cpId);
                    } else {
                      final p = ChatModelProvider.values.firstWhere(
                        (e) => e.name == value,
                        orElse: () => ChatModelProvider.all,
                      );
                      provider.setProvider(p);
                    }
                  },
                ),
              ),
              const Divider(),
              _buildSectionHeader(context, '사용 모델'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<UnifiedModel>(
                  value: availableModels.contains(provider.selectedModel)
                      ? provider.selectedModel
                      : (availableModels.isNotEmpty ? availableModels.first : null),
                  isExpanded: true,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: availableModels
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setModel(value);
                    }
                  },
                ),
              ),
              if (provider.selectedModel.isCustom) ...[
                const Divider(),
                _buildSectionHeader(context, '모델 정보'),
                _buildInfoTile(context, 'API 포맷', provider.selectedModel.apiFormat.displayName),
                if (provider.selectedModel.baseUrl != null)
                  _buildInfoTile(context, 'Base URL', provider.selectedModel.baseUrl!),
                _buildInfoTile(context, 'Model ID', provider.selectedModel.modelId),
              ],
              if (provider.customModels.isNotEmpty) ...[
                const Divider(),
                _buildSectionHeader(context, '커스텀 모델 관리'),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('커스텀 모델 관리'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomModelScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: CommonTitleMedium(
        text: title,
      ),
    );
  }

Widget _buildInfoTile(BuildContext context, String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
