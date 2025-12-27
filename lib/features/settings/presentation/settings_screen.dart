import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    // Helper to get display name
    String _getLanguageName(String code) {
      switch (code) {
        case 'en': return 'English';
        case 'gu': return 'ગુજરાતી (Gujarati)';
        case 'hi': return 'हिन्दी (Hindi)';
        default: return 'System Default';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Language / ભાષા / भाषा'),
            subtitle: Text(_getLanguageName(currentLocale?.languageCode ?? 'system')),
          ),
          const Divider(),
          RadioListTile<String?>(
            title: const Text('System Default'),
            value: null,
            groupValue: currentLocale?.languageCode,
            onChanged: (val) {
              ref.read(localeProvider.notifier).setLocale(null);
            },
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: currentLocale?.languageCode,
            onChanged: (val) {
               if (val != null) ref.read(localeProvider.notifier).setLocale(Locale(val));
            },
          ),
          RadioListTile<String>(
            title: const Text('ગુજરાતી'),
            value: 'gu',
            groupValue: currentLocale?.languageCode,
            onChanged: (val) {
               if (val != null) ref.read(localeProvider.notifier).setLocale(Locale(val));
            },
          ),
          RadioListTile<String>(
            title: const Text('हिन्दी'),
            value: 'hi',
            groupValue: currentLocale?.languageCode,
            onChanged: (val) {
               if (val != null) ref.read(localeProvider.notifier).setLocale(Locale(val));
            },
          ),
        ],
      ),
    );
  }
}
