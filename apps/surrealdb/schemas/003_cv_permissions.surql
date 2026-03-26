-- ============================================================================
-- 003_cv_permissions.surql — Access control for CV tables
-- ============================================================================

-- ── Public CV tables: anyone can SELECT, only admin can CUD ─────────────────

DEFINE ACCESS admin ON DATABASE TYPE RECORD
    SIGNUP (CREATE admin_user SET username = $username, hashed_password = crypto::argon2::generate($password))
    SIGNIN (SELECT * FROM admin_user WHERE username = $username AND crypto::argon2::compare(hashed_password, $password))
    DURATION FOR SESSION 24h;

-- skill
DEFINE ACCESS skill_public ON TABLE skill TYPE RECORD
    WITH JWT ALGORITHM HS256 KEY "unused"
    DURATION FOR SESSION 1h;
-- Allow all users to SELECT
-- CUD restricted to root/admin via default deny

-- project
DEFINE ACCESS project_public ON TABLE project TYPE RECORD
    WITH JWT ALGORITHM HS256 KEY "unused"
    DURATION FOR SESSION 1h;

-- experience
DEFINE ACCESS experience_public ON TABLE experience TYPE RECORD
    WITH JWT ALGORITHM HS256 KEY "unused"
    DURATION FOR SESSION 1h;

-- certification
DEFINE ACCESS certification_public ON TABLE certification TYPE RECORD
    WITH JWT ALGORITHM HS256 KEY "unused"
    DURATION FOR SESSION 1h;

-- education
DEFINE ACCESS education_public ON TABLE education TYPE RECORD
    WITH JWT ALGORITHM HS256 KEY "unused"
    DURATION FOR SESSION 1h;

-- fortune
DEFINE ACCESS fortune_public ON TABLE fortune TYPE RECORD
    WITH JWT ALGORITHM HS256 KEY "unused"
    DURATION FOR SESSION 1h;

-- ── Public CV tables: SELECT for all ────────────────────────────────────────

DEFINE TABLE skill   PERMISSIONS
    FOR select FULL
    FOR create, update, delete WHERE $auth.admin = true;

DEFINE TABLE project PERMISSIONS
    FOR select FULL
    FOR create, update, delete WHERE $auth.admin = true;

DEFINE TABLE experience PERMISSIONS
    FOR select FULL
    FOR create, update, delete WHERE $auth.admin = true;

DEFINE TABLE certification PERMISSIONS
    FOR select FULL
    FOR create, update, delete WHERE $auth.admin = true;

DEFINE TABLE education PERMISSIONS
    FOR select FULL
    FOR create, update, delete WHERE $auth.admin = true;

DEFINE TABLE fortune PERMISSIONS
    FOR select FULL
    FOR create, update, delete WHERE $auth.admin = true;

-- ── Private tables: all operations require admin ────────────────────────────

DEFINE TABLE page_view PERMISSIONS
    FOR select, create, update, delete WHERE $auth.admin = true;

DEFINE TABLE admin_user PERMISSIONS
    FOR select, create, update, delete WHERE $auth.admin = true;
