-- ============================================================================
-- 002_cv_relations.surql — RELATE edge table definitions
-- ============================================================================

-- skill ENABLES skill — skill dependency / prerequisite trees
-- e.g., python ENABLES ml, docker ENABLES kubernetes
DEFINE TABLE enables SCHEMAFULL TYPE RELATION IN skill OUT skill;

-- project USES_SKILL skill — which skills a project leverages
DEFINE TABLE uses_skill SCHEMAFULL TYPE RELATION IN project OUT skill;
DEFINE FIELD role ON TABLE uses_skill TYPE string
    ASSERT $value IN ["primary", "secondary"];

-- experience PRODUCED project — work experience that led to a project
DEFINE TABLE produced SCHEMAFULL TYPE RELATION IN experience OUT project;

-- experience REQUIRED skill — skills used in a role
DEFINE TABLE required SCHEMAFULL TYPE RELATION IN experience OUT skill;

-- certification VALIDATES skill — certifications that prove skill competency
DEFINE TABLE validates SCHEMAFULL TYPE RELATION IN certification OUT skill;
