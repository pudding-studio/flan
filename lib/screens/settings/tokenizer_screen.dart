import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tokenizer_provider.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_title_medium.dart';

class TokenizerScreen extends StatelessWidget {
  const TokenizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '토크나이저',
      ),
      body: Consumer<TokenizerProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              _buildSectionHeader(context, '토크나이저 선택'),
              _buildListTile(
                context: context,
                icon: Icons.token,
                title: '토크나이저',
                trailing: DropdownButton<TokenizerType>(
                  value: provider.selectedTokenizer,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: TokenizerType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setTokenizer(value);
                    }
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '토크나이저는 텍스트를 토큰으로 변환하는 방식을 결정합니다. '
                  '모델에 따라 적합한 토크나이저가 다를 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
      child: CommonTitleMedium(
        text: title,
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
