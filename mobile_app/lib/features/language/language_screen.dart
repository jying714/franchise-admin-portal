import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/features/language/language_provider.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

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
      // Add more languages here as needed
    ];

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.language,
          style: TextStyle(
            fontSize: shared.DesignTokens.titleFontSize,
            color: scheme.onPrimary,
            fontWeight: shared.UiConfig.fontWeightBold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        centerTitle: true,
      ),
      backgroundColor: scheme.surface,
      body: Padding(
        padding: shared.UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.selectLanguage,
              style: TextStyle(
                fontSize: shared.DesignTokens.bodyFontSize,
                fontWeight: shared.UiConfig.fontWeightBold,
                color: scheme.onSurface,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: 24),
            ...languages.map((lang) => ListTile(
                  title: Text(
                    lang['label']!,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.bodyFontSize,
                      color: scheme.onSurface,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                  trailing: languageProvider.locale.languageCode == lang['code']
                      ? Icon(
                          Icons.check,
                          color: scheme.primary,
                        )
                      : null,
                  onTap: () {
                    languageProvider.setLanguage(lang['code']!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.languageSetTo(lang['label']!),
                          style:
                              TextStyle(color: shared.UiConfig.textColorDark),
                        ),
                        backgroundColor: shared.UiConfig.surfaceColorDark,
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
