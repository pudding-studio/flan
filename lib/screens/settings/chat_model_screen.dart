import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat/chat_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../widgets/common/common_appbar.dart';

class ChatModelScreen extends StatelessWidget {
  const ChatModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '채팅 모델',
      ),
      body: Consumer<ChatModelSettingsProvider>(
        builder: (context, provider, child) {
          final availableModels =
              ChatModel.getModelsByProvider(provider.selectedProvider);

          return ListView(
            children: [
              _buildSectionHeader(context, '지원 제조사'),
              _buildListTile(
                context: context,
                icon: Icons.business,
                title: '제조사',
                trailing: DropdownButton<ChatModelProvider>(
                  value: provider.selectedProvider,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: ChatModelProvider.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setProvider(value);
                    }
                  },
                ),
              ),
              const Divider(),
              _buildSectionHeader(context, '사용 모델'),
              _buildListTile(
                context: context,
                icon: Icons.psychology,
                title: '모델',
                trailing: DropdownButton<ChatModel>(
                  value: provider.selectedModel,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: availableModels
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setModel(value);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
    );
  }
}
