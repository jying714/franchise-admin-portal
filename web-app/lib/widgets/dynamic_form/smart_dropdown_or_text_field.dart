import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartDropdownOrTextField extends StatefulWidget {
  final String label;
  final dynamic value;
  final String? optionsSource; // e.g., 'categories', 'ingredient_metadata'
  final String? hint;
  final bool requiredField;
  final ValueChanged<String?> onChanged;
  final String? fieldKey;

  const SmartDropdownOrTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.optionsSource,
    this.hint,
    this.requiredField = false,
    this.fieldKey,
  });

  @override
  State<SmartDropdownOrTextField> createState() =>
      _SmartDropdownOrTextFieldState();
}

class _SmartDropdownOrTextFieldState extends State<SmartDropdownOrTextField> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<String> _allOptions = [];
  List<String> _filteredOptions = [];
  bool _loading = false;
  bool _dropdownOpen = false;

  @override
  void initState() {
    super.initState();
    final initial = _normalizeValue(widget.value);
    _controller.text = initial;
    _controller.addListener(_onTextChanged);
    _loadOptions();
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  String _normalizeValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map && value.containsKey('en')) return value['en'].toString();
    return value.toString();
  }

  void _onTextChanged() {
    final input = _controller.text;
    widget.onChanged(input.trim().isEmpty ? null : input.trim());

    if (!_dropdownOpen || !mounted) return;

    setState(() {
      _filteredOptions = _allOptions
          .where((o) => o.toLowerCase().contains(input.toLowerCase()))
          .toList();
    });

    _updateOverlay();
  }

  Future<void> _loadOptions() async {
    if (widget.optionsSource == null || !mounted) return;

    setState(() => _loading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection(widget.optionsSource!)
          .get();

      final set = <String>{};
      for (var doc in snap.docs) {
        final data = doc.data();
        final candidate = widget.fieldKey == 'type'
            ? data['type']?.toString()
            : data['name']?.toString() ?? doc.id;

        if (candidate != null && candidate.trim().isNotEmpty) {
          set.add(candidate.trim());
        }
      }

      _allOptions = set.toList()..sort();
      _filteredOptions = List.from(_allOptions);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleDropdown() {
    if (_dropdownOpen) {
      _removeOverlay();
    } else {
      _filteredOptions = _allOptions
          .where(
              (o) => o.toLowerCase().contains(_controller.text.toLowerCase()))
          .toList();
      _showOverlay();
    }
  }

  void _selectOption(String option) {
    _controller.text = option;
    widget.onChanged(option);
    _removeOverlay();
  }

  void _showOverlay() {
    _overlayEntry = _buildOverlayEntry();
    if (!mounted) return;
    Overlay.of(context).insert(_overlayEntry!);
    _dropdownOpen = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _dropdownOpen = false;
  }

  void _updateOverlay() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = _filteredOptions[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(option),
                    onTap: () => _selectOption(option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            errorText: widget.requiredField && _controller.text.trim().isEmpty
                ? '${widget.label} is required'
                : null,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _dropdownOpen
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                    ),
                    onPressed: _toggleDropdown,
                  ),
          ),
          onTap: _removeOverlay,
          onFieldSubmitted: (_) => _removeOverlay(),
        ),
      ),
    );
  }
}


