-- ============================================================================
-- 001_cv_tables.surql — Core CV table definitions (SCHEMAFULL)
-- ============================================================================

-- ── skill ───────────────────────────────────────────────────────────────────
DEFINE TABLE skill SCHEMAFULL;

DEFINE FIELD name          ON TABLE skill TYPE string;
DEFINE FIELD category      ON TABLE skill TYPE string
    ASSERT $value IN ["language", "infra", "tool", "ml"];
DEFINE FIELD proficiency   ON TABLE skill TYPE int
    ASSERT $value >= 1 AND $value <= 100;
DEFINE FIELD hours         ON TABLE skill TYPE float;
DEFINE FIELD years         ON TABLE skill TYPE float;
DEFINE FIELD description   ON TABLE skill TYPE option<string>;

-- ── project ─────────────────────────────────────────────────────────────────
DEFINE TABLE project SCHEMAFULL;

DEFINE FIELD title         ON TABLE project TYPE string;
DEFINE FIELD description   ON TABLE project TYPE string;
DEFINE FIELD tags          ON TABLE project TYPE array<string>;
DEFINE FIELD source_url    ON TABLE project TYPE option<string>;
DEFINE FIELD live_url      ON TABLE project TYPE option<string>;
DEFINE FIELD status        ON TABLE project TYPE string
    ASSERT $value IN ["active", "sleeping", "zombie"];
DEFINE FIELD visible       ON TABLE project TYPE bool DEFAULT true;
DEFINE FIELD sort_order    ON TABLE project TYPE int;

-- ── experience ──────────────────────────────────────────────────────────────
DEFINE TABLE experience SCHEMAFULL;

DEFINE FIELD title         ON TABLE experience TYPE string;
DEFINE FIELD company       ON TABLE experience TYPE string;
DEFINE FIELD start_date    ON TABLE experience TYPE string;
DEFINE FIELD end_date      ON TABLE experience TYPE option<string>;
DEFINE FIELD description   ON TABLE experience TYPE string;
DEFINE FIELD current       ON TABLE experience TYPE bool DEFAULT false;

-- ── certification ───────────────────────────────────────────────────────────
DEFINE TABLE certification SCHEMAFULL;

DEFINE FIELD title         ON TABLE certification TYPE string;
DEFINE FIELD issuer        ON TABLE certification TYPE string;
DEFINE FIELD date          ON TABLE certification TYPE string;

-- ── education ───────────────────────────────────────────────────────────────
DEFINE TABLE education SCHEMAFULL;

DEFINE FIELD institution   ON TABLE education TYPE string;
DEFINE FIELD program       ON TABLE education TYPE string;
DEFINE FIELD date          ON TABLE education TYPE string;
DEFINE FIELD description   ON TABLE education TYPE option<string>;

-- ── fortune ─────────────────────────────────────────────────────────────────
DEFINE TABLE fortune SCHEMAFULL;

DEFINE FIELD text          ON TABLE fortune TYPE string;
DEFINE FIELD author        ON TABLE fortune TYPE option<string>;

-- ── page_view ───────────────────────────────────────────────────────────────
DEFINE TABLE page_view SCHEMAFULL;

DEFINE FIELD path          ON TABLE page_view TYPE string;
DEFINE FIELD timestamp     ON TABLE page_view TYPE datetime DEFAULT time::now();
DEFINE FIELD referrer      ON TABLE page_view TYPE option<string>;

-- ── admin_user ──────────────────────────────────────────────────────────────
DEFINE TABLE admin_user SCHEMAFULL;

DEFINE FIELD username        ON TABLE admin_user TYPE string;
DEFINE FIELD hashed_password ON TABLE admin_user TYPE string;
