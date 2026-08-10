import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

class PromoFormDialog extends StatefulWidget {
  final shared.Promo? promo;
  final Future<void> Function(shared.Promo)? onSave;

  const PromoFormDialog({super.key, this.promo, this.onSave});

  @override
  State<PromoFormDialog> createState() => _PromoFormDialogState();
}

class _PromoFormDialogState extends State<PromoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _code;
  late final TextEditingController _discount;
  late final TextEditingController _maxUses;
  late final TextEditingController _minOrder;
  late final TextEditingController _bogoBuy;
  late final TextEditingController _bogoGet;
  late final TextEditingController _bogoPct;
  late final TextEditingController _freeMenuItemId;
  late final TextEditingController _freeMaxPrice;
  late final TextEditingController _deliveryValue;
  late final TextEditingController _minToppings;

  late String _type;
  late String _maxUsesType;
  late String _bogoApplyTo;
  late String _deliveryDiscountType;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _active;
  late bool _stackable;
  bool _saving = false;
  String? _error;

  final Set<String> _selectedCategoryIds = <String>{};
  final Set<String> _selectedMenuItemIds = <String>{};
  final Set<String> _selectedSizeLabels = <String>{};

  List<shared.Category> _categories = const [];
  List<shared.MenuItem> _menuItems = const [];
  bool _catalogLoading = true;
  String? _catalogError;

  StreamSubscription<List<shared.Category>>? _catSub;
  StreamSubscription<List<shared.MenuItem>>? _itemSub;

  bool get _isEdit => widget.promo != null && (widget.promo!.id.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _code = TextEditingController(text: p?.code ?? '');
    _discount = TextEditingController(
      text: (p?.discount ?? 0) > 0 ? _trimNum(p!.discount) : '',
    );
    _maxUses = TextEditingController(text: '${p?.maxUses ?? 0}');
    _minOrder = TextEditingController(
      text: (p?.minOrderValue ?? 0) > 0 ? _trimNum(p!.minOrderValue) : '0',
    );
    _bogoBuy = TextEditingController(text: '${p?.bogoBuyQty ?? 1}');
    _bogoGet = TextEditingController(text: '${p?.bogoGetQty ?? 1}');
    _bogoPct = TextEditingController(
      text: _trimNum(p?.bogoGetDiscountPct ?? 50),
    );
    _freeMenuItemId = TextEditingController(text: p?.freeMenuItemId ?? '');
    _freeMaxPrice = TextEditingController(
      text: p?.freeItemMaxPrice != null ? _trimNum(p!.freeItemMaxPrice!) : '',
    );
    _deliveryValue = TextEditingController(
      text: (p?.deliveryDiscountValue ?? 0) > 0
          ? _trimNum(p!.deliveryDiscountValue)
          : '',
    );
    _minToppings = TextEditingController(
      text: p?.qualifyMinToppings?.toString() ?? '',
    );

    _selectedCategoryIds.addAll(p?.qualifyCategoryIds ?? const []);
    final itemIds = (p?.qualifyMenuItemIds.isNotEmpty == true)
        ? p!.qualifyMenuItemIds
        : (p?.items ?? const <String>[]);
    _selectedMenuItemIds.addAll(itemIds);
    _selectedSizeLabels.addAll(p?.qualifySizeLabels ?? const []);

    _type = shared.PromoType.normalize(p?.type ?? shared.PromoType.percent);
    if (!shared.PromoType.all.contains(_type)) {
      _type = shared.PromoType.percent;
    }
    _maxUsesType = shared.PromoMaxUsesType.normalize(p?.maxUsesType ?? 'total');
    _bogoApplyTo = shared.BogoApplyTo.normalize(p?.bogoApplyTo);
    _deliveryDiscountType =
        shared.DeliveryDiscountType.normalize(p?.deliveryDiscountType);
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _active = p?.active ?? true;
    _stackable = p?.stackable ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) => _bindCatalog());
  }

  void _bindCatalog() {
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'default') {
      setState(() {
        _catalogLoading = false;
        _catalogError = 'Select a franchise to load menu data';
      });
      return;
    }

    _catSub?.cancel();
    _itemSub?.cancel();

    _catSub = fs.getCategories(franchiseId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _categories = list.where((c) => c.isActive).toList()
            ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
          _catalogLoading = false;
          _catalogError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _catalogLoading = false;
          _catalogError = 'Categories failed: $e';
        });
      },
    );

    _itemSub = fs.getMenuItems(franchiseId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _menuItems = list.where((m) => !m.archived && m.available).toList()
            ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _catalogLoading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _catalogError = 'Menu items failed: $e';
          _catalogLoading = false;
        });
      },
    );
  }

  /// Size labels derived from live menu (sizes + sizePrices keys).
  List<String> get _availableSizeLabels {
    final out = <String>{};
    for (final m in _menuItems) {
      final sizes = m.sizes;
      if (sizes != null) {
        for (final s in sizes) {
          final label = s.label.trim();
          if (label.isNotEmpty) out.add(label);
        }
      }
      final prices = m.sizePrices;
      if (prices != null) {
        for (final k in prices.keys) {
          final label = k.trim();
          if (label.isNotEmpty) out.add(label);
        }
      }
    }
    final list = out.toList()..sort();
    return list;
  }

  List<shared.MenuItem> get _itemsForPicker {
    if (_selectedCategoryIds.isEmpty) return _menuItems;
    return _menuItems
        .where((m) =>
            _selectedCategoryIds.contains(m.categoryId) ||
            _selectedCategoryIds.contains(m.category))
        .toList();
  }

  static String _trimNum(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _itemSub?.cancel();
    _name.dispose();
    _description.dispose();
    _code.dispose();
    _discount.dispose();
    _maxUses.dispose();
    _minOrder.dispose();
    _bogoBuy.dispose();
    _bogoGet.dispose();
    _bogoPct.dispose();
    _freeMenuItemId.dispose();
    _freeMaxPrice.dispose();
    _deliveryValue.dispose();
    _minToppings.dispose();
    super.dispose();
  }

  String _preview() {
    switch (_type) {
      case shared.PromoType.percent:
        return '${_discount.text}% off order';
      case shared.PromoType.amount:
        return '\$${_discount.text} off order';
      case shared.PromoType.itemPercent:
        return '${_discount.text}% off qualifying items';
      case shared.PromoType.itemAmount:
        return '\$${_discount.text} off qualifying items';
      case shared.PromoType.bogo:
        return 'Buy ${_bogoBuy.text} get ${_bogoGet.text} at ${_bogoPct.text}% off';
      case shared.PromoType.freeItem:
        final match = _menuItems.cast<shared.MenuItem?>().firstWhere(
              (m) => m?.id == _freeMenuItemId.text.trim(),
              orElse: () => null,
            );
        return 'Free item ${match?.name ?? _freeMenuItemId.text}';
      case shared.PromoType.delivery:
        if (_deliveryDiscountType == shared.DeliveryDiscountType.free) {
          return 'Free delivery';
        }
        return 'Delivery deal ($_deliveryDiscountType)';
      default:
        return shared.PromoType.label(_type);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_active &&
        DateTime(_endDate.year, _endDate.month, _endDate.day).isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )) {
      setState(() => _error = 'Active promos need an end date today or later');
      return;
    }

    final discountVal = double.tryParse(_discount.text.trim()) ?? 0.0;
    final minOrderVal = double.tryParse(_minOrder.text.trim()) ?? 0.0;
    final maxUsesVal = int.tryParse(_maxUses.text.trim()) ?? 0;
    final minTop = int.tryParse(_minToppings.text.trim());
    final menuIds = _selectedMenuItemIds.toList();
    final catIds = _selectedCategoryIds.toList();
    final sizes = _selectedSizeLabels.toList();

    final promo = shared.Promo(
      id: _isEdit ? widget.promo!.id : '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      code: _code.text.trim().toUpperCase(),
      type: _type,
      items: menuIds,
      discount: discountVal,
      maxUses: maxUsesVal,
      maxUsesType: _maxUsesType,
      minOrderValue: minOrderVal,
      startDate: _startDate,
      endDate: _endDate,
      active: _active,
      imageUrl: widget.promo?.imageUrl,
      sortOrder: widget.promo?.sortOrder ?? 0,
      channels: widget.promo?.channels ?? const <String>[],
      qualifyMenuItemIds: menuIds,
      qualifyCategoryIds: catIds,
      qualifySizeLabels: sizes,
      qualifyMinToppings: minTop,
      qualifyMaxToppings: widget.promo?.qualifyMaxToppings,
      excludeMenuItemIds: widget.promo?.excludeMenuItemIds ?? const <String>[],
      bogoBuyQty: int.tryParse(_bogoBuy.text.trim()) ?? 1,
      bogoGetQty: int.tryParse(_bogoGet.text.trim()) ?? 1,
      bogoGetDiscountPct: double.tryParse(_bogoPct.text.trim()) ?? 50,
      bogoApplyTo: _bogoApplyTo,
      freeMenuItemId: _freeMenuItemId.text.trim().isEmpty
          ? null
          : _freeMenuItemId.text.trim(),
      freeItemMaxPrice: double.tryParse(_freeMaxPrice.text.trim()),
      deliveryDiscountType: _deliveryDiscountType,
      deliveryDiscountValue: double.tryParse(_deliveryValue.text.trim()) ?? 0,
      stackable: _stackable,
      priority: widget.promo?.priority ?? 0,
      target: widget.promo?.target,
      timeRules: widget.promo?.timeRules,
    );

    final onSave = widget.onSave;
    if (onSave == null) {
      setState(() => _error = 'Save handler missing');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await onSave(promo);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Save failed: $e';
      });
    }
  }

  Widget _numField({
    required TextEditingController controller,
    required String label,
    String? helper,
    bool requiredField = false,
    bool allowDecimal = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) {
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        if (double.tryParse(v.trim()) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _chipWrap({
    required List<MapEntry<String, String>> options,
    required Set<String> selected,
    required void Function(String id, bool select) onToggle,
    String emptyMessage = 'None loaded',
  }) {
    if (_catalogLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (options.isEmpty) {
      return Text(
        emptyMessage,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((e) {
        final on = selected.contains(e.key);
        return FilterChip(
          label: Text(e.value),
          selected: on,
          onSelected: (v) => onToggle(e.key, v),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsDiscount = _type == shared.PromoType.percent ||
        _type == shared.PromoType.amount ||
        _type == shared.PromoType.itemPercent ||
        _type == shared.PromoType.itemAmount;

    final categoryOptions = _categories
        .map((c) => MapEntry(
            c.id,
            c.displayName?.trim().isNotEmpty == true
                ? c.displayName!.trim()
                : c.name))
        .toList();

    final itemOptions =
        _itemsForPicker.map((m) => MapEntry(m.id, m.name)).toList();

    final sizeOptions =
        _availableSizeLabels.map((s) => MapEntry(s, s)).toList();

    final freeItemValue = _menuItems.any((m) => m.id == _freeMenuItemId.text)
        ? _freeMenuItemId.text
        : null;

    return AlertDialog(
      title: Text(_isEdit ? 'Edit promo code' : 'Add promo code'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Preview: ${_preview()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_catalogError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _catalogError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Deal type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: shared.PromoType.all
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(shared.PromoType.label(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    helperText: 'Customer enters this at checkout',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                if (needsDiscount)
                  _numField(
                    controller: _discount,
                    label: _type == shared.PromoType.percent ||
                            _type == shared.PromoType.itemPercent
                        ? 'Percent off'
                        : 'Amount off (\$)',
                    requiredField: true,
                  ),
                if (_type == shared.PromoType.bogo) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _numField(
                          controller: _bogoBuy,
                          label: 'Buy qty',
                          allowDecimal: false,
                          requiredField: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _numField(
                          controller: _bogoGet,
                          label: 'Get qty',
                          allowDecimal: false,
                          requiredField: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _numField(
                          controller: _bogoPct,
                          label: 'Get % off',
                          helper: '50 = half off',
                          requiredField: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _bogoApplyTo,
                    decoration: const InputDecoration(
                      labelText: 'Apply discount to',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: shared.BogoApplyTo.all
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _bogoApplyTo = v);
                    },
                  ),
                ],
                if (_type == shared.PromoType.freeItem) ...[
                  DropdownButtonFormField<String>(
                    value: freeItemValue,
                    decoration: const InputDecoration(
                      labelText: 'Free menu item',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _menuItems
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _freeMenuItemId.text = v ?? '';
                      });
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    controller: _freeMaxPrice,
                    label: 'Max free value (optional)',
                  ),
                ],
                if (_type == shared.PromoType.delivery) ...[
                  DropdownButtonFormField<String>(
                    value: _deliveryDiscountType,
                    decoration: const InputDecoration(
                      labelText: 'Delivery deal',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: shared.DeliveryDiscountType.all
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _deliveryDiscountType = v);
                      }
                    },
                  ),
                  if (_deliveryDiscountType !=
                      shared.DeliveryDiscountType.free) ...[
                    const SizedBox(height: 12),
                    _numField(
                      controller: _deliveryValue,
                      label: _deliveryDiscountType ==
                              shared.DeliveryDiscountType.percent
                          ? 'Percent off delivery'
                          : 'Amount off delivery',
                      requiredField: true,
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                const Divider(),
                _sectionLabel('Qualification (from live menu)'),
                Text(
                  'Leave categories/items empty to apply to all items. '
                  'Selecting categories filters the item list.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Text('Categories',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                _chipWrap(
                  options: categoryOptions,
                  selected: _selectedCategoryIds,
                  emptyMessage: 'No categories for this franchise',
                  onToggle: (id, select) {
                    setState(() {
                      if (select) {
                        _selectedCategoryIds.add(id);
                      } else {
                        _selectedCategoryIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text('Menu items',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                _chipWrap(
                  options: itemOptions,
                  selected: _selectedMenuItemIds,
                  emptyMessage: 'No menu items loaded',
                  onToggle: (id, select) {
                    setState(() {
                      if (select) {
                        _selectedMenuItemIds.add(id);
                      } else {
                        _selectedMenuItemIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text('Sizes', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                _chipWrap(
                  options: sizeOptions,
                  selected: _selectedSizeLabels,
                  emptyMessage: 'No sizes found on menu items',
                  onToggle: (id, select) {
                    setState(() {
                      if (select) {
                        _selectedSizeLabels.add(id);
                      } else {
                        _selectedSizeLabels.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _numField(
                  controller: _minToppings,
                  label: 'Min toppings (optional)',
                  allowDecimal: false,
                ),
                const SizedBox(height: 12),
                const Divider(),
                _numField(
                  controller: _minOrder,
                  label: 'Minimum order (\$)',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _numField(
                        controller: _maxUses,
                        label: 'Max uses (0 = unlimited)',
                        allowDecimal: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _maxUsesType,
                        decoration: const InputDecoration(
                          labelText: 'Max uses type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: shared.PromoMaxUsesType.all
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _maxUsesType = v);
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Stackable with other codes'),
                  value: _stackable,
                  onChanged: (v) => setState(() => _stackable = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Start: ${_startDate.toLocal().toString().split(' ').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'End: ${_endDate.toLocal().toString().split(' ').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
