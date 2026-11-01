-- Private schema tables are accessed only through SECURITY DEFINER routines.
-- Direct table privileges remain revoked; these routines run as the table owner.
ALTER TABLE private.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.admin_bootstrap_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.access_codes ENABLE ROW LEVEL SECURITY;
