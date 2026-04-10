import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/tokenizer_provider.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_title_medium.dart';

class TokenizerScreen extends StatelessWidget {
  const TokenizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.tokenizerTitle,
      ),
      body: Consumer<TokenizerProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              _buildSectionHeader(context, l10n.tokenizerSectionTitle),
              _buildListTile(
                context: context,
                icon: Icons.token,
                title: l10n.tokenizerLabel,
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
                  l10n.tokenizerDescription,
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
