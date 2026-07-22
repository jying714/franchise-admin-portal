/**
 * Liberty Diner Seed Import Script
 *
 * Uses the exact same firebase-admin loading pattern as
 * scripts/dump_full_firestore_schema.js (which is known to work).
 *
 * Usage (from project root or this folder):
 *   node import_liberty_diner.js
 *
 * Requires:
 *   web-app/serviceAccountKey.json
 *   web-app/node_modules/firebase-admin
 */

const path = require('path');
const fs = require('fs');

// ---------- Load firebase-admin exactly like the working dump script ----------
const firebaseAdminPath = path.join(__dirname, '..', '..', '..', 'web-app', 'node_modules', 'firebase-admin');
let admin;

try {
  admin = require(firebaseAdminPath);
} catch (err) {
  console.error('\n❌  Could not load firebase-admin from web-app/node_modules.');
  console.error('   Path tried:', firebaseAdminPath);
  console.error('   Error:', err.message);
  console.error('\n   Make sure you have run: cd web-app && npm install\n');
  process.exit(1);
}

if (!admin) {
  console.error('\n❌  firebase-admin require returned undefined.\n');
  process.exit(1);
}

// ---------- Service account (same location as dump script) ----------
const SERVICE_ACCOUNT_PATH = path.join(__dirname, '..', '..', '..', 'web-app', 'serviceAccountKey.json');

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('\n❌  serviceAccountKey.json not found at:');
  console.error('   ', SERVICE_ACCOUNT_PATH);
  console.error('\n   This is the same key used by your working dump script.\n');
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

// ---------- Initialize ----------
if (!admin.apps || !admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id || 'doughboyspizzeria-2b3d2'
  });
}

const db = admin.firestore();

// ---------- Seed data ----------
const seedPath = path.join(__dirname, 'seed_data.json');

if (!fs.existsSync(seedPath)) {
  console.error('\n❌  seed_data.json not found at:', seedPath, '\n');
  process.exit(1);
}

const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

// ---------- Helpers ----------
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

async function importCollection(collectionPath, docs) {
  const batchSize = 400;
  const entries = Object.entries(docs);
  let count = 0;

  for (let i = 0; i < entries.length; i += batchSize) {
    const batch = db.batch();
    const chunk = entries.slice(i, i + batchSize);

    for (const [id, data] of chunk) {
      const ref = db.doc(`${collectionPath}/${id}`);
      const cleaned = convertTimestamps(data);
      batch.set(ref, cleaned, { merge: true });
      count++;
    }
    await batch.commit();
  }
  return count;
}

// ---------- Main ----------
async function run() {
  console.log('\n=== Liberty Diner Seed Import ===');
  console.log(`Franchise ID  : ${seed.meta.franchiseId}`);
  console.log(`restaurantType: diner | Multi-location: yes\n`);

  try {
    console.log('Importing franchise document...');
    await importCollection('franchises', seed.franchises);
    console.log('  ✓ franchises/liberty_diner');

    console.log('Importing franchise locations...');
    const locCount = await importCollection('franchise_locations', seed.franchise_locations);
    console.log(`  ✓ ${locCount} locations`);

    console.log('Importing categories...');
    const catCount = await importCollection(
      'franchises/liberty_diner/categories',
      seed.categories.liberty_diner
    );
    console.log(`  ✓ ${catCount} categories`);

    console.log('Importing menu items...');
    const itemCount = await importCollection(
      'franchises/liberty_diner/menu_items',
      seed.menu_items.liberty_diner
    );
    console.log(`  ✓ ${itemCount} menu items`);

    console.log('Importing banners...');
    const bannerCount = await importCollection('banners', seed.banners);
    console.log(`  ✓ ${bannerCount} banners`);

    console.log('Importing franchise config...');
    await importCollection(
      'franchises/liberty_diner/config',
      seed.config.liberty_diner
    );
    console.log('  ✓ config/features, ui_config, branding');

    console.log('Importing analytics summary...');
    await importCollection(
      'franchises/liberty_diner/analytics_summaries',
      seed.analytics_summaries.liberty_diner
    );
    console.log('  ✓ analytics_summaries/default_2026-07');

    console.log('\n=== Import complete ===');
    console.log('You can now switch to franchiseId "liberty_diner" in the app.');
    console.log('Locations: liberty_diner_main , liberty_diner_eastside');
    console.log('restaurantType: "diner"\n');
  } catch (err) {
    console.error('\n❌  Import failed:');
    console.error(err);
    process.exit(1);
  }
}

run();
