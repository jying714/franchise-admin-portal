import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/theme_provider.dart';

class ThemeModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isSystem = themeProvider.themeMode == ThemeMode.system;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Theme", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            ChoiceChip(
              label: const Text("Light"),
              selected: themeProvider.themeMode == ThemeMode.light,
              onSelected: (_) => themeProvider.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("Dark"),
              selected: isDark,
              onSelected: (_) => themeProvider.setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("System"),
              selected: isSystem,
              onSelected: (_) => themeProvider.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
      ],
    );
  }
}
