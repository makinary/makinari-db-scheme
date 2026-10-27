const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const dotenv = require(path.resolve(root, '../market-fit/node_modules/dotenv'));
const env = { ...process.env, ...dotenv.parse(fs.readFileSync(path.join(root, '.env.local'))), PGCONNECT_TIMEOUT: '15' };
for (const k of ['PGHOST', 'PGPORT', 'PGUSER', 'PGDATABASE', 'PGPASSWORD']) if (!env[k]) throw Error(`${k} is required`);
const refPath = path.join(root, 'supabase/.temp/project-ref');
const poolPath = path.join(root, 'supabase/.temp/pooler-url');
if (fs.existsSync(refPath) && fs.existsSync(poolPath)) {
  const ref = fs.readFileSync(refPath, 'utf8').trim();
  if (env.PGHOST === `db.${ref}.supabase.co`) {
    const u = new URL(fs.readFileSync(poolPath, 'utf8').trim());
    if (!u.hostname.endsWith('.pooler.supabase.com') || u.password) throw Error('Invalid cached session pooler');
    env.PGHOST = u.hostname; env.PGPORT = u.port || '5432'; env.PGUSER = decodeURIComponent(u.username) || `postgres.${ref}`;
  }
}
const dir = path.join(root, '.exports');
fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
fs.chmodSync(dir, 0o700);
function command(binary, args) {
  const r = spawnSync(binary, args, { env, encoding: 'utf8', timeout: 240000 });
  if (r.status !== 0) {
    fs.writeFileSync(path.join(dir, 'export-error.log'), r.stderr || String(r.error), { mode: 0o600 });
    throw Error('Export failed; inspect private .exports/export-error.log. No remote changes were made.');
  }
  return r.stdout;
}
try {
  const bin = process.env.PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';
  const sql = "BEGIN READ ONLY; SELECT nspname FROM pg_namespace WHERE nspname NOT IN ('pg_catalog','information_schema','auth','storage','realtime','extensions','graphql','graphql_public','net','pgsodium','pgsodium_masks','vault','supabase_functions','supabase_migrations','_analytics','_realtime') AND nspname NOT LIKE 'pg_%' ORDER BY nspname; COMMIT;";
  const schemas = command(path.join(bin, 'psql'), ['-X', '-w', '-At', '-v', 'ON_ERROR_STOP=1', '-c', sql]).trim().split('\n').filter(s => s !== 'BEGIN' && s !== 'COMMIT');
  const file = path.join(dir, 'schema-raw.sql');
  // Never dump rows or platform-owned schemas. Raw DDL can still contain secrets; keep it private.
  command(path.join(bin, 'pg_dump'), ['--schema-only', '--no-owner', '--no-comments', '--no-security-labels',
    '--lock-wait-timeout=10000', ...schemas.flatMap(s => ['--schema', s]), '--file', file]);
  fs.chmodSync(file, 0o600);
  fs.writeFileSync(path.join(dir, 'export-metadata.json'), JSON.stringify({ capturedAt: new Date().toISOString(), schemas,
    schemaOnly: true, rowsExported: false, state: 'raw-export-requires-review' }, null, 2), { mode: 0o600 });
  console.log(`Schema-only export complete: ${fs.statSync(file).size} bytes. Raw DDL is private and not ready for Git.`);
} catch (error) { console.error(error.message); process.exitCode = 1; }