-- ============================================================================
-- 003_cv_permissions.surql — Access control (database-level auth)
-- ============================================================================
-- Table-level permissions are defined inline in 001_cv_tables.surql.

-- ── Admin access: record-based auth on the database ──────────────────────────

DEFINE ACCESS admin ON DATABASE TYPE RECORD
    SIGNUP (CREATE admin_user SET username = $username, hashed_password = crypto::argon2::generate($password))
    SIGNIN (SELECT * FROM admin_user WHERE username = $username AND crypto::argon2::compare(hashed_password, $password))
    DURATION FOR SESSION 24h;
