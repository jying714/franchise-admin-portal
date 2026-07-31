import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual languages when available
    final scheme = Theme.of(context).colorScheme;
    final languages = [
      const DropdownMenuItem(value: 'en', child: Text('English')),
      DropdownMenuItem(
        value: 'es',
        enabled: false,
        child: Text(
          'Español (coming soon)',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Language", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: 'en',
          items: languages,
          onChanged: (val) {
            if (val == null || val == 'en') return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Additional languages coming soon.'),
                backgroundColor: scheme.inverseSurface,
              ),
            );
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Only English is available in this build.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
