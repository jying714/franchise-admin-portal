// File: lib/core/constants/feature_metadata.dart

import 'package:flutter/material.dart';

class FeatureDefinition {
  final String key;
  final String label;
  final String description;
  final String group;
  final String? requiredPlanTier;
  final bool isBeta;
  final bool isDeprecated;
  final bool visibleInUI;
  final IconData icon;

  const FeatureDefinition({
    required this.key,
    required this.label,
    required this.description,
    required this.group,
    this.requiredPlanTier,
    this.isBeta = false,
    this.isDeprecated = false,
    this.visibleInUI = true,
    required this.icon,
  });
}

final List<FeatureDefinition> kFeatureMetadataList = [
  // 🌐 GLOBAL
  FeatureDefinition(
    key: 'language_support',
    label: 'Multilingual Support',
    description: 'Allow customers and staff to switch app language.',
    group: 'global',
    icon: Icons.language,
  ),
  FeatureDefinition(
    key: 'branding_customization',
    label: 'Custom Branding',
    description: 'Apply franchise-specific logos, colors, and assets.',
    group: 'global',
    icon: Icons.palette,
  ),

  // 🛒 MENU / ORDERING
  FeatureDefinition(
    key: 'menu_item_customization',
    label: 'Menu Item Customization',
    description: 'Enable ingredient-based customization flows for items.',
    group: 'menu',
    icon: Icons.restaurant_menu,
  ),
  FeatureDefinition(
    key: 'combo_meals',
    label: 'Combo Meals / Bundles',
    description: 'Group items together into preset or build-your-own combos.',
    group: 'menu',
    icon: Icons.fastfood,
  ),
  FeatureDefinition(
    key: 'nutritional_info',
    label: 'Nutrition & Allergen Info',
    description: 'Display calorie counts and allergen warnings per item.',
    group: 'menu',
    icon: Icons.info_outline,
  ),

  // 📦 OPERATIONS
  FeatureDefinition(
    key: 'inventory',
    label: 'Inventory Management',
    description: 'Track ingredient stock, mark items out of stock.',
    group: 'operations',
    icon: Icons.warehouse,
  ),
  FeatureDefinition(
    key: 'staff_access',
    label: 'Staff Access Controls',
    description: 'Invite and manage team roles (manager, staff, etc).',
    group: 'operations',
    icon: Icons.supervisor_account,
  ),
  FeatureDefinition(
    key: 'order_tracking',
    label: 'Order Tracking Dashboard',
    description: 'Live overview of current and past orders.',
    group: 'operations',
    icon: Icons.track_changes,
  ),

  // 💬 SUPPORT
  FeatureDefinition(
    key: 'chat_support',
    label: 'Live Chat Support',
    description: 'Enable real-time support chat from the app or admin panel.',
    group: 'support',
    icon: Icons.chat,
  ),
  FeatureDefinition(
    key: 'feedback',
    label: 'Customer Feedback Collection',
    description: 'Capture reviews and satisfaction after orders.',
    group: 'support',
    icon: Icons.feedback,
  ),

  // 🎁 PROMO + ENGAGEMENT
  FeatureDefinition(
    key: 'promo_banners',
    label: 'Promotional Banners',
    description: 'Display limited-time deals or app banners.',
    group: 'customer_engagement',
    icon: Icons.campaign,
  ),
  FeatureDefinition(
    key: 'loyalty',
    label: 'Loyalty Program',
    description: 'Track and reward frequent customer visits.',
    group: 'customer_engagement',
    icon: Icons.card_giftcard,
  ),
  FeatureDefinition(
    key: 'discount_codes',
    label: 'Promo / Discount Codes',
    description: 'Allow customers to redeem codes at checkout.',
    group: 'customer_engagement',
    icon: Icons.discount,
  ),

  // 🧠 AI & AUTOMATION (future)
  FeatureDefinition(
    key: 'ai_menu_builder',
    label: 'AI Menu Generator',
    description: 'Use AI to auto-generate menus or combos.',
    group: 'future',
    icon: Icons.auto_awesome,
    isBeta: true,
    visibleInUI: false,
  ),
  FeatureDefinition(
    key: 'llm_chat_orders',
    label: 'AI Chat Ordering',
    description: 'Let users place orders through natural language chat.',
    group: 'future',
    icon: Icons.smart_toy,
    isBeta: true,
    visibleInUI: false,
  ),
];
