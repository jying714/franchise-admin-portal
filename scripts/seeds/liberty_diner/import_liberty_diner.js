/**
 * Liberty Diner Seed Import Script (robust version)
 *
 * Imports the mock non-pizzeria franchise (liberty_diner) into Firestore.
 *
 * Usage (from this folder or project root):
 *   node import_liberty_diner.js
 *
 * Credentials (pick one):
 *   1. Place serviceAccountKey.json in this folder or project root
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable
 *   3. Use Application Default Credentials
 */

const fs = require('fs');
const path = require('path');

// ---------- Robust require of firebase-admin ----------
let admin;
try {
  admin = require('firebase-admin');
} catch (err) {
  console.error('\n❌  firebase-admin is not installed or cannot be required.');
  console.error('   Run this from the project root:');
  console.error('   npm install firebase-admin');
  console.error('\n   Then try again.\n');
  process.exit(1);
}

if (!admin || !admin.apps) {
  console.error('\n❌  firebase-admin loaded but is in an unexpected state.');
  console.error('   Try deleting node_modules and package-lock.json, then reinstall.');
  process.exit(1);
}

// ---------- Find service account key ----------
function findServiceAccountKey() {
  const candidates = [
    path.join(__dirname, 'serviceAccountKey.json'),
    path.join(__dirname, '..', '..', '..', 'serviceAccountKey.json'), // project root
    path.join(process.cwd(), 'serviceAccountKey.json'),
  ];

  for (const p of candidates) {
    if (fs.existsSync(p)) {
      console.log(`Using service account key: ${p}`);
      return require(p);
    }
  }
  return null;
}

// ---------- Initialize Firebase Admin ----------
if (!admin.apps.length) {
  try {
    const serviceAccount = findServiceAccountKey();

    if (serviceAccount) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log(`Using GOOGLE_APPLICATION_CREDENTIALS: ${process.env.GOOGLE_APPLICATION_CREDENTIALS}`);
      admin.initializeApp();
    } else {
      // Last resort – Application Default Credentials
      console.log('No serviceAccountKey.json found. Trying Application Default Credentials...');
      admin.initializeApp();
    }
  } catch (e) {
    console.error('\n❌  Failed to initialize Firebase Admin.');
    console.error('   Error:', e.message);
    console.error('\n   Solutions:');
    console.error('   1. Place a serviceAccountKey.json in this folder (scripts/seeds/liberty_diner/)');
    console.error('   2. Or set the environment variable:');
    console.error('      $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\serviceAccountKey.json"');
    console.error('   3. Then run the script again.\n');
    process.exit(1);
  }
}

const db = admin.firestore();
const seedPath = path.join(__dirname, 'seed_data.json');

if (!fs.existsSync(seedPath)) {
  console.error(`\n❌  seed_data.json not found at: ${seedPath}\n`);
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
      const cleaned = convertTimestamps(data);
      batch.set(ref, cleaned, { merge });
      count++;
    }
    await batch.commit();
  }
  return count;
}

// ---------- Main ----------
async function run() {
  console.log('\n=== Liberty Diner Seed Import ===');
  console.log(`Franchise ID : ${seed.meta.franchiseId}`);
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
