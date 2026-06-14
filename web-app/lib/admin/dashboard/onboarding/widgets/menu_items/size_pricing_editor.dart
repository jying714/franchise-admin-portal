import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/ui_config.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:collection/collection.dart';

class SizePricingEditor extends StatefulWidget {
  final List<shared.SizeData> sizes;
  final void Function(List<shared.SizeData>) onChanged;
  final Widget? trailingTemplateDropdown;

  const SizePricingEditor({
    super.key,
    required this.sizes,
    required this.onChanged,
    this.trailingTemplateDropdown,
  });

  @override
  State<SizePricingEditor> createState() => _SizePricingEditorState();
}

class _SizePricingEditorState extends State<SizePricingEditor> {
  late List<shared.SizeData> _localSizes;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _localSizes = List<shared.SizeData>.from(widget.sizes.map((s) => s.copy()));
  }

  @override
  void didUpdateWidget(covariant SizePricingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const DeepCollectionEquality().equals(widget.sizes, oldWidget.sizes)) {
      _localSizes =
          List<shared.SizeData>.from(widget.sizes.map((s) => s.copy()));
    }
  }

  void _updateSizes() {
    try {
      widget.onChanged(List<shared.SizeData>.from(_localSizes));
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to update size pricing',
        source: 'SizePricingEditor',
        severity: 'error',
        stack: stack.toString(),
      );
    }
  }

  void _addSize() {
    setState(() {
      _localSizes.add(shared.SizeData(
        label: '',
        basePrice: 0.0,
        toppingPrice: 0.0,
      ));
    });
    _updateSizes();
  }

  void _removeSize(int index) {
    if (_localSizes.length <= 1) return; // Prevent removing last size
    setState(() {
      _localSizes.removeAt(index);
    });
    _updateSizes();
  }

  void _updateField(int index,
      {String? label, double? basePrice, double? toppingPrice}) {
    setState(() {
      final current = _localSizes[index];
      _localSizes[index] = current.copyWith(
        label: label ?? current.label,
        basePrice: basePrice ?? current.basePrice,
        toppingPrice: toppingPrice ?? current.toppingPrice,
      );
    });
    _updateSizes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                loc.sizePricing ?? 'Size Pricing',
                style: UiConfig.titleStyle,
              ),
            ),
            if (widget.trailingTemplateDropdown != null) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: widget.trailingTemplateDropdown!,
              ),
            ]
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          itemCount: _localSizes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final size = _localSizes[index];
            final isHovered = _hoveredIndex == index;

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: size.label,
                        decoration: InputDecoration(
                          labelText: loc.sizeLabel ?? 'Label',
                          hintText: 'e.g. Small, Medium, Large',
                        ),
                        onChanged: (val) => _updateField(index, label: val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: size.basePrice.toStringAsFixed(2),
                        decoration: InputDecoration(
                          labelText: loc.basePrice ?? 'Base Price',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          _updateField(index, basePrice: parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: size.toppingPrice.toStringAsFixed(2),
                        decoration: InputDecoration(
                          labelText: loc.toppingPrice ?? 'Topping Price',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          _updateField(index, toppingPrice: parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeSize(index),
                      tooltip: loc.removeSize ?? 'Remove Size',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSize,
            icon: const Icon(Icons.add),
            label: Text(loc.addSize ?? 'Add Size'),
          ),
        ),
      ],
    );
  }
}
