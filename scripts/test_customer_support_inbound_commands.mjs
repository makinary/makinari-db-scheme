// Offline only: in-memory PostgreSQL; no environment files or network connections.
// Uses the already-installed sibling API dependency (no install required).
import { PGlite } from '../../API/node_modules/@electric-sql/pglite/dist/index.js';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import test from 'node:test';

const root = new URL('../', import.meta.url);
const name = '20261105193000_customer_support_inbound_commands.sql';
const sql = readFileSync(new URL(`supabase/migrations/${name}`, root), 'utf8');
const table = 'customer_support_inbound_commands';

test('bootstrap bytes, ordered manifests and permanent receipt contract', () => {
  assert.equal(readFileSync(new URL(`bootstrap/supabase/migrations/${name}`, root), 'utf8'), sql);
  for (const file of ['manifest.json', 'upgrades-20261030.json']) {
    const { files } = JSON.parse(readFileSync(new URL(`bootstrap/${file}`, root)));
    assert.deepEqual(files.filter(x => x.file === name), [
      { file: name, sha256: createHash('sha256').update(sql).digest('hex') },
    ]);
    assert.deepEqual(files.map(x => x.file), files.map(x => x.file).sort());
  }
  const body = sql.replace(/--[^\n]*/g, '');
  assert.doesNotMatch(body, /\b(DELETE|TRUNCATE|CASCADE|TRIGGER|FUNCTION|POLICY)\b/i);
  assert.doesNotMatch(body, /\b(expir\w*|lease\w*|reclaim\w*)\b/i);
  assert.ok(body.indexOf('authenticated, service_role') < body.indexOf('GRANT SELECT, INSERT, UPDATE'));
});

test('schema scope, identity, constraints, no reclaim and default ACL hardening', async () => {
  const db = new PGlite();
  const query = async text => (await db.query(text)).rows;
  const fail = async (text, code) => assert.rejects(db.query(text), e => e.code === code);
  try {
    await db.exec(`
      CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
      CREATE SCHEMA app_tenant; CREATE SCHEMA "app_Quoted-Tenant";
      CREATE SCHEMA app_empty; CREATE SCHEMA application; CREATE SCHEMA other;
      ALTER DEFAULT PRIVILEGES GRANT ALL ON TABLES TO PUBLIC, anon, authenticated, service_role;
    `);
    for (const s of ['public', 'app_tenant', 'app_Quoted-Tenant', 'application', 'other']) {
      await db.exec(`CREATE TABLE "${s}".commands (id uuid PRIMARY KEY);`);
    }
    await db.exec(sql);
    assert.deepEqual((await query(`SELECT n.nspname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relname='${table}' ORDER BY 1`)).map(x => x.nspname), ['app_Quoted-Tenant', 'app_tenant', 'public']);
    for (const s of ['public', 'app_tenant', 'app_Quoted-Tenant']) {
      const t = `"${s}".${table}`;
      assert.deepEqual(await query(`SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema='${s}' AND table_name='${table}' ORDER BY ordinal_position`), [
        ['site_id', 'uuid', 'NO'], ['connection_id', 'text', 'NO'],
        ['origin_message_id', 'text', 'NO'], ['owner_token', 'uuid', 'NO'],
        ['command_id', 'uuid', 'YES'], ['created_at', 'timestamp with time zone', 'NO'],
      ].map(([column_name, data_type, is_nullable]) => ({ column_name, data_type, is_nullable })));
      assert.equal((await query(`SELECT column_default FROM information_schema.columns WHERE table_schema='${s}' AND table_name='${table}' AND column_name='created_at'`))[0].column_default, 'now()');
      assert.equal((await query(`SELECT relrowsecurity FROM pg_class WHERE oid='${t}'::regclass`))[0].relrowsecurity, true);
      assert.equal((await query(`SELECT count(*)::int AS n FROM pg_policy WHERE polrelid='${t}'::regclass`))[0].n, 0);
      for (const role of ['anon', 'authenticated', 'service_role']) {
        for (const privilege of ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER']) {
          assert.equal((await query(`SELECT has_table_privilege('${role}', '${t}', '${privilege}') AS ok`))[0].ok,
            role === 'service_role' && ['SELECT', 'INSERT', 'UPDATE'].includes(privilege), `${s}/${role}/${privilege}`);
        }
      }
      const site = '00000000-0000-0000-0000-000000000001';
      const owner = '00000000-0000-0000-0000-000000000002';
      const command = '00000000-0000-0000-0000-000000000003';
      const insert = (sid = site, conn = 'connection', origin = 'message', token = `'${owner}'`) =>
        `INSERT INTO ${t} (site_id,connection_id,origin_message_id,owner_token) VALUES ('${sid}','${conn}','${origin}',${token})`;
      await db.exec(`GRANT USAGE ON SCHEMA "${s}" TO service_role; SET ROLE service_role;`);
      await db.exec(insert());
      await fail(insert(), '23505');
      await fail(insert(site, '', 'other'), '23514');
      await fail(insert(site, 'other', ''), '23514');
      await fail(insert(site, 'other', 'other', 'NULL'), '23502');
      await db.exec(insert(owner)); // same provider identity in a different site
      await db.exec(insert(site, 'other')); // different connection
      await db.exec(insert(site, 'connection', 'other')); // different origin
      await db.exec(`UPDATE ${t} SET created_at=now()-interval '10 years'`);
      await fail(insert(), '23505'); // old unbound receipts remain authoritative
      await fail(`DELETE FROM ${t}`, '42501');
      await fail(`TRUNCATE ${t}`, '42501');
      await fail(`UPDATE ${t} SET command_id='${command}'`, '23503');
      await db.exec('RESET ROLE');
      await db.exec(`INSERT INTO "${s}".commands VALUES ('${command}'); SET ROLE service_role;`);
      await db.exec(`UPDATE ${t} SET command_id='${command}'`);
      assert.equal((await query(`SELECT count(*)::int AS n FROM ${t} WHERE command_id='${command}' AND owner_token='${owner}'`))[0].n, 4);
      await db.exec('RESET ROLE');
      await fail(`DELETE FROM "${s}".commands`, '23503'); // no cascading receipt removal
    }
  } finally {
    await db.close();
  }
});
