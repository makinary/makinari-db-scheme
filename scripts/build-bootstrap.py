#!/usr/bin/env python3
"""Build reviewed QA-only schema chunks; never rewrite historical migrations."""
import hashlib
import datetime as dt
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]


def transform(text):
    blocks = re.split(r'(?=^--\n-- Name: )', text, flags=re.M)
    removed = []
    out = []
    for block in blocks:
        header = re.search(r'^-- Name: (.*)$', block, re.M)
        name = header.group(1) if header else 'preamble'
        if re.search(r'CREATE TRIGGER\s+messages_webhooks\b', block):
            removed.append(name)
            continue
        if 'supabase_functions.http_request(' in block:
            raise ValueError('Unexpected direct HTTP trigger; manual review required')
        if name.startswith('dispatch_workflow_database_webhook(); Type: FUNCTION;'):
            anchor = "  webhook_headers := jsonb_build_object('Content-Type', 'application/json');"
            guard = """  -- QA bootstrap must never dispatch to external or production destinations.
  IF webhook_url !~ '^http://(127[.]0[.]0[.]1|localhost|host[.]docker[.]internal):[0-9]+/' THEN
    RAISE WARNING 'QA workflow webhook rejected: non-local destination';
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
  END IF;

"""
            if block.count(anchor) != 1:
                raise ValueError('Dispatcher shape changed; manual review required')
            block = block.replace(anchor, guard + anchor)
        block = re.sub(r'^\\(?:un)?restrict.*\n', '', block, flags=re.M)
        out.append(block)
    if len(removed) != 1:
        raise ValueError('Expected exactly one legacy external messages webhook')
    return out, removed


def split_statements(text):
    # Avoid splitting SQL statements or dollar-quoted function bodies across migrations.
    statements = []
    start = i = 0
    quote = None
    while i < len(text):
        if quote:
            if text.startswith(quote, i):
                if quote in ["'", '"'] and text.startswith(quote + quote, i):
                    i += 2
                    continue
                i += len(quote)
                quote = None
            else:
                i += 1
            continue
        if text.startswith('--', i):
            end = text.find('\n', i)
            i = len(text) if end < 0 else end + 1
            continue
        if text.startswith('/*', i):
            end = text.find('*/', i + 2)
            if end < 0:
                raise ValueError('Unclosed comment')
            i = end + 2
            continue
        if text[i] in ["'", '"']:
            quote = text[i]
            i += 1
            continue
        dollar = re.match(r'\$(?:[A-Za-z_][A-Za-z_0-9]*)?\$', text[i:]) if text[i] == '$' else None
        if dollar:
            quote = dollar.group(0)
            i += len(quote)
            continue
        if text[i] == ';':
            statements.append(text[start:i + 1])
            start = i + 1
        i += 1
    if quote:
        raise ValueError('Unclosed SQL quote')
    if text[start:].strip():
        statements.append(text[start:])
    return statements


def build():
    source = ROOT / '.exports/schema-raw.sql'
    raw = source.read_text()
    if 'PostgreSQL database dump complete' not in raw:
        raise ValueError('Incomplete pg_dump export')
    blocks, removed = transform(raw)
    target = ROOT / 'bootstrap/supabase/migrations'
    target.mkdir(parents=True, exist_ok=True)
    if any(target.glob('*.sql')):
        raise ValueError('Bootstrap already exists; generate a new version instead of overwriting')
    preamble = """-- Fresh QA Supabase only. Never apply this bootstrap to an existing database.
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS moddatetime WITH SCHEMA public;
"""
    # Each chunk restores dump session settings because migration runners may use separate sessions.
    settings = "SET search_path = '';\nSET check_function_bodies = false;\nSET row_security = off;\n"
    chunks = []
    current = preamble
    for statement in split_statements(''.join(blocks)):
        if len(statement.splitlines()) > 490:
            # These captured functions contain standalone SQL comments, not multiline text literals.
            # Keep executable lines unchanged; remove empty/comment-only lines for bounded files.
            statement = '\n'.join(line for line in statement.splitlines()
                                  if line.strip() and not line.lstrip().startswith('--')) + '\n'
        if len(statement.splitlines()) > 490:
            # Fold adjacent punctuation/control lines only; never fold quoted literals or comments.
            lines = statement.splitlines()
            folded = []
            for line in lines:
                if folded and re.fullmatch(r'[\sA-Za-z0-9_;(),.=<>:+*/]+', line) and re.fullmatch(r'[\sA-Za-z0-9_;(),.=<>:+*/]+', folded[-1]) and len(folded[-1]) + len(line) < 180:
                    folded[-1] += ' ' + line.strip()
                else:
                    folded.append(line)
            statement = '\n'.join(folded) + '\n'
        if len(statement.splitlines()) > 490:
            raise ValueError('Oversized SQL statement requires explicit formatting review')
        if len((settings + current + statement).splitlines()) >= 495:
            chunks.append(settings + current)
            current = ''
        current += statement
    if current.strip():
        chunks.append(settings + current)
    files = []
    for index, text in enumerate(chunks):
        version = (dt.datetime(2026, 10, 27) + dt.timedelta(seconds=index)).strftime('%Y%m%d%H%M%S')
        name = f'{version}_qa_baseline_{index:03d}.sql'
        (target / name).write_text(text + '\n')
        files.append({'file': name, 'sha256': hashlib.sha256((text + '\n').encode()).hexdigest()})
    manifest = {'capturedAt': json.loads((ROOT / '.exports/export-metadata.json').read_text())['capturedAt'],
                'rawSha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'schemaOnly': True,
                'rowsExported': False, 'purpose': 'fresh-local-qa-bootstrap',
                'removedObjects': removed, 'modifiedObjects': ['public.dispatch_workflow_database_webhook: local destination guard'],
                'files': files, 'validation': 'static-only; fresh Supabase replay pending'}
    platform_file = ROOT / '.exports/platform-customizations.json'
    if platform_file.exists():
        platform = json.loads(platform_file.read_text())
        lines = ['-- Custom triggers and policies on Supabase-owned objects; no platform data.']
        lines.extend(platform.get('auth_triggers') or [])
        ident = lambda value: '"' + value.replace('"', '""') + '"'
        for policy in platform.get('storage_policies') or []:
            line = f'CREATE POLICY {ident(policy["name"])} ON storage.{ident(policy["table"])} AS {policy["permissive"]} FOR {policy["command"]} TO '
            line += ', '.join(ident(role) for role in policy['roles'])
            if policy['using']:
                line += ' USING (' + policy['using'] + ')'
            if policy['check']:
                line += ' WITH CHECK (' + policy['check'] + ')'
            lines.append(line + ';')
        text = '\n'.join(lines) + '\n'
        name = '20261027001000_qa_platform_customizations.sql'
        (target / name).write_text(text)
        files.append({'file': name, 'sha256': hashlib.sha256(text.encode()).hexdigest()})
        manifest['platformCustomizations'] = {'authTriggers': len(platform.get('auth_triggers') or []),
                                             'storagePolicies': len(platform.get('storage_policies') or [])}
    (ROOT / 'bootstrap/manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Created {len(files)} bounded SQL chunks. Historical migrations unchanged.')


if __name__ == '__main__':
    build()