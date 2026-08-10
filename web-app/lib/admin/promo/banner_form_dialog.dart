import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/services/firebase_storage_service_impl.dart';

/// User-facing intent for banner tap (maps to Banner.action.type).
enum _BannerTapIntent {
  promoteDeal, // promo
  openCategory, // linkCategory
  openItem, // linkItem
  openUrl, // url
  none, // none
}

class BannerFormDialog extends StatefulWidget {
  final shared.Banner? banner;
  final Future<void> Function(shared.Banner banner) onSave;

  const BannerFormDialog({
    super.key,
    this.banner,
    required this.onSave,
  });

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _imageUrl;
  late final TextEditingController _ctaText;
  late final TextEditingController _sortOrder;
  late final TextEditingController _urlController;

  late _BannerTapIntent _intent;
  String? _selectedPromoCode;
  String? _selectedCategoryId;
  String? _selectedMenuItemId;

  late DateTime _startDate;
  late DateTime _endDate;
  late bool _active;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  List<shared.Promo> _promos = const [];
  List<shared.Category> _categories = const [];
  List<shared.MenuItem> _menuItems = const [];
  bool _catalogLoading = true;
  String? _catalogError;

  StreamSubscription? _promoSub;
  StreamSubscription? _catSub;
  StreamSubscription? _itemSub;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _title = TextEditingController(text: b?.title ?? '');
    _subtitle = TextEditingController(text: b?.subtitle ?? '');
    _imageUrl = TextEditingController(text: b?.image ?? '');
    _ctaText = TextEditingController(text: b?.action.ctaText ?? '');
    _sortOrder = TextEditingController(text: (b?.sortOrder ?? 0).toString());
    _urlController = TextEditingController();

    _intent = _intentFromAction(b?.action);
    final actionVal = b?.action.value?.trim();
    switch (_intent) {
      case _BannerTapIntent.promoteDeal:
        _selectedPromoCode = actionVal?.toUpperCase();
        break;
      case _BannerTapIntent.openCategory:
        _selectedCategoryId = actionVal;
        break;
      case _BannerTapIntent.openItem:
        _selectedMenuItemId = actionVal;
        break;
      case _BannerTapIntent.openUrl:
        _urlController.text = actionVal ?? '';
        break;
      case _BannerTapIntent.none:
        break;
    }

