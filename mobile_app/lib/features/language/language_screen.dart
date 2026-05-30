import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/language/language_provider.dart';
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
      // Add more languages here as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.language,
          style: TextStyle(
            fontSize: shared.DesignTokens.titleFontSize,
            color: UiConfig.foregroundColorDark,
            fontWeight: UiConfig.fontWeightBold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
        centerTitle: true,
      ),
      backgroundColor: UiConfig.backgroundColorDark,
      body: Padding(
        padding: UiConfig.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.selectLanguage,
              style: TextStyle(
                fontSize: shared.DesignTokens.bodyFontSize,
                fontWeight: UiConfig.fontWeightBold,
                color: UiConfig.textColorDark,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: 24),
            ...languages.map((lang) => ListTile(
                  title: Text(
                    lang['label']!,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.bodyFontSize,
                      color: UiConfig.textColorDark,
                      fontFamily: shared.DesignTokens.fontFamily,
                    ),
                  ),
                  trailing: languageProvider.locale.languageCode == lang['code']
                      ? Icon(
                          Icons.check,
                          color: UiConfig.primaryColor,
                        )
                      : null,
                  onTap: () {
                    languageProvider.setLanguage(lang['code']!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.languageSetTo(lang['label']!),
                          style: TextStyle(color: UiConfig.textColorDark),
                        ),
                        backgroundColor: UiConfig.surfaceColorDark,
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
