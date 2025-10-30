import 'package:flutter/material.dart';
import 'package:admin_portal/admin/menu/dynamic_menu_item_editor_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:provider/provider.dart';

class MenuItemEditorPanel extends StatefulWidget {
  final bool isOpen;
  final String? initialCategoryId;
  final VoidCallback onClose;
  final VoidCallback? onCategoryCleared;
  final ValueChanged<String>? onCategorySelected; // <-- Add this

  const MenuItemEditorPanel({
    Key? key,
    required this.isOpen,
    this.initialCategoryId,
    required this.onClose,
    this.onCategoryCleared,
    this.onCategorySelected, // <-- Add this
  }) : super(key: key);

  @override
  State<MenuItemEditorPanel> createState() => _MenuItemEditorPanelState();
}

class _MenuItemEditorPanelState extends State<MenuItemEditorPanel> {
  String? _categoryId;

  @override
  void didUpdateWidget(MenuItemEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _categoryId = widget.initialCategoryId;
      });
    }
    if (!widget.isOpen) {
      setState(() {
        _categoryId = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
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
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: theme.colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header with back button and close button
              Container(
                color: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    if (_categoryId != null)
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
                        tooltip: 'Back',
                        onPressed: () {
                          setState(() {
                            _categoryId = null; // Back to category picker
                          });
                          if (widget.onCategoryCleared != null) {
                            widget.onCategoryCleared!();
                          }
                        },
                      )
                    else
                      const SizedBox(width: 48), // maintain alignment

                    Text(
                      loc.addItem,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : colorScheme.onSurface,
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

              // Content area
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: DynamicMenuItemEditorScreen(
                      key: ValueKey(_categoryId),
                      franchiseId:
                          Provider.of<FranchiseProvider>(context, listen: false)
                              .franchiseId,
                      initialCategoryId: _categoryId,
                      onCategorySelected: (selectedCategory) {
                        setState(() {
                          _categoryId = selectedCategory;
                        });
                        widget.onCategorySelected?.call(selectedCategory);
                      },
                      onCancel: () {
                        if (_categoryId != null) {
                          setState(() {
                            _categoryId = null;
                          });
                          widget.onCategoryCleared?.call();
                        } else {
                          widget.onClose();
                        }
                      },
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
