/**
 * Full Firestore Schema Dumper - COMPLETE DOCUMENTS
 * 
 * Usage:
 *   cd web-app
 *   node ..\scripts\dump_full_firestore_schema.js
 * 
 * Output: scripts/full_firestore_schema_YYYY-MM-DD_HH-mm-ss.txt
 */

const path = require('path');
const fs = require('fs');

// Load firebase-admin
const firebaseAdminPath = path.join(__dirname, '..', 'web-app', 'node_modules', 'firebase-admin');
const admin = require(firebaseAdminPath);

// === CONFIG ===
const SERVICE_ACCOUNT_PATH = path.join(__dirname, '..', 'web-app', 'serviceAccountKey.json');
const OUTPUT_DIR = path.join(__dirname);  // scripts folder in project root
const MAX_DOCS_LIMITED = 3;  // for audit/error logs only

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
  if (typeof value === 'object' && value !== null) return 'map';
  return typeof value;
}

function sanitizeValue(value, depth = 0) {
  if (depth > 3) return '[deeply nested]';
  if (value === null || value === undefined) return value;
  if (value instanceof admin.firestore.Timestamp) return value.toDate().toISOString();
  if (value instanceof admin.firestore.DocumentReference) return `ref:${value.path}`;
  if (value instanceof admin.firestore.GeoPoint) return { _type: 'GeoPoint', lat: value.latitude, lng: value.longitude };
  if (Array.isArray(value)) return value.map(v => sanitizeValue(v, depth + 1));
  if (typeof value === 'object' && value !== null) {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = sanitizeValue(v, depth + 1);
    }
    return out;
  }
  return value;
}

async function getFullDocs(collectionRef, limit = null) {
  try {
    let query = collectionRef;
    if (limit) query = query.limit(limit);
    const snapshot = await query.get();
    const docs = [];
    snapshot.forEach(doc => {
      const data = doc.data() || {};
      const sanitized = {};
      for (const [key, val] of Object.entries(data)) {
        sanitized[key] = {
          type: getType(val),
          value: sanitizeValue(val)
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
  const isLimitedCollection = ['audit_logs', 'error_logs', 'public_error_logs'].some(c => 
    collectionPath === c || collectionPath.startsWith(c + '/')
  );

  const limit = isLimitedCollection ? MAX_DOCS_LIMITED : null;

  lines.push(`${indent}Collection: ${collectionPath}`);
  lines.push(`${indent}  Full documents: ${limit ? limit + ' (limited)' : 'ALL'}`);

  try {
    const docs = await getFullDocs(collectionRef, limit);
    if (docs.length === 0) {
      lines.push(`${indent}  (empty)`);
    } else {
      docs.forEach((doc, idx) => {
        lines.push(`${indent}  --- Doc ${idx + 1} (id: ${doc.id}) ---`);
        if (doc.error) {
          lines.push(`${indent}    ERROR: ${doc.error}`);
        } else {
          for (const [field, info] of Object.entries(doc.fields)) {
            const valueStr = typeof info.value === 'object' 
              ? JSON.stringify(info.value, null, 2).slice(0, 500) 
              : String(info.value);
            lines.push(`${indent}    • ${field}: ${info.type}`);
            lines.push(`${indent}      ${valueStr}`);
          }
        }
      });
    }
  } catch (err) {
    lines.push(`${indent}  ERROR: ${err.message}`);
  }

  // Recurse into subcollections
  try {
    const snapshot = await collectionRef.limit(5).get(); // small sample for discovery
    for (const doc of snapshot.docs) {
      const subcollections = await doc.ref.listCollections();
      for (const sub of subcollections) {
        const subPath = `${collectionPath}/${doc.id}/${sub.id}`;
        lines.push(...await exploreCollection(subPath, depth + 1, visited));
      }
    }
  } catch (e) {
    // ignore discovery errors
  }

  return lines;
}

async function dumpFullSchema() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputFile = path.join(OUTPUT_DIR, `full_firestore_schema_${timestamp}.txt`);

  console.log('🚀 Starting COMPLETE Firestore schema dump...');
  console.log('   Full documents everywhere except 3 limited log collections.\n');

  const allLines = [
    '================================================================================',
    'DOUGHBOYS PIZZERIA — COMPLETE FIRESTORE SCHEMA DUMP (FULL DOCUMENTS)',
    `Generated: ${new Date().toISOString()}`,
    'Project: doughboyspizzeria-2b3d2',
    'Limited collections (3 docs each): audit_logs, error_logs, public_error_logs',
    '================================================================================',
    ''
  ];

  const rootCollections = [
    'alerts', 'banners', 'categories', 'config', 'feedback', 'franchise_subscriptions',
    'franchisee_invitations', 'franchises', 'integrations', 'invoices', 'menu_items',
    'onboarding_progress', 'orders', 'payouts', 'platform_features', 'platform_invoices',
    'platform_payments', 'platform_plans', 'promotions', 'restaurant_types', 'support_chats',
    'support_requests', 'tax_reports', 'users', 'onboarding_templates', 'audit_logs',
    'error_logs', 'public_error_logs'
  ];

  const visited = new Set();

  for (const coll of rootCollections) {
    console.log(`Exploring: ${coll} ...`);
    const lines = await exploreCollection(coll, 0, visited);
    allLines.push(...lines);
    allLines.push('');
  }

  allLines.push('================================================================================');
  allLines.push('END OF COMPLETE SCHEMA DUMP');
  allLines.push(`Total collections/subcollections visited: ${visited.size}`);
  allLines.push('================================================================================');

  fs.writeFileSync(outputFile, allLines.join('\n'), 'utf8');

  console.log(`\n✅ Full schema dump completed!`);
  console.log(`   File: ${outputFile}`);
  console.log(`   Collections visited: ${visited.size}`);
}

dumpFullSchema().catch(err => {
  console.error('FATAL ERROR:', err);
  process.exit(1);
});