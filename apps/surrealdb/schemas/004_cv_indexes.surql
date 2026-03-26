-- ============================================================================
-- 004_cv_indexes.surql — Search and unique indexes
-- ============================================================================

-- ── Full-text search indexes ────────────────────────────────────────────────

DEFINE ANALYZER cv_analyzer TOKENIZERS blank, class FILTERS lowercase, ascii, snowball(english);

DEFINE INDEX idx_project_title_search
    ON TABLE project
    FIELDS title
    SEARCH ANALYZER cv_analyzer BM25;

DEFINE INDEX idx_project_desc_search
    ON TABLE project
    FIELDS description
    SEARCH ANALYZER cv_analyzer BM25;

DEFINE INDEX idx_experience_desc_search
    ON TABLE experience
    FIELDS description
    SEARCH ANALYZER cv_analyzer BM25;

-- ── Unique indexes ──────────────────────────────────────────────────────────

DEFINE INDEX idx_skill_name_unique
    ON TABLE skill
    FIELDS name
    UNIQUE;

DEFINE INDEX idx_admin_username_unique
    ON TABLE admin_user
    FIELDS username
    UNIQUE;
