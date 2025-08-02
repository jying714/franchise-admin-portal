import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class ScrollingJsonEditor extends StatefulWidget {
  final String? initialJson;
  final void Function(String json) onChanged;
  final double height;
  final bool readOnly;
  final AppLocalizations loc;

  const ScrollingJsonEditor({
    Key? key,
    required this.onChanged,
    this.initialJson,
    this.height = 455,
    this.readOnly = false,
    required this.loc,
  }) : super(key: key);

  @override
  State<ScrollingJsonEditor> createState() => _ScrollingJsonEditorState();
}

class _ScrollingJsonEditorState extends State<ScrollingJsonEditor> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialJson ?? '');
    _scrollController = ScrollController();
    _controller.addListener(_handleChange);
  }

  void _handleChange() {
    try {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        setState(() => _error = null);
        widget.onChanged(text);
        return;
      }

      final parsed = json.decode(text);
      if (parsed is! Map && parsed is! List) {
        throw const FormatException('Invalid JSON structure');
      }

      setState(() => _error = null);
      widget.onChanged(text);
    } catch (e, stack) {
      setState(() => _error = widget.loc.invalidJsonFormat ?? 'Invalid JSON');
      ErrorLogger.log(
        message: 'Invalid JSON in ScrollingJsonEditor',
        source: 'scrolling_json_editor.dart',
        screen: 'ingredient_type_management_screen',
        severity: 'warning',
        stack: stack.toString(),
        contextData: {
          'input': _controller.text,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = widget.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: DesignTokens.surfaceColor,
            border: Border.all(
              color: _error != null
                  ? colorScheme.error
                  : DesignTokens.cardBorderColor,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          padding: const EdgeInsets.all(12),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: TextField(
                controller: _controller,
                maxLines: null,
                readOnly: widget.readOnly,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration.collapsed(
                  hintText: '{ "key": "value" }',
                ),
                keyboardType: TextInputType.multiline,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\u0000]')),
                ],
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
