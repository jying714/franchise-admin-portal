/**
 * Full Firestore Schema Dumper
 * 
 * Usage:
 *   cd web-app
 *   node ../scripts/dump_full_firestore_schema.js
 * 
 * Requirements:
 *   - firebase-admin in web-app/node_modules (already present)
 *   - web-app/serviceAccountKey.json (service account with Firestore read access)
 * 
 * Output: scripts/full_firestore_schema_YYYY-MM-DD_HH-mm-ss.txt
 * 
 * Samples up to 3 documents per collection + recurses into subcollections.
 * Safe for production (limited reads).
 */

const path = require('path');
const fs = require('fs');

// Load firebase-admin from web-app's node_modules (avoids path issues)
const firebaseAdminPath = path.join(__dirname, '..', 'web-app', 'node_modules', 'firebase-admin');
const admin = require(firebaseAdminPath);

// === CONFIG ===
const SERVICE_ACCOUNT_PATH = path.join(__dirname, '..', 'web-app', 'serviceAccountKey.json');
const OUTPUT_DIR = path.join(__dirname);
const MAX_DOCS_PER_COLLECTION = 3;

// === INIT ===
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('ERROR: serviceAccountKey.json not found at', SERVICE_ACCOUNT_PATH);
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id || 'doughboyspizzeria-2b3d2'
});

const db = admin.firestore();

// === HELPERS ===

function getType(value) {
  if (value === null) return 'null';
  if (value === undefined) return 'undefined';
  if (value instanceof admin.firestore.Timestamp) return 'Timestamp';
  if (value instanceof admin.firestore.DocumentReference) return `DocumentReference -> ${value.path}`;
  if (value instanceof admin.firestore.GeoPoint) return `GeoPoint(${value.latitude}, ${value.longitude})`;
  if (Array.isArray(value)) return `array[${value.length}]`;
  if (typeof value === 'object') return 'map';
  return typeof value;
}

function sanitizeValue(value, depth = 0) {
  if (depth > 2) return '[nested]';
  if (value === null || value === undefined) return value;
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate().toISOString();
  }
  if (value instanceof admin.firestore.DocumentReference) {
    return `ref:${value.path}`;
  }
  if (value instanceof admin.firestore.GeoPoint) {
    return { _type: 'GeoPoint', lat: value.latitude, lng: value.longitude };
  }
  if (Array.isArray(value)) {
    return value.slice(0, 3).map(v => sanitizeValue(v, depth + 1)); // limit array samples
  }
  if (typeof value === 'object') {
    const out = {};
    let count = 0;
    for (const [k, v] of Object.entries(value)) {
      if (count++ > 12) { out['...'] = '[truncated]'; break; }
      out[k] = sanitizeValue(v, depth + 1);
    }
    return out;
  }
  return value;
}

async function getSampleDocs(collectionRef) {
  try {
    const snapshot = await collectionRef.limit(MAX_DOCS_PER_COLLECTION).get();
    const docs = [];
    snapshot.forEach(doc => {
      const data = doc.data() || {};
      const sanitized = {};
      for (const [key, val] of Object.entries(data)) {
        sanitized[key] = {
          type: getType(val),
          sample: sanitizeValue(val)
        };
      }
      docs.push({
        id: doc.id,
        fields: sanitized
      });
    });
    return docs;
  } catch (err) {
    return [{ error: err.message }];
  }
}

