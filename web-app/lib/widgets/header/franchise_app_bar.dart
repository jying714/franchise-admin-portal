import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// A modular, franchise-ready AppBar widget.
/// Expandable: supports title, logo, subtitle, custom actions, colors, and more.
class FranchiseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle? titleStyle;
  final bool centerTitle;
  final bool showLogo;
  final String? logoAsset;
  final double logoHeight;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showBottomDivider;
  final PreferredSizeWidget? bottom;

  /// For further expansion: add subtitle, back button logic, etc.
  const FranchiseAppBar({
    Key? key,
    required this.title,
    this.titleStyle,
    this.centerTitle = true,
    this.showLogo = false,
    this.logoAsset,
    this.logoHeight = 40,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showBottomDivider = false,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool displayLogo =
        showLogo && logoAsset != null && logoAsset!.isNotEmpty;

    final Color appBarBg = backgroundColor ??
        theme.appBarTheme.backgroundColor ??
        colorScheme.primary;
    final Color appBarFg = foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        colorScheme.onPrimary;
    final double appBarElevation =
        elevation ?? theme.appBarTheme.elevation ?? 0;

    final titleWidget = displayLogo
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                logoAsset!,
                height: logoHeight,
                fit: BoxFit.contain,
                semanticLabel: title,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: titleStyle ??
                      TextStyle(
                        fontSize: DesignTokens.titleFontSize,
                        fontWeight: DesignTokens.titleFontWeight,
                        fontFamily: DesignTokens.fontFamily,
                        color: appBarFg,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        : Text(
            title,
            style: titleStyle ??
                TextStyle(
                  fontSize: DesignTokens.titleFontSize,
                  fontWeight: DesignTokens.titleFontWeight,
                  fontFamily: DesignTokens.fontFamily,
                  color: appBarFg,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    // Divider: Use dividerColor from theme
    final dividerColor = Theme.of(context).dividerColor;

    return AppBar(
      backgroundColor: appBarBg,
      elevation: appBarElevation,
      centerTitle: displayLogo ? false : centerTitle,
      iconTheme: IconThemeData(
        color: appBarFg,
      ),
      leading: leading,
      title: titleWidget,
      actions: actions,
      bottom: showBottomDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: dividerColor,
                height: 1.0,
              ),
            )
          : bottom,
    );
  }
}