    _startDate = b?.startDate ?? DateTime.now();
    _endDate = b?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _active = b?.active ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) => _bindCatalog());
  }

  _BannerTapIntent _intentFromAction(shared.Action? action) {
    switch ((action?.type ?? 'none').trim()) {
      case 'promo':
        return _BannerTapIntent.promoteDeal;
      case 'linkCategory':
        return _BannerTapIntent.openCategory;
      case 'linkItem':
        return _BannerTapIntent.openItem;
      case 'url':
        return _BannerTapIntent.openUrl;
      default:
        return _BannerTapIntent.none;
    }
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
        _catalogError = 'Select a franchise first';
      });
      return;
    }

    _promoSub?.cancel();
    _catSub?.cancel();
    _itemSub?.cancel();

    _promoSub = fs.getPromos(franchiseId).listen(
      (list) {
        if (!mounted) return;
        final live = list.where((p) => p.isLiveAt(DateTime.now())).toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        // Keep selected code even if expired so edits still show.
        setState(() {
          _promos = list.toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          _catalogLoading = false;
          if (_selectedPromoCode != null &&
              !_promos.any(
                (p) => p.code.toUpperCase() == _selectedPromoCode,
              ) &&
              live.isNotEmpty) {
            // leave selection; dropdown allows value not in list via null check
          }
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _catalogError = 'Could not load deals: $e';
          _catalogLoading = false;
        });
      },
    );

    _catSub = fs.getCategories(franchiseId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _categories = list.where((c) => c.isActive).toList()
            ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
        });
      },
    );

    _itemSub = fs.getMenuItems(franchiseId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _menuItems = list.where((m) => !m.archived).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
        });
      },
    );
  }

  @override
  void dispose() {
    _promoSub?.cancel();
    _catSub?.cancel();
    _itemSub?.cancel();
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    _ctaText.dispose();
    _sortOrder.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _promoLabel(shared.Promo p) {
    final code = p.code.isNotEmpty ? p.code : '(no code)';
    final name = p.name.isNotEmpty ? p.name : 'Untitled';
    final kind = shared.PromoType.label(p.type);
    return '$code — $name ($kind)';
  }

  String _categoryLabel(shared.Category c) {
    final n = c.displayName?.trim().isNotEmpty == true
        ? c.displayName!.trim()
        : c.name;
    return n.isNotEmpty ? n : c.id;
  }

  Future<void> _pickAndUploadImage() async {
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      setState(() => _error = 'Select a franchise first');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'Could not read image bytes');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final storage = FirebaseStorageServiceImpl();
      final url = await storage.uploadFranchiseImageBytes(
        bytes: bytes,
        fileName: file.name,
        franchiseId: franchiseId,
        folder: 'banners',
      );
      if (!mounted) return;
      setState(() {
        _imageUrl.text = url;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'Upload failed: $e';
      });
    }
  }

  shared.Action _buildAction() {
    switch (_intent) {
      case _BannerTapIntent.promoteDeal:
        final code = (_selectedPromoCode ?? '').trim().toUpperCase();
        return shared.Action(
          type: 'promo',
          value: code.isEmpty ? null : code,
          ctaText: _ctaText.text.trim().isEmpty ? null : _ctaText.text.trim(),
        );
      case _BannerTapIntent.openCategory:
        return shared.Action(
          type: 'linkCategory',
          value: _selectedCategoryId,
          ctaText: _ctaText.text.trim().isEmpty ? null : _ctaText.text.trim(),
        );
      case _BannerTapIntent.openItem:
        return shared.Action(
          type: 'linkItem',
          value: _selectedMenuItemId,
          ctaText: _ctaText.text.trim().isEmpty ? null : _ctaText.text.trim(),
        );
      case _BannerTapIntent.openUrl:
        return shared.Action(
          type: 'url',
          value: _urlController.text.trim().isEmpty
              ? null
              : _urlController.text.trim(),
          ctaText: _ctaText.text.trim().isEmpty ? null : _ctaText.text.trim(),
        );
      case _BannerTapIntent.none:
        return shared.Action(
          type: 'none',
          ctaText: _ctaText.text.trim().isEmpty ? null : _ctaText.text.trim(),
        );
    }
  }

  String? _validateIntent() {
    switch (_intent) {
      case _BannerTapIntent.promoteDeal:
        if (_selectedPromoCode == null || _selectedPromoCode!.isEmpty) {
          return 'Choose a deal to promote';
        }
        return null;
      case _BannerTapIntent.openCategory:
        if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
          return 'Choose a category';
        }
        return null;
      case _BannerTapIntent.openItem:
        if (_selectedMenuItemId == null || _selectedMenuItemId!.isEmpty) {
          return 'Choose a menu item';
        }
        return null;
      case _BannerTapIntent.openUrl:
        final u = _urlController.text.trim();
        if (u.isEmpty) return 'Enter a URL';
        if (!(u.startsWith('http://') || u.startsWith('https://'))) {
          return 'URL must start with http:// or https://';
        }
        return null;
      case _BannerTapIntent.none:
        return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final intentError = _validateIntent();
    if (intentError != null) {
      setState(() => _error = intentError);
      return;
    }
    if (_active &&
        DateTime(_endDate.year, _endDate.month, _endDate.day).isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )) {
      setState(() => _error = 'Active banners need an end date today or later');
      return;
    }
    final image = _imageUrl.text.trim();
    if (image.isEmpty) {
      setState(() => _error = 'Upload or paste a banner image');
      return;
    }

    final banner = shared.Banner(
      id: widget.banner?.id ?? '',
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
      image: image,
      action: _buildAction(),
      startDate: _startDate,
      endDate: _endDate,
      active: _active,
      sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(banner);
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

  Widget _intentTile({
    required _BannerTapIntent value,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<_BannerTapIntent>(
      value: value,
      groupValue: _intent,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) {
        if (v != null) setState(() => _intent = v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.banner != null;
    final promoCodes = _promos
        .map((p) => p.code.trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Ensure current selection appears in dropdown.
    if (_selectedPromoCode != null &&
        _selectedPromoCode!.isNotEmpty &&
        !promoCodes.contains(_selectedPromoCode)) {
      promoCodes.insert(0, _selectedPromoCode!);
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit banner' : 'Add banner'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Banners are the images on the menu. '
                  'Link one to a deal so tapping it promotes that code.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (_catalogLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
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
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subtitle,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Image',
                    helperText: 'Upload a photo or paste an image URL',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUploadImage,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file, size: 18),
                  label: Text(_uploading ? 'Uploading…' : 'Upload image'),
                ),
                if (_imageUrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrl.text.trim(),
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text(
                        'Preview unavailable',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'When customer taps',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                _intentTile(
                  value: _BannerTapIntent.promoteDeal,
                  title: 'Promote a deal',
                  subtitle:
                      'Recommended. Applies this deal’s code at checkout when the cart qualifies.',
                ),
                if (_intent == _BannerTapIntent.promoteDeal) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: DropdownButtonFormField<String>(
                      value: promoCodes.contains(_selectedPromoCode)
                          ? _selectedPromoCode
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Deal',
                        border: OutlineInputBorder(),
                        isDense: true,
                        helperText:
                            'Create deals under the Codes tab if the list is empty.',
                      ),
                      items: _promos
                          .where((p) => p.code.trim().isNotEmpty)
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.code.trim().toUpperCase(),
                              child: Text(
                                _promoLabel(p),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPromoCode = v),
                    ),
                  ),
                ],
                _intentTile(
                  value: _BannerTapIntent.openCategory,
                  title: 'Open a menu category',
                  subtitle: 'Jumps to that category on the menu.',
                ),
                if (_intent == _BannerTapIntent.openCategory) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: DropdownButtonFormField<String>(
                      value: _categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(_categoryLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                ],
                _intentTile(
                  value: _BannerTapIntent.openItem,
                  title: 'Open a menu item',
                  subtitle:
                      'Jumps toward that item (when navigation supports it).',
                ),
                if (_intent == _BannerTapIntent.openItem) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: DropdownButtonFormField<String>(
                      value: _menuItems.any((m) => m.id == _selectedMenuItemId)
                          ? _selectedMenuItemId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Menu item',
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
                      onChanged: (v) => setState(() => _selectedMenuItemId = v),
                    ),
                  ),
                ],
                _intentTile(
                  value: _BannerTapIntent.openUrl,
                  title: 'Open a web link',
                  subtitle: 'Opens an external URL.',
                ),
                if (_intent == _BannerTapIntent.openUrl) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
                _intentTile(
                  value: _BannerTapIntent.none,
                  title: 'Image only',
                  subtitle: 'No navigation when tapped.',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ctaText,
                  decoration: const InputDecoration(
                    labelText: 'Button label on banner (optional)',
                    helperText: 'e.g. Order now, Get deal',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortOrder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort order (lower shows first)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
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
          onPressed: _saving || _uploading ? null : _submit,
          child: Text(_saving ? 'Saving…' : (isEdit ? 'Save' : 'Add')),
        ),
      ],
    );
  }
}
