import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../packages/shared_core/lib/src/core/models/customization.dart';
import 'package:franchise_admin_portal/admin/menu/customization_types.dart';

// Dialog for full-featured editing of menu customizations/groups/options.
class MenuItemCustomizationsDialog extends StatefulWidget {
  final List<CustomizationGroup> initialGroups;
  final ValueChanged<List<CustomizationGroup>>? onSave;

  const MenuItemCustomizationsDialog({
    super.key,
    required this.initialGroups,
    this.onSave,
  });

  @override
  State<MenuItemCustomizationsDialog> createState() =>
      _MenuItemCustomizationsDialogState();
}

class _MenuItemCustomizationsDialogState
    extends State<MenuItemCustomizationsDialog> {
  late List<CustomizationGroup> _groups;

  @override
  void initState() {
    super.initState();
    // Deep copy for edit safety, include all advanced fields.
    _groups = widget.initialGroups
        .map((g) => CustomizationGroup(
              groupName: g.groupName,
              type: g.type,
              minSelect: g.minSelect,
              maxSelect: g.maxSelect,
              maxFree: g.maxFree,
              allowExtra: g.allowExtra,
              allowSide: g.allowSide,
              required: g.required,
              groupUpcharge: g.groupUpcharge,
              groupTag: g.groupTag,
              options: g.options
                  .map((o) => CustomizationOption(
                        name: o.name,
                        price: o.price,
                        upcharges: o.upcharges,
                        isDefault: o.isDefault,
                        outOfStock: o.outOfStock,
                        allowExtra: o.allowExtra,
                        allowSide: o.allowSide,
                        quantity: o.quantity,
                        portion: o.portion,
                        tag: o.tag,
                      ))
                  .toList(),
            ))
        .toList();
  }

  void _addGroup() {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // Optionally, show a SnackBar or AlertDialog here if you want to warn the user.
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Localization missing! [debug]'))
      // );
      return; // Just exit the function early.
    }
    String groupName = '';
    String type = 'single';
    int minSelect = 1;
    int maxSelect = 1;
    int? maxFree;
    bool allowExtra = false;
    bool allowSide = false;
    bool required = false;
    double? groupUpcharge;
    String? groupTag;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.addCustomization),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: loc.customizationName),
                    onChanged: (v) => groupName = v,
                    autofocus: true,
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(labelText: loc.type),
                    items: [
                      DropdownMenuItem(
                          value: 'single', child: Text(loc.singleSelect)),
                      DropdownMenuItem(
                          value: 'multi', child: Text(loc.multiSelect)),
                      DropdownMenuItem(
                          value: 'quantity', child: Text(loc.quantitySelect)),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => type = v ?? 'single'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: loc.minSelect),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => minSelect = int.tryParse(v) ?? 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: loc.maxSelect),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => maxSelect = int.tryParse(v) ?? 1,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.firstNFreeLabel),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => maxFree = int.tryParse(v),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.groupUpcharge),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => groupUpcharge = double.tryParse(v),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.groupTag),
                    onChanged: (v) => groupTag = v,
                  ),
                  SwitchListTile(
                    title: Text(loc.allowExtra),
                    value: allowExtra,
                    onChanged: (v) => setStateDialog(() => allowExtra = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.allowSide),
                    value: allowSide,
                    onChanged: (v) => setStateDialog(() => allowSide = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.requiredField),
                    value: required,
                    onChanged: (v) => setStateDialog(() => required = v),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (groupName.trim().isNotEmpty) {
                setState(() {
                  _groups.add(CustomizationGroup(
                    groupName: groupName,
                    type: type,
                    minSelect: minSelect,
                    maxSelect: maxSelect,
                    maxFree: maxFree,
                    allowExtra: allowExtra,
                    allowSide: allowSide,
                    required: required,
                    groupUpcharge: groupUpcharge,
                    groupTag: groupTag,
                    options: [],
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  void _addOption(int groupIdx) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Localization missing! [debug]'))
      // );
      return;
    }
    String optName = '';
    double optPrice = 0.0;
    Map<String, double>? upcharges;
    bool isDefault = false;
    bool outOfStock = false;
    bool allowExtra = false;
    bool allowSide = false;
    int quantity = 1;
    Portion portion = Portion.whole;
    String? tag;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.addOption),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: loc.customizationName),
                    onChanged: (v) => optName = v,
                    autofocus: true,
                  ),
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: loc.customizationPrice),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => optPrice = double.tryParse(v) ?? 0.0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.upchargePerSize),
                    keyboardType: TextInputType.text,
                    onChanged: (v) {
                      // Format: "Small:1.5,Large:2.0"
                      upcharges = {};
                      for (final entry in v.split(',')) {
                        final parts = entry.split(':');
                        if (parts.length == 2) {
                          final key = parts[0].trim();
                          final val = double.tryParse(parts[1].trim());
                          if (key.isNotEmpty && val != null)
                            upcharges![key] = val;
                        }
                      }
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.tag),
                    onChanged: (v) => tag = v,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Portion>(
                          value: portion,
                          decoration: InputDecoration(labelText: loc.portion),
                          items: Portion.values
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.toString().split('.').last),
                                  ))
                              .toList(),
                          onChanged: (v) => setStateDialog(
                              () => portion = v ?? Portion.whole),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: loc.quantity),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => quantity = int.tryParse(v) ?? 1,
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: Text(loc.setAsDefault),
                    value: isDefault,
                    onChanged: (v) => setStateDialog(() => isDefault = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.outOfStock),
                    value: outOfStock,
                    onChanged: (v) => setStateDialog(() => outOfStock = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.allowExtra),
                    value: allowExtra,
                    onChanged: (v) => setStateDialog(() => allowExtra = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.allowSide),
                    value: allowSide,
                    onChanged: (v) => setStateDialog(() => allowSide = v),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (optName.trim().isNotEmpty) {
                setState(() {
                  _groups[groupIdx].options.add(CustomizationOption(
                        name: optName,
                        price: optPrice,
                        upcharges: upcharges,
                        isDefault: isDefault,
                        outOfStock: outOfStock,
                        allowExtra: allowExtra,
                        allowSide: allowSide,
                        quantity: quantity,
                        portion: portion,
                        tag: tag,
                      ));
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  void _editOption(int groupIdx, int optIdx) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Localization missing! [debug]'))
      // );
      return;
    }
    var opt = _groups[groupIdx].options[optIdx];
    String optName = opt.name;
    double optPrice = opt.price;
    Map<String, double>? upcharges =
        opt.upcharges != null ? Map.from(opt.upcharges!) : null;
    bool isDefault = opt.isDefault;
    bool outOfStock = opt.outOfStock;
    bool allowExtra = opt.allowExtra;
    bool allowSide = opt.allowSide;
    int quantity = opt.quantity;
    Portion portion = opt.portion;
    String? tag = opt.tag;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.editCustomization),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: optName,
                    decoration:
                        InputDecoration(labelText: loc.customizationName),
                    onChanged: (v) => optName = v,
                    autofocus: true,
                  ),
                  TextFormField(
                    initialValue: optPrice.toString(),
                    decoration:
                        InputDecoration(labelText: loc.customizationPrice),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => optPrice = double.tryParse(v) ?? 0.0,
                  ),
                  TextFormField(
                    initialValue: (upcharges?.entries ?? [])
                        .map((e) => '${e.key}:${e.value}')
                        .join(','),
                    decoration: InputDecoration(labelText: loc.upchargePerSize),
                    keyboardType: TextInputType.text,
                    onChanged: (v) {
                      upcharges = {};
                      for (final entry in v.split(',')) {
                        final parts = entry.split(':');
                        if (parts.length == 2) {
                          final key = parts[0].trim();
                          final val = double.tryParse(parts[1].trim());
                          if (key.isNotEmpty && val != null)
                            upcharges![key] = val;
                        }
                      }
                    },
                  ),
                  TextFormField(
                    initialValue: tag ?? '',
                    decoration: InputDecoration(labelText: loc.tag),
                    onChanged: (v) => tag = v,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Portion>(
                          value: portion,
                          decoration: InputDecoration(labelText: loc.portion),
                          items: Portion.values
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.toString().split('.').last),
                                  ))
                              .toList(),
                          onChanged: (v) => setStateDialog(
                              () => portion = v ?? Portion.whole),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: quantity.toString(),
                          decoration: InputDecoration(labelText: loc.quantity),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => quantity = int.tryParse(v) ?? 1,
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: Text(loc.setAsDefault),
                    value: isDefault,
                    onChanged: (v) => setStateDialog(() => isDefault = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.outOfStock),
                    value: outOfStock,
                    onChanged: (v) => setStateDialog(() => outOfStock = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.allowExtra),
                    value: allowExtra,
                    onChanged: (v) => setStateDialog(() => allowExtra = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.allowSide),
                    value: allowSide,
                    onChanged: (v) => setStateDialog(() => allowSide = v),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (optName.trim().isNotEmpty) {
                setState(() {
                  _groups[groupIdx].options[optIdx] = CustomizationOption(
                    name: optName,
                    price: optPrice,
                    upcharges: upcharges,
                    isDefault: isDefault,
                    outOfStock: outOfStock,
                    allowExtra: allowExtra,
                    allowSide: allowSide,
                    quantity: quantity,
                    portion: portion,
                    tag: tag,
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  void _removeOption(int groupIdx, int optIdx) {
    setState(() {
      _groups[groupIdx].options.removeAt(optIdx);
    });
  }

  void _removeGroup(int idx) {
    setState(() {
      _groups.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.customizations,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: loc.addCustomization,
                    onPressed: _addGroup,
                  )
                ],
              ),
              const SizedBox(height: 10),
              _groups.isEmpty
                  ? Center(
                      child: Text(
                        loc.noCustomizations,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _groups.length,
                      itemBuilder: (context, groupIdx) {
                        final g = _groups[groupIdx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            title: Text('${g.groupName} (${g.type})'),
                            subtitle: Text(
                              '${loc.minSelect}: ${g.minSelect}, ${loc.maxSelect}: ${g.maxSelect}'
                              '${g.maxFree != null ? ', ${loc.firstNFree}: ${g.maxFree}' : ''}'
                              '${g.groupUpcharge != null ? ', ${loc.groupUpcharge}: \$${g.groupUpcharge!.toStringAsFixed(2)}' : ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: loc.delete,
                              onPressed: () => _removeGroup(groupIdx),
                            ),
                            children: [
                              if (g.groupTag != null && g.groupTag!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, bottom: 8),
                                  child: Row(
                                    children: [
                                      Text('${loc.tag}: ',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(g.groupTag!),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  if (g.allowExtra)
                                    Chip(label: Text(loc.allowExtra)),
                                  if (g.allowSide)
                                    Chip(label: Text(loc.allowSide)),
                                  if (g.required)
                                    Chip(label: Text(loc.requiredField)),
                                ],
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: g.options.length,
                                itemBuilder: (ctx, optIdx) {
                                  final opt = g.options[optIdx];
                                  return ListTile(
                                    title: Text(
                                        '${opt.name} (\$${opt.price.toStringAsFixed(2)})'
                                        '${opt.upcharges != null && opt.upcharges!.isNotEmpty ? ' [${loc.upchargePerSize}: ${opt.upcharges!.entries.map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}').join(', ')}]' : ''}'),
                                    subtitle: Text(
                                        '${opt.tag != null && opt.tag!.isNotEmpty ? '${loc.tag}: ${opt.tag!} • ' : ''}'
                                        '${loc.portion}: ${opt.portion.name}, '
                                        '${loc.quantity}: ${opt.quantity}'
                                        '${opt.outOfStock ? ' • ${loc.outOfStock}' : ''}'
                                        '${opt.isDefault ? ' • ${loc.setAsDefault}' : ''}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: loc.edit,
                                          onPressed: () =>
                                              _editOption(groupIdx, optIdx),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          tooltip: loc.delete,
                                          onPressed: () =>
                                              _removeOption(groupIdx, optIdx),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                onPressed: () => _addOption(groupIdx),
                                icon: const Icon(Icons.add),
                                label: Text(loc.addOption),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave?.call(_groups);
                      Navigator.pop(context, _groups);
                    },
                    child: Text(loc.save),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
