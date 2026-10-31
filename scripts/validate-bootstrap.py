#!/usr/bin/env python3
"""Static validation only; does not establish that PostgreSQL/Supabase replay succeeds."""
import datetime as dt
import hashlib
import json
import pathlib
import re

def top_level_sql(text):
    """Remove dollar-quoted bodies before checking reviewed migration backfills."""
    text = re.sub(r'(\$(?:[A-Za-z_][A-Za-z_0-9]*)?\$).*?\1', '', text, flags=re.S)
    return re.sub(r'--[^\n]*|/\*.*?\*/', '', text, flags=re.S)


def validate(root):
    manifest = json.loads((root / 'bootstrap/manifest.json').read_text())
    directory = root / 'bootstrap/supabase/migrations'
    files = sorted(directory.glob('*.sql'))
    names = [entry['file'] for entry in manifest['files']]
    assert len(names) == len(set(names)), 'Duplicate manifest filename'
    assert set(names) == {p.name for p in files}, 'Manifest coverage mismatch'
    assert manifest['schemaOnly'] and manifest['rowsExported'] is False
    upgrade = json.loads((root / 'bootstrap' / manifest['upgradeManifest']).read_text())
    upgrade_entries = {entry['file']: entry for entry in upgrade['files']}
    assert len(upgrade_entries) == len(upgrade['files']), 'Duplicate upgrade filename'
    cutoff = upgrade['baselineLastVersion']
    assert cutoff == '20261027001000', 'Unexpected baseline boundary'
    assert set(upgrade_entries) == {p.name for p in files if p.name.split('_')[0] > cutoff}
    allowed = set(upgrade['allowedTopLevelInsertFiles'])
    assert allowed == {
        '20261027174001_procurement_credentials.sql',
        '20261028010001_procurement_replenishment_queue.sql',
        '20261028020000_procurement_lifecycle_repair.sql',
    }, 'Unexpected backfill allowlist'
    versions = set()
    for entry in manifest['files']:
        p = directory / entry['file']
        assert hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256'], p.name
        assert len(p.read_text().splitlines()) < 500, p.name
        version = p.name.split('_')[0]
        assert re.fullmatch(r'\d{14}', version) and version not in versions, p.name
        dt.datetime.strptime(version, '%Y%m%d%H%M%S')
        versions.add(version)
        sql = p.read_text()
        if p.name in upgrade_entries:
            assert entry == upgrade_entries[p.name], 'Upgrade hash mismatch: ' + p.name
            canonical = root / 'supabase/migrations' / p.name
            assert canonical.read_bytes() == p.read_bytes(), 'Canonical drift: ' + p.name
            top = top_level_sql(sql)
            assert not re.search(r'\bCOPY\s', top, re.I), p.name
            if p.name not in allowed:
                assert not re.search(r'\bINSERT\s+INTO\s', top, re.I), p.name
            assert not re.search(r'\b(?:INSERT\s+INTO|COPY)\s+auth\.users\b', sql, re.I), p.name
        else:
            # The captured baseline remains strictly schema-only and immutable.
            assert not re.search(r'^COPY |^INSERT INTO ', sql, re.M), p.name
        assert not re.search(r'^\\(?:un)?restrict', sql, re.M), p.name
    text = '\n'.join(p.read_text() for p in files)
    for table in ['sites', 'profiles', 'site_members', 'settings', 'sale_order_items']:
        assert re.search(r'CREATE TABLE public\.' + table + r'\s*\(', text), table
    for function in ['user_can', 'current_user_site_role']:
        assert re.search(r'CREATE FUNCTION public\.' + function + r'\(', text), function
    assert 'supabase_functions.http_request(' not in text
    assert 'QA workflow webhook rejected: non-local destination' in text
    assert 'CREATE TRIGGER on_auth_user_created' in text
    assert 'CREATE SCHEMA IF NOT EXISTS public;' in text
    assert 'CREATE ROLE apps_migration_coordinator NOLOGIN NOINHERIT NOSUPERUSER' in text
    assert 'ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin' not in text
    assert manifest['platformCustomizations']['storagePolicies'] == 13
    return len(files), len(upgrade_entries)


if __name__ == '__main__':
    count, upgrades = validate(pathlib.Path(__file__).resolve().parents[1])
    print(f'Static validation passed: {count} migrations ({upgrades} canonical upgrades), hashes, coverage, core objects and local webhook guard.')
    print('Static checks and focused regressions do not establish full Supabase replay or E2E success.')