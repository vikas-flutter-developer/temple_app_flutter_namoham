import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    
    final currentLocale = localeProvider.locale?.languageCode ?? 'en';

    final languages = [
      {'code': 'en', 'name': l10n.english, 'nativeName': 'English'},
      {'code': 'mr', 'name': l10n.marathi, 'nativeName': 'मराठी'},
      {'code': 'hi', 'name': l10n.hindi, 'nativeName': 'हिंदी'},
      {'code': 'gu', 'name': l10n.gujarati, 'nativeName': 'ગુજરાતી'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          final isSelected = currentLocale == language['code'];

          return ListTile(
            leading: Icon(
              Icons.language,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              language['nativeName']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  )
                : null,
            onTap: () {
              localeProvider.setLocale(Locale(language['code']!));
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
