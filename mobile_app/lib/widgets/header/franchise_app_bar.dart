import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';

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
  final double elevation;
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
    this.elevation = 0,
    this.showBottomDivider = false,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final bool displayLogo =
        showLogo && logoAsset != null && logoAsset!.isNotEmpty;
    final color = backgroundColor ?? DesignTokens.primaryColor;
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
                        color: foregroundColor ?? DesignTokens.foregroundColor,
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
                  color: foregroundColor ?? DesignTokens.foregroundColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    return AppBar(
      backgroundColor: color,
      elevation: elevation,
      centerTitle: displayLogo ? false : centerTitle, // PATCH HERE
      iconTheme: IconThemeData(
        color: foregroundColor ?? DesignTokens.foregroundColor,
      ),
      leading: leading,
      title: titleWidget,
      actions: actions,
      bottom: showBottomDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Colors.grey.shade300,
                height: 1.0,
              ),
            )
          : bottom,
    );
  }
}
