import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/common_settings_widgets.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String koreanUrl;
  final String? englishUrl;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.koreanUrl,
    this.englishUrl,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: title,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('한국어'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl(koreanUrl),
          ),
          if (englishUrl != null)
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchUrl(englishUrl!),
            ),
        ],
      ),
    );
  }
}
