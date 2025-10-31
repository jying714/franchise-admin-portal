import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual languages when available
    final languages = const [
      DropdownMenuItem(value: 'en', child: Text('English')),
      DropdownMenuItem(
          value: 'es',
          child: Text('EspaÃ±ol (coming soon)',
              style: TextStyle(color: Colors.grey))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Language", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          value: 'en',
          items: languages,
          onChanged: (val) {
            // TODO: Handle language change and persist selection
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language change coming soon!')));
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 4),
        Text("More languages coming soon...",
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}