async function exploreCollection(collectionPath, depth = 0, visited = new Set()) {
  const indent = '  '.repeat(depth);
  const lines = [];

  if (visited.has(collectionPath)) return lines;
  visited.add(collectionPath);

  const collectionRef = db.collection(collectionPath);

  // Get collection metadata + samples
  let docCount = 0;
  try {
    // Note: count() is expensive on huge collections; we just sample
    const samples = await getSampleDocs(collectionRef);
    docCount = samples.length;

    lines.push(`${indent}Collection: ${collectionPath}`);
    lines.push(`${indent}  Sampled documents: ${docCount} (max ${MAX_DOCS_PER_COLLECTION})`);

    if (samples.length === 0) {
      lines.push(`${indent}  (empty or no permission)`);
    } else {
      samples.forEach((doc, idx) => {
        lines.push(`${indent}  --- Doc ${idx + 1} (id: ${doc.id}) ---`);
        if (doc.error) {
          lines.push(`${indent}    ERROR: ${doc.error}`);
        } else {
          for (const [field, info] of Object.entries(doc.fields)) {
            const sampleStr = typeof info.sample === 'object' 
              ? JSON.stringify(info.sample, null, 0).slice(0, 180)
              : String(info.sample).slice(0, 120);
            lines.push(`${indent}    • ${field}: ${info.type}   = ${sampleStr}`);
          }
        }
      });
    }
  } catch (err) {
    lines.push(`${indent}Collection: ${collectionPath}`);
    lines.push(`${indent}  ERROR accessing collection: ${err.message}`);
  }

  // Discover subcollections for the sampled documents
  try {
    const snapshot = await collectionRef.limit(2).get(); // small number for subcollection discovery
    for (const doc of snapshot.docs) {
      const subcollections = await doc.ref.listCollections();
      for (const sub of subcollections) {
        const subPath = `${collectionPath}/${doc.id}/${sub.id}`;
        lines.push(...await exploreCollection(subPath, depth + 1, visited));
      }
    }
  } catch (e) {
    // ignore subcollection discovery errors
  }

  return lines;
}

async function dumpFullSchema() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputFile = path.join(OUTPUT_DIR, `full_firestore_schema_${timestamp}.txt`);

  console.log('🚀 Starting full Firestore schema dump for project: doughboyspizzeria-2b3d2');
  console.log('   Sampling max 3 documents per collection + recursing subcollections...\n');

  const allLines = [
    '================================================================================',
    'DOUGHBOYS PIZZERIA — COMPLETE FIRESTORE SCHEMA DUMP',
    `Generated: ${new Date().toISOString()}`,
    'Project: doughboyspizzeria-2b3d2',
    `Method: firebase-admin (service account) + recursive collection walk`,
    `Sample limit: ${MAX_DOCS_PER_COLLECTION} documents per collection`,
    '================================================================================',
    '',
    'NOTE: This is a live snapshot. Structure is dominated by franchises/{franchiseId}/ subcollections.',
    ''
  ];

  // Start from known important root collections + full discovery
  const rootCollectionsToExplore = [
    'alerts',
    'audit_logs',
    'banners',
    'categories',
    'config',
    'error_logs',
    'feedback',
    'franchise_subscriptions',
    'franchisee_invitations',
    'franchises',           // CRITICAL ROOT
    'integrations',
    'invoices',
    'menu_items',
    'onboarding_progress',
    'orders',
    'payouts',
    'platform_features',
    'platform_invoices',
    'platform_payments',
    'platform_plans',
    'promotions',
    'restaurant_types',
    'support_chats',
    'support_requests',
    'tax_reports',
    'users',                 // CRITICAL ROOT (has subcollections)
    'onboarding_templates'
  ];

  const visited = new Set();

  for (const coll of rootCollectionsToExplore) {
    console.log(`Exploring: ${coll} ...`);
    const lines = await exploreCollection(coll, 0, visited);
    allLines.push(...lines);
    allLines.push('');
  }

  // Final note
  allLines.push('');
  allLines.push('================================================================================');
  allLines.push('END OF SCHEMA DUMP');
  allLines.push(`Total collections explored (including subcollections): ${visited.size}`);
  allLines.push('================================================================================');

  fs.writeFileSync(outputFile, allLines.join('\n'), 'utf8');

  console.log(`\n✅ Complete schema written to:\n   ${outputFile}`);
  console.log(`   Collections/subcollections visited: ${visited.size}`);
}

// Run
dumpFullSchema().catch(err => {
  console.error('FATAL ERROR during schema dump:', err);
  process.exit(1);
});