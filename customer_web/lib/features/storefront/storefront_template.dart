/// Franchise storefront layout id from config/storefront.templateId.
enum StorefrontTemplateId {
  /// Current plain MVP landing (default).
  defaultLayout,

  /// Pizzon-inspired Modern template (this epic).
  modern,
}

StorefrontTemplateId parseStorefrontTemplateId(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'modern':
      return StorefrontTemplateId.modern;
    default:
      return StorefrontTemplateId.defaultLayout;
  }
}
