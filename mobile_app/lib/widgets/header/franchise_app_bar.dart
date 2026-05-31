import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:shared_core/shared_core.dart' as shared;

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

/// A modular, franchise-ready AppBar widget.
/// Expandable: supports title, logo, subtitle, custom actions, colors, and more.
class FranchiseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle? titleStyle;
  final bool centerTitle;
  final bool showLogo;
  final String? logoAsset; // Local fallback asset
  final String? logoUrl;   // Remote logo URL (from FranchiseProvider / UiConfig)
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
    super.key,
    required this.title,
    this.titleStyle,
    this.centerTitle = true,
    this.showLogo = false,
    this.logoAsset,
    this.logoUrl,
    this.logoHeight = 40,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.showBottomDivider = false,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

    final bool hasRemoteLogo = showLogo && logoUrl != null && logoUrl!.isNotEmpty;
    final bool hasLocalLogo = showLogo && logoAsset != null && logoAsset!.isNotEmpty;
    final bool displayLogo = hasRemoteLogo || hasLocalLogo;

    final color = backgroundColor ?? UiConfig.primaryColor;

    Widget logoWidget;
    if (hasRemoteLogo) {
      logoWidget = NetworkImageWidget(
        imageUrl: logoUrl,
        fallbackAsset: logoAsset ?? shared.BrandingConfig.defaultPizzaIcon,
        width: logoHeight * 1.6,
        height: logoHeight,
        fit: BoxFit.contain,
      );
    } else if (hasLocalLogo) {
      logoWidget = Image.asset(
        logoAsset!,
        height: logoHeight,
        fit: BoxFit.contain,
        semanticLabel: title,
      );
    } else {
      logoWidget = const SizedBox.shrink();
    }

    final titleWidget = displayLogo
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              logoWidget,
              if (hasRemoteLogo || hasLocalLogo) const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: titleStyle ??
                      TextStyle(
                        fontSize: shared.DesignTokens.titleFontSize,
                        fontWeight: UiConfig.fontWeightBold,
                        fontFamily: shared.DesignTokens.fontFamily,
                        color: foregroundColor ?? UiConfig.foregroundColor,
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
                  fontSize: shared.DesignTokens.titleFontSize,
                  fontWeight: UiConfig.fontWeightBold,
                  fontFamily: shared.DesignTokens.fontFamily,
                  color: foregroundColor ?? UiConfig.foregroundColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    return AppBar(
      backgroundColor: color,
      elevation: elevation,
      centerTitle: displayLogo ? false : centerTitle,
      iconTheme: IconThemeData(
        color: foregroundColor ?? UiConfig.foregroundColor,
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
