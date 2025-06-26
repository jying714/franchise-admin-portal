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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: widget.isOpen
          ? Column(
              key: ValueKey('editor-open-$_reloadToken'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: BrandingConfig.brandRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Row(
                    children: [
                      Text(
                        loc.addItem,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                // No Expanded here, just the widget:
                DynamicMenuItemEditorScreen(
                  initialCategoryId: _categoryId,
                ),
              ],
            )
          : Container(
              key: const ValueKey('editor-closed'),
              color: Colors.white,
              child: Center(
                child: Text(
                  loc.selectItemToEdit,
                  style: TextStyle(color: Colors.grey[500], fontSize: 18),
                ),
              ),
            ),
    );
  }
}
