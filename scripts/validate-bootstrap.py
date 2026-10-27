#!/usr/bin/env python3
"""Static validation only; does not establish that PostgreSQL/Supabase replay succeeds."""
import datetime as dt
import hashlib
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'bootstrap/manifest.json').read_text())
directory = root / 'bootstrap/supabase/migrations'
files = sorted(directory.glob('*.sql'))
assert len(files) == len(manifest['files'])
assert manifest['schemaOnly'] and manifest['rowsExported'] is False
for entry in manifest['files']:
    p = directory / entry['file']
    assert hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256'], p.name
    assert len(p.read_text().splitlines()) < 500, p.name
    dt.datetime.strptime(p.name.split('_')[0], '%Y%m%d%H%M%S')
text = '\n'.join(p.read_text() for p in files)
for table in ['sites', 'profiles', 'site_members', 'settings', 'sale_order_items']:
    assert re.search(r'CREATE TABLE public\.' + table + r'\s*\(', text), table
for function in ['user_can', 'current_user_site_role']:
    assert re.search(r'CREATE FUNCTION public\.' + function + r'\(', text), function
assert 'supabase_functions.http_request(' not in text
assert 'QA workflow webhook rejected: non-local destination' in text
assert 'CREATE TRIGGER on_auth_user_created' in text
assert not re.search(r'^COPY |^INSERT INTO ', text, re.M)
assert not re.search(r'^\\(?:un)?restrict', text, re.M)
assert manifest['platformCustomizations']['storagePolicies'] == 13
print(f'Static validation passed: {len(files)} chunks, manifest hashes, core objects, auth trigger, Storage policies and local webhook guard.')
print('Fresh Supabase runtime replay is still required; no database or E2E pass is claimed.')