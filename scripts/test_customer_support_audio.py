"""Offline contract checks for the reviewed audio migration; no database access."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
NAME = '20261105200000_customer_support_audio.sql'


class AudioMigrationTests(unittest.TestCase):
    def setUp(self):
        self.sql = (ROOT / 'supabase/migrations' / NAME).read_text()

    def test_bootstrap_identical(self):
        self.assertEqual((ROOT / 'supabase/migrations' / NAME).read_bytes(),
                         (ROOT / 'bootstrap/supabase/migrations' / NAME).read_bytes())

    def test_default_acl_hazard_is_removed_before_grant(self):
        revoke = 'REVOKE ALL ON %I.customer_support_audio FROM PUBLIC, anon, authenticated, service_role'
        grant = 'GRANT SELECT, INSERT, UPDATE ON %I.customer_support_audio TO service_role'
        self.assertLess(self.sql.index(revoke), self.sql.index(grant))
        self.assertEqual(self.sql.count('GRANT SELECT'), 1)
        self.assertIn('ENABLE ROW LEVEL SECURITY', self.sql)
        self.assertNotIn('CREATE POLICY', self.sql)

    def test_receipt_constraints_and_schema_scope(self):
        for fragment in ["nspname = 'public'", "to_regclass(format('%I.sites', nspname)) IS NOT NULL",
                         'PRIMARY KEY (site_id, source_hash)', 'ON DELETE CASCADE',
                         "^[0-9a-f]{64}$", "status IN (''pending'', ''complete'')",
                         'length(transcript) <= 12000',
                         "status <> ''complete'' OR (transcript IS NOT NULL AND length(transcript) > 0)",
                         'created_at timestamptz NOT NULL DEFAULT now()']:
            self.assertIn(fragment, self.sql)


if __name__ == '__main__':
    unittest.main()
