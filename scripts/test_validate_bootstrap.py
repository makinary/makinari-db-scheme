"""Offline regression tests; no credentials, database connections or deployment."""
import importlib.util
import hashlib
import json
import pathlib
import shutil
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('validator', ROOT / 'scripts/validate-bootstrap.py')
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


class BootstrapValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        shutil.copytree(ROOT / 'bootstrap', self.root / 'bootstrap')
        shutil.copytree(ROOT / 'supabase/migrations', self.root / 'supabase/migrations')

    def test_current_bootstrap_and_upgrades(self):
        self.assertEqual(VALIDATOR.validate(self.root), (226, 80))

    def test_qa_compatibility_is_not_a_canonical_upgrade(self):
        name = '20261113210450_qa_accounting_wrapper_oid_compatibility.sql'
        source = self.root / 'bootstrap/supabase/migrations' / name
        self.assertTrue(source.exists())
        self.assertFalse((self.root / 'supabase/migrations' / name).exists())
        shutil.copy2(source, self.root / 'supabase/migrations' / name)
        with self.assertRaisesRegex(AssertionError, 'QA-only file in canonical history'):
            VALIDATOR.validate(self.root)

    def test_unreviewed_qa_compatibility_list_is_rejected(self):
        path = self.root / 'bootstrap/manifest.json'
        manifest = json.loads(path.read_text())
        manifest['qaCompatibilityFiles'] = []
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(AssertionError, 'Unexpected QA compatibility files'):
            VALIDATOR.validate(self.root)

    def test_duplicate_manifest_entry_is_rejected(self):
        path = self.root / 'bootstrap/manifest.json'
        manifest = json.loads(path.read_text())
        manifest['files'][-1] = manifest['files'][0]
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(AssertionError, 'Duplicate manifest filename'):
            VALIDATOR.validate(self.root)

    def test_canonical_drift_is_rejected(self):
        path = self.root / 'supabase/migrations/20261030220000_procurement_quotation_detail.sql'
        path.write_text(path.read_text() + '\n-- drift\n')
        with self.assertRaisesRegex(AssertionError, 'Canonical drift'):
            VALIDATOR.validate(self.root)

    def test_unlisted_sql_is_rejected(self):
        (self.root / 'bootstrap/supabase/migrations/20261030230000_unreviewed.sql').write_text('SELECT 1;')
        with self.assertRaisesRegex(AssertionError, 'Manifest coverage mismatch'):
            VALIDATOR.validate(self.root)

    def test_function_insert_is_not_a_backfill(self):
        sql = 'CREATE FUNCTION f() RETURNS void AS $body$ BEGIN\nINSERT INTO x VALUES(1); END $body$ LANGUAGE plpgsql;'
        self.assertNotIn('INSERT', VALIDATOR.top_level_sql(sql))
        self.assertIn('INSERT', VALIDATOR.top_level_sql(sql + '\nINSERT INTO y VALUES(2);'))

    def test_openrouter_backfills_only_private_platform_attribution(self):
        for filename, target, source in [
            ('20261112021000_openrouter_command_routing.sql', 'openrouter_command_routing', 'commands'),
            ('20261112022000_openrouter_plan_routing.sql', 'openrouter_plan_routing', 'instance_plans'),
        ]:
            top = VALIDATOR.top_level_sql((self.root / 'supabase/migrations' / filename).read_text())
            self.assertEqual(top.upper().count('INSERT INTO'), 1)
            self.assertIn('INSERT INTO public.' + target, top)
            self.assertIn('FROM public.' + source, top)
            self.assertIn("'payer','platform'", top.replace(' ', ''))
            self.assertNotRegex(top, r'(?im)^\s*(?:UPDATE|DELETE\s+FROM|TRUNCATE)\b')

    def test_unreviewed_insert_rejected_even_with_matching_hashes(self):
        name = '20261030220000_procurement_quotation_detail.sql'
        path = self.root / 'bootstrap/supabase/migrations' / name
        sql = path.read_text() + '\nINSERT INTO public.sites DEFAULT VALUES;\n'
        path.write_text(sql)
        (self.root / 'supabase/migrations' / name).write_text(sql)
        for filename in ['manifest.json', 'upgrades-20261030.json']:
            metadata = self.root / 'bootstrap' / filename
            content = json.loads(metadata.read_text())
            for entry in content['files']:
                if entry['file'] == name:
                    entry['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
            metadata.write_text(json.dumps(content))
        with self.assertRaisesRegex(AssertionError, name):
            VALIDATOR.validate(self.root)


if __name__ == '__main__':
    unittest.main()