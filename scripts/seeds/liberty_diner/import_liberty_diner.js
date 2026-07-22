/**
 * Liberty Diner Seed Import Script
 * 
 * Imports the mock non-pizzeria franchise (liberty_diner) into Firestore.
 * Matches the existing project schema patterns.
 *
 * Usage (from project root or this folder):
 *   node import_liberty_diner.js
 *
 * Prerequisites:
 *   - firebase-admin installed
 *   - GOOGLE_APPLICATION_CREDENTIALS or service account key configured
 *   - Or run with: FIREBASE_CONFIG=... node import_liberty_diner.js
 *
 * Safe to re-run (uses set with merge where appropriate).
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin (adjust path to your service account if needed)
if (!admin.apps.length) {
  try {
    // Prefer application default credentials or environment
    admin.initializeApp({
      // credential: admin.credential.cert(require('./serviceAccountKey.json')), // uncomment if using local key
    });
  } catch (e) {
    console.error('Firebase Admin init failed. Make sure credentials are configured.');
    console.error(e.message);
    process.exit(1);
  }
}

const db = admin.firestore();
const seedPath = path.join(__dirname, 'seed_data.json');
const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

async function importCollection(collectionPath, docs, options = {}) {
  const { merge = true } = options;
  const batchSize = 400;
  const entries = Object.entries(docs);
  let count = 0;

  for (let i = 0; i < entries.length; i += batchSize) {
    const batch = db.batch();
    const chunk = entries.slice(i, i + batchSize);

    for (const [id, data] of chunk) {
      const ref = db.doc(`${collectionPath}/${id}`);
      // Convert ISO date strings to Timestamps where appropriate
      const cleaned = convertTimestamps(data);
      batch.set(ref, cleaned, { merge });
      count++;
    }
    await batch.commit();
  }
  return count;
}

function convertTimestamps(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(convertTimestamps);

  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(value)) {
      result[key] = admin.firestore.Timestamp.fromDate(new Date(value));
    } else if (typeof value === 'object') {
      result[key] = convertTimestamps(value);
    } else {
      result[key] = value;
    }
  }
  return result;
}

async function run() {
  console.log('=== Liberty Diner Seed Import ===');
  console.log(`Franchise ID: ${seed.meta.franchiseId}`);
  console.log(`restaurantType: diner | Multi-location: yes\n`);

  try {
    // 1. Franchise document
    console.log('Importing franchise document...');
    await importCollection('franchises', seed.franchises);
    console.log('  ✓ franchises/liberty_diner');

    // 2. Franchise locations (top-level collection matching existing pattern)
    console.log('Importing franchise locations...');
    const locCount = await importCollection('franchise_locations', seed.franchise_locations);
    console.log(`  ✓ ${locCount} locations`);

    // 3. Categories (under franchise subcollection)
    console.log('Importing categories...');
    const catCount = await importCollection(
      'franchises/liberty_diner/categories',
      seed.categories.liberty_diner
    );
    console.log(`  ✓ ${catCount} categories`);

    // 4. Menu items (under franchise subcollection)
    console.log('Importing menu items...');
    const itemCount = await importCollection(
      'franchises/liberty_diner/menu_items',
      seed.menu_items.liberty_diner
    );
    console.log(`  ✓ ${itemCount} menu items`);

    // 5. Banners (top-level for now, tagged with franchiseId)
    console.log('Importing banners...');
    const bannerCount = await importCollection('banners', seed.banners);
    console.log(`  ✓ ${bannerCount} banners`);

    // 6. Franchise-scoped config
    console.log('Importing franchise config...');
    await importCollection(
      'franchises/liberty_diner/config',
      seed.config.liberty_diner
    );
    console.log('  ✓ config/features, ui_config, branding');

    // 7. Analytics summary placeholder
    console.log('Importing analytics summary...');
    await importCollection(
      'franchises/liberty_diner/analytics_summaries',
      seed.analytics_summaries.liberty_diner
    );
    console.log('  ✓ analytics_summaries/default_2026-07');

    console.log('\n=== Import complete ===');
    console.log('You can now switch to franchiseId "liberty_diner" in the app.');
    console.log('Locations: liberty_diner_main, liberty_diner_eastside');
    console.log('restaurantType: "diner"');
  } catch (err) {
    console.error('\nImport failed:', err);
    process.exit(1);
  }
}

run();
