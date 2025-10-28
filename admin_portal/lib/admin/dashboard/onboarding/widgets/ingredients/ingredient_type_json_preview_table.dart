import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/ingredient_type_model.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class IngredientTypeJsonPreviewTable extends StatelessWidget {
  final String rawJson;
  final List<IngredientType>? previewTypes;

  const IngredientTypeJsonPreviewTable({
    Key? key,
    required this.rawJson,
    required this.previewTypes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    List<IngredientType> parsedTypes = [];
    String? errorMessage;

    try {
      final parsed = json.decode(rawJson);
      if (parsed is List) {
        parsedTypes = parsed.map((item) {
          return IngredientType(
            id: null,
            name: item['name'] ?? '',
            description: item['description'],
            sortOrder: item['sortOrder'],
            systemTag: item['systemTag'],
            visibleInApp: item['visibleInApp'] ?? true,
            createdAt: null,
            updatedAt: null,
          );
        }).toList();
      } else {
        errorMessage = loc.invalidJsonFormat;
      }
    } catch (e, stack) {
      errorMessage = loc.jsonParseError;
      ErrorLogger.log(
        message: 'Failed to parse ingredient type JSON preview',
        source: 'ingredient_type_json_preview_table.dart',
        screen: 'ingredient_type_management_screen',
        severity: 'warning',
        stack: stack.toString(),
        contextData: {'rawInput': rawJson},
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceColor,
        border: Border.all(color: DesignTokens.cardBorderColor),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(16),
      child: errorMessage != null
          ? Text(
              errorMessage,
              style: TextStyle(color: colorScheme.error),
            )
          : parsedTypes.isEmpty
              ? Text(loc.noPreviewData)
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: [
                      DataColumn(label: Text(loc.name)),
                      DataColumn(label: Text(loc.description)),
                      DataColumn(label: Text(loc.sortOrder)),
                      DataColumn(label: Text(loc.systemTag)),
                      DataColumn(label: Text(loc.visibleInApp)),
                    ],
                    rows: parsedTypes.map((type) {
                      return DataRow(cells: [
                        DataCell(Text(type.name)),
                        DataCell(Text(type.description ?? '-')),
                        DataCell(Text(type.sortOrder?.toString() ?? '-')),
                        DataCell(Text(type.systemTag ?? '-')),
                        DataCell(Icon(
                          type.visibleInApp ? Icons.check : Icons.close,
                          color: type.visibleInApp
                              ? colorScheme.primary
                              : colorScheme.error,
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
    );
  }
}
