import 'package:flutter/material.dart';

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({Key? key}) : super(key: key);

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Search everything...",
          prefixIcon:
              Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: colorScheme.surfaceVariant,
          filled: true,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        onSubmitted: (query) {
          // TODO: Integrate global search logic
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Global search coming soon!')));
        },
      ),
    );
  }
}


