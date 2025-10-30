import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/promo.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class PromoFormDialog extends StatefulWidget {
  final Promo? promo;
  final Future<void> Function(Promo)? onSave; // <-- FIXED

  const PromoFormDialog({super.key, this.promo, this.onSave}); // <-- FIXED

  @override
  State<PromoFormDialog> createState() => _PromoFormDialogState();
}

class _PromoFormDialogState extends State<PromoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String description;
  late String code;
  late String type;
  late double discount;
  late int maxUses;
  late String maxUsesType;
  late double minOrderValue;
  late DateTime startDate;
  late DateTime endDate;
  late bool active;

  @override
  void initState() {
    super.initState();
    name = widget.promo?.name ?? '';
    description = widget.promo?.description ?? '';
    code = widget.promo?.code ?? '';
    type = widget.promo?.type ?? '';
    discount = widget.promo?.discount ?? 0.0;
    maxUses = widget.promo?.maxUses ?? 0;
    maxUsesType = widget.promo?.maxUsesType ?? 'total';
    minOrderValue = widget.promo?.minOrderValue ?? 0.0;
    startDate = widget.promo?.startDate ?? DateTime.now();
    endDate =
        widget.promo?.endDate ?? DateTime.now().add(const Duration(days: 30));
    active = widget.promo?.active ?? true;
  }

  Future<void> _save() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final promo = Promo(
      id: widget.promo?.id ?? UniqueKey().toString(),
      name: name,
      description: description,
      code: code,
      type: type,
      items: widget.promo?.items ?? [],
      discount: discount,
      maxUses: maxUses,
      maxUsesType: maxUsesType,
      minOrderValue: minOrderValue,
      startDate: startDate,
      endDate: endDate,
      active: active,
      target: widget.promo?.target,
      timeRules: widget.promo?.timeRules,
    );

    if (widget.onSave != null) {
      await widget.onSave!(promo); // Safe to await: always Future
    } else {
      // Fallback: Dialog saves directly if no callback supplied (legacy usage)
      if (widget.promo != null) {
        await FirestoreService().updatePromo(franchiseId, promo);
      } else {
        await FirestoreService().addPromo(franchiseId, promo);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.promo == null ? 'Create Promo' : 'Edit Promo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => name = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (v) => description = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: code,
                decoration: const InputDecoration(labelText: 'Promo Code'),
                onSaved: (v) => code = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                onSaved: (v) => type = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: discount.toString(),
                decoration: const InputDecoration(labelText: 'Discount'),
                keyboardType: TextInputType.number,
                onSaved: (v) => discount = double.tryParse(v ?? '0') ?? 0,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: maxUses.toString(),
                decoration: const InputDecoration(labelText: 'Max Uses'),
                keyboardType: TextInputType.number,
                onSaved: (v) => maxUses = int.tryParse(v ?? '0') ?? 0,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: maxUsesType,
                decoration: const InputDecoration(labelText: 'Max Uses Type'),
                onSaved: (v) => maxUsesType = v ?? 'total',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                initialValue: minOrderValue.toString(),
                decoration: const InputDecoration(labelText: 'Min Order Value'),
                keyboardType: TextInputType.number,
                onSaved: (v) => minOrderValue = double.tryParse(v ?? '0') ?? 0,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SwitchListTile(
                value: active,
                title: const Text('Active'),
                onChanged: (v) => setState(() => active = v),
              ),
              ListTile(
                title: Text(
                    'Start Date: ${startDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
              ),
              ListTile(
                title: Text(
                    'End Date: ${endDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => endDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
