import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/features/language/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context)!;

    // Supported languages
    final languages = [
      {'code': 'en', 'label': loc.languageEnglish},
      {'code': 'es', 'label': loc.languageSpanish},
      // Add more languages here as needed:
      // {'code': 'fr', 'label': loc.languageFrench},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.language,
          style: const TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: DesignTokens.foregroundColorDark,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColorDark),
        centerTitle: true,
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.selectLanguage,
              style: const TextStyle(
                fontSize: DesignTokens.bodyFontSize,
                fontWeight: DesignTokens.titleFontWeight,
                color: DesignTokens.textColor,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: DesignTokens.gridSpacing * 2),
            ...languages.map((lang) => ListTile(
                  title: Text(
                    lang['label']!,
                    style: const TextStyle(
                      fontSize: DesignTokens.bodyFontSize,
                      color: DesignTokens.textColor,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  trailing: languageProvider.locale.languageCode == lang['code']
                      ? const Icon(Icons.check,
                          color: DesignTokens.primaryColor)
                      : null,
                  onTap: () {
                    languageProvider.setLanguage(lang['code']!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.languageSetTo(lang['label']!),
                          style: const TextStyle(color: DesignTokens.textColor),
                        ),
                        backgroundColor: DesignTokens.surfaceColor,
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}
