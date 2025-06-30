import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/admin/menu/dynamic_menu_item_editor_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';

class MenuItemEditorPanel extends StatefulWidget {
  final bool isOpen;
  final String? initialCategoryId;
  final VoidCallback onClose;

  const MenuItemEditorPanel({
    Key? key,
    required this.isOpen,
    this.initialCategoryId,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MenuItemEditorPanel> createState() => _MenuItemEditorPanelState();
}

class _MenuItemEditorPanelState extends State<MenuItemEditorPanel> {
  String? _categoryId;
  int _reloadToken = 0; // Used to force reload form if needed

  @override
  void didUpdateWidget(MenuItemEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      _categoryId = widget.initialCategoryId;
      // To reload the form (optional, if schema is tied to category)
      _reloadToken++;
    }
    if (!widget.isOpen) {
      // Optionally clear state if closed
      _categoryId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header (fixed height, not full app bar)
              Container(
                color: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    Text(
                      loc.addItem,
                      style: TextStyle(
                        color: BrandingConfig.brandRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      tooltip: 'Close',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: DynamicMenuItemEditorScreen(
                      initialCategoryId: _categoryId,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
