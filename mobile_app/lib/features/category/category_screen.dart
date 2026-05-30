import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
import 'package:franchise_mobile_app/widgets/loading_shimmer_widget.dart';
import 'package:franchise_mobile_app/widgets/menu_item_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _sortBy = 'Name';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: UiConfig.primaryColor,
      ),
      backgroundColor: UiConfig.backgroundColor,
      body: SafeArea(
        bottom: true,
        child: Consumer<shared.FranchiseProvider>(
          builder: (context, provider, child) {
            if (!provider.hasValidFranchise) {
              return const Center(child: CircularProgressIndicator());
            }
            final fid = provider.currentFranchiseId;
            return Center(
              child: Padding(
                padding: UiConfig.defaultScreenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Category: ${widget.categoryName}',
                      style: UiConfig.titleStyle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Franchise-aware (fid: $fid) via FranchiseProvider + UiConfig',
                      style: UiConfig.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
