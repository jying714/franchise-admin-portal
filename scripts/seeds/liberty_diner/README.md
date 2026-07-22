# Liberty Diner Mock Franchise Seed

**Purpose**: Non-pizzeria, multi-location mock franchise for testing multi-tenant behavior, `restaurantType: "diner"`, hybrid location UI, branding isolation, and config-driven dynamic UI.

## Contents

| File | Description |
|------|-------------|
| `seed_data.json` | Complete seed data matching project Firestore structure |
| `import_liberty_diner.js` | Node.js import script (firebase-admin) |
| `README.md` | This file |

## Franchise Summary

- **franchiseId**: `liberty_diner`
- **restaurantType**: `diner`
- **Locations**: 2 (Main Street + Eastside)
- **Categories**: Burgers, Sandwiches & Wraps, Sides, Drinks, Desserts, Breakfast All Day
- **Menu Items**: 13 (classic diner items with appropriate customizations)
- **Banners**: 2
- **Config**: Franchise-scoped features + ui_config + branding (pizzaCustomizationConfig deliberately null)
- **Branding**: Navy primary (`#1B4F72`) + gold secondary

## How to Import

1. Ensure you have `firebase-admin` available (or install it temporarily):
   ```bash
   npm install firebase-admin
   ```

2. Configure credentials (one of):
   - Set `GOOGLE_APPLICATION_CREDENTIALS` to your service account JSON
   - Or uncomment the `credential.cert(...)` line in the script and point to a key file

3. Run the import:
   ```bash
   node import_liberty_diner.js
   ```

The script is idempotent (uses merge) and can be re-run safely.

## After Import

- Switch franchise context to `liberty_diner` in the web admin or mobile app.
- Verify two locations appear in the hybrid location picker.
- Confirm categories and menu items load without pizza-specific UI.
- Check that branding colors and logo placeholder are applied.
- Confirm `pizzaCustomizationConfig` is absent/null so FeatureGate / dynamic UI skips pizza paths.

## Notes

- Image URLs are placeholders (`example.com`). Replace with real Storage URLs if desired.
- No real orders, feedback, or staff data are seeded (keeps the mock clean).
- Analytics summary is a zeroed placeholder.
- Aligns with `/docs/architecture/firestore-per-franchise-config.md` and `mobile_dynamic.md`.
