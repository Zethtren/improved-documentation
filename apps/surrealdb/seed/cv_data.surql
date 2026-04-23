-- ============================================================================
-- cv_data.surql — Seed data extracted from leptos-cv main.rs
-- ============================================================================

-- ── Skills ──────────────────────────────────────────────────────────────────

CREATE skill:python SET
    name = "Python",
    category = "language",
    proficiency = 90,
    hours = 3000.0,
    years = 6.0,
    description = "Pipelines, ML, automation — the glue that holds everything together";

CREATE skill:rust SET
    name = "Rust",
    category = "language",
    proficiency = 75,
    hours = 1500.0,
    years = 3.0,
    description = "Systems code, WASM, the reason I have strong opinions about lifetimes";

CREATE skill:go SET
    name = "Go",
    category = "language",
    proficiency = 70,
    hours = 1200.0,
    years = 2.5,
    description = "Services, CLI tools, concurrency that doesn't hurt";

CREATE skill:sql SET
    name = "SQL",
    category = "language",
    proficiency = 85,
    hours = 2400.0,
    years = 5.0,
    description = "PostgreSQL, analytics, the query that probably needs an index";

CREATE skill:gcp SET
    name = "GCP",
    category = "infra",
    proficiency = 90,
    hours = 3200.0,
    years = 4.0,
    description = "Cloud Run, GKE, VPCs, Secrets, Storage (most of the acronyms)";

CREATE skill:docker SET
    name = "Docker",
    category = "infra",
    proficiency = 88,
    hours = 2800.0,
    years = 4.0,
    description = "Containerize it, orchestrate it, ship it";

CREATE skill:kubernetes SET
    name = "Kubernetes",
    category = "infra",
    proficiency = 82,
    hours = 2000.0,
    years = 3.0,
    description = "GKE orchestration, service meshes, helm charts";

CREATE skill:cloud_run SET
    name = "Cloud Run",
    category = "infra",
    proficiency = 85,
    hours = 1600.0,
    years = 3.0,
    description = "Serverless container deployments on GCP";

CREATE skill:ml SET
    name = "Machine Learning",
    category = "ml",
    proficiency = 80,
    hours = 2200.0,
    years = 4.0,
    description = "Predictive models, deep learning, TensorFlow";

CREATE skill:tensorflow SET
    name = "TensorFlow",
    category = "ml",
    proficiency = 72,
    hours = 1000.0,
    years = 3.0,
    description = "Deep learning framework for training and serving models";

CREATE skill:postgresql SET
    name = "PostgreSQL",
    category = "tool",
    proficiency = 82,
    hours = 2000.0,
    years = 5.0,
    description = "Primary relational database for analytics and application data";

CREATE skill:leptos SET
    name = "Leptos",
    category = "tool",
    proficiency = 60,
    hours = 400.0,
    years = 1.0,
    description = "Rust web framework compiled to WASM";

CREATE skill:wasm SET
    name = "WASM",
    category = "tool",
    proficiency = 55,
    hours = 350.0,
    years = 1.0,
    description = "WebAssembly for high-performance browser applications";

CREATE skill:data_engineering SET
    name = "Data Engineering",
    category = "tool",
    proficiency = 85,
    hours = 2600.0,
    years = 5.0,
    description = "Pipelines, ETL, data quality, warehouse design";

CREATE skill:metabase SET
    name = "Metabase",
    category = "tool",
    proficiency = 65,
    hours = 300.0,
    years = 1.0,
    description = "Open-source BI dashboarding and data quality monitoring";

CREATE skill:api_design SET
    name = "API Design",
    category = "tool",
    proficiency = 78,
    hours = 1400.0,
    years = 3.0,
    description = "RESTful APIs, decorator patterns, clean interfaces";

-- ── Experience ──────────────────────────────────────────────────────────────

CREATE experience:nicular SET
    title = "Lead Developer",
    company = "Nicular LLC",
    start_date = "2022-07",
    end_date = NONE,
    current = true,
    description = "Lead dev on the cloud side. Helped design and build much of the company's GCP architecture — VPCs, secrets management, client storage, and the supporting bits — and built internal tooling so the team can ship services to Cloud Run or GKE without wrestling with infra. Helped drive the migration of legacy GCP-managed apps into Kubernetes, and review a lot of what goes to production.";

CREATE experience:johnson_group SET
    title = "Data Scientist / Analyst",
    company = "Johnson Group Marketing",
    start_date = "2021-02",
    end_date = "2022-04",
    current = false,
    description = "Turned a daily reporting grind — 4+ hours of manual spreadsheet work — into a set of scripts that ran in 15 minutes. Built predictive models to establish baseline marketing performance, and created geographic tracking tools that fed hiring leads and market opportunities directly to clients.";

CREATE experience:yawye SET
    title = "QA Analyst",
    company = "Yawye (Start-up)",
    start_date = "2020-05",
    end_date = "2020-05",
    current = false,
    description = "Short contract, big migration. Moved the startup's analytics layer from MongoDB to PostgreSQL, built Metabase dashboards for data quality monitoring, and helped define what data was actually worth collecting in the first place.";

CREATE experience:general_assembly SET
    title = "Data Scientist",
    company = "General Assembly",
    start_date = "2019-12",
    end_date = "2020-03",
    current = false,
    description = "Where it all started. Immersive program focused on building real things — ML models, data pipelines, SQL-driven analytics — with a personal obsession for writing readable, portable code. Built tools designed to run on distributed cloud architectures from day one.";

-- ── Projects ────────────────────────────────────────────────────────────────

CREATE project:docker_scraper SET
    title = "DockerScraper",
    description = "Spins up containers that scrape live crypto ticker data and pipe it straight into Postgres — ready for ML models to chew on.",
    tags = ["Python", "Docker", "PostgreSQL"],
    source_url = "https://github.com/Zethtren/DockerScraper",
    live_url = NONE,
    status = "active",
    visible = true,
    sort_order = 1;

CREATE project:roam_chat SET
    title = "RoamChat",
    description = "Unofficial API for Roam Chat. Send messages, handle failures gracefully, and wrap it all in a clean decorator pattern. Open-sourced because APIs should just work.",
    tags = ["Python", "API", "Open Source"],
    source_url = "https://github.com/Zethtren/RoamUnofficial",
    live_url = NONE,
    status = "active",
    visible = true,
    sort_order = 2;

CREATE project:nicular_cloud SET
    title = "Nicular Cloud Platform",
    description = "Built an entire production GCP environment from scratch — VPCs, secrets, storage, deploy pipelines. The team ships to Cloud Run and GKE without touching infra.",
    tags = ["GCP", "Kubernetes", "Cloud Run"],
    source_url = NONE,
    live_url = NONE,
    status = "active",
    visible = true,
    sort_order = 3;

CREATE project:marketing_intelligence SET
    title = "Marketing Intelligence",
    description = "Replaced 4+ hours of daily manual reporting with 15-minute automated pipelines. Added predictive baselines and geographic lead tracking that clients actually used.",
    tags = ["Python", "SQL", "ML"],
    source_url = NONE,
    live_url = NONE,
    status = "sleeping",
    visible = true,
    sort_order = 4;

CREATE project:crypto_ml_pipeline SET
    title = "Crypto ML Pipeline",
    description = "End-to-end machine learning pipeline for crypto market analysis. Ingests live data, trains models, and surfaces predictions — all containerized and cloud-native.",
    tags = ["Python", "ML", "Docker"],
    source_url = NONE,
    live_url = NONE,
    status = "sleeping",
    visible = true,
    sort_order = 5;

CREATE project:leptos_cv SET
    title = "leptos-cv",
    description = "You're looking at it. A terminal-themed CV compiled to WASM with Leptos, styled in Catppuccin, because resumes should have a theme switcher.",
    tags = ["Rust", "Leptos", "WASM"],
    source_url = "https://github.com/Zethtren/leptos-cv",
    live_url = NONE,
    status = "active",
    visible = true,
    sort_order = 6;

-- ── Certifications ──────────────────────────────────────────────────────────

CREATE certification:ml_trading SET
    title = "ML for Trading Specialization",
    issuer = "Coursera",
    date = "2020-10";

CREATE certification:adv_data_science_ibm SET
    title = "Advanced Data Science with IBM",
    issuer = "Coursera",
    date = "2020-05";

CREATE certification:ml_tensorflow_gcp SET
    title = "ML with TensorFlow on Google Cloud",
    issuer = "Coursera",
    date = "2020-03";

CREATE certification:adv_ml_tensorflow_gcp SET
    title = "Adv. ML with TensorFlow on Google Cloud",
    issuer = "Coursera",
    date = "2020-03";

CREATE certification:deep_learning SET
    title = "Deep Learning Specialization (Andrew Ng)",
    issuer = "Coursera",
    date = "2020-02";

-- ── Education ───────────────────────────────────────────────────────────────

CREATE education:general_assembly SET
    institution = "General Assembly",
    program = "Data Science Immersive",
    date = "2019-2020",
    description = "Hands-on ML, statistical modeling, and data engineering. Built for the cloud from the start.";

-- ── Fortune Quotes ──────────────────────────────────────────────────────────

CREATE fortune:cache_invalidation SET
    text = "There are only two hard things in Computer Science: cache invalidation and naming things.",
    author = "Phil Karlton";

CREATE fortune:premature_optimization SET
    text = "Premature optimization is the root of all evil.",
    author = "Donald Knuth";

CREATE fortune:simplicity SET
    text = "Simplicity is prerequisite for reliability.",
    author = "Edsger W. Dijkstra";

CREATE fortune:debugging SET
    text = "Debugging is twice as hard as writing the code in the first place. Therefore, if you write the code as cleverly as possible, you are, by definition, not smart enough to debug it.",
    author = "Brian Kernighan";

CREATE fortune:measuring SET
    text = "Measuring programming progress by lines of code is like measuring aircraft building progress by weight.",
    author = "Bill Gates";

CREATE fortune:unix SET
    text = "Unix is simple. It just takes a genius to understand its simplicity.",
    author = "Dennis Ritchie";

CREATE fortune:types SET
    text = "A program that produces incorrect results twice as fast is infinitely slower.",
    author = "John Osterhout";

CREATE fortune:abstraction SET
    text = "All problems in computer science can be solved by another level of indirection... except for the problem of too many layers of indirection.",
    author = "David Wheeler";

CREATE fortune:legacy_code SET
    text = "Legacy code is code without tests.",
    author = "Michael Feathers";

CREATE fortune:shipping SET
    text = "Real artists ship.",
    author = "Steve Jobs";

-- ============================================================================
-- RELATE statements — connecting records
-- ============================================================================

-- ── Project USES_SKILL relations ────────────────────────────────────────────

-- DockerScraper: Python, Docker, PostgreSQL
RELATE project:docker_scraper -> uses_skill -> skill:python SET role = "primary";
RELATE project:docker_scraper -> uses_skill -> skill:docker SET role = "primary";
RELATE project:docker_scraper -> uses_skill -> skill:postgresql SET role = "primary";

-- RoamChat: Python, API Design
RELATE project:roam_chat -> uses_skill -> skill:python SET role = "primary";
RELATE project:roam_chat -> uses_skill -> skill:api_design SET role = "primary";

-- Nicular Cloud Platform: GCP, Kubernetes, Cloud Run
RELATE project:nicular_cloud -> uses_skill -> skill:gcp SET role = "primary";
RELATE project:nicular_cloud -> uses_skill -> skill:kubernetes SET role = "primary";
RELATE project:nicular_cloud -> uses_skill -> skill:cloud_run SET role = "primary";
RELATE project:nicular_cloud -> uses_skill -> skill:docker SET role = "secondary";

-- Marketing Intelligence: Python, SQL, ML
RELATE project:marketing_intelligence -> uses_skill -> skill:python SET role = "primary";
RELATE project:marketing_intelligence -> uses_skill -> skill:sql SET role = "primary";
RELATE project:marketing_intelligence -> uses_skill -> skill:ml SET role = "primary";

-- Crypto ML Pipeline: Python, ML, Docker
RELATE project:crypto_ml_pipeline -> uses_skill -> skill:python SET role = "primary";
RELATE project:crypto_ml_pipeline -> uses_skill -> skill:ml SET role = "primary";
RELATE project:crypto_ml_pipeline -> uses_skill -> skill:docker SET role = "primary";

-- leptos-cv: Rust, Leptos, WASM
RELATE project:leptos_cv -> uses_skill -> skill:rust SET role = "primary";
RELATE project:leptos_cv -> uses_skill -> skill:leptos SET role = "primary";
RELATE project:leptos_cv -> uses_skill -> skill:wasm SET role = "primary";

-- ── Experience PRODUCED project relations ───────────────────────────────────

RELATE experience:nicular -> produced -> project:nicular_cloud;
RELATE experience:johnson_group -> produced -> project:marketing_intelligence;
RELATE experience:general_assembly -> produced -> project:crypto_ml_pipeline;

-- ── Experience REQUIRED skill relations ─────────────────────────────────────

-- Nicular: GCP, Docker, Kubernetes, Cloud Run, Python, Go
RELATE experience:nicular -> required -> skill:gcp;
RELATE experience:nicular -> required -> skill:docker;
RELATE experience:nicular -> required -> skill:kubernetes;
RELATE experience:nicular -> required -> skill:cloud_run;
RELATE experience:nicular -> required -> skill:python;
RELATE experience:nicular -> required -> skill:go;

-- Johnson Group: Python, SQL, ML, Data Engineering
RELATE experience:johnson_group -> required -> skill:python;
RELATE experience:johnson_group -> required -> skill:sql;
RELATE experience:johnson_group -> required -> skill:ml;
RELATE experience:johnson_group -> required -> skill:data_engineering;

-- Yawye: SQL, PostgreSQL, Metabase
RELATE experience:yawye -> required -> skill:sql;
RELATE experience:yawye -> required -> skill:postgresql;
RELATE experience:yawye -> required -> skill:metabase;

-- General Assembly: Python, ML, SQL, Data Engineering
RELATE experience:general_assembly -> required -> skill:python;
RELATE experience:general_assembly -> required -> skill:ml;
RELATE experience:general_assembly -> required -> skill:sql;
RELATE experience:general_assembly -> required -> skill:data_engineering;

-- ── Certification VALIDATES skill relations ─────────────────────────────────

RELATE certification:ml_trading -> validates -> skill:ml;
RELATE certification:ml_trading -> validates -> skill:python;

RELATE certification:adv_data_science_ibm -> validates -> skill:ml;
RELATE certification:adv_data_science_ibm -> validates -> skill:data_engineering;

RELATE certification:ml_tensorflow_gcp -> validates -> skill:ml;
RELATE certification:ml_tensorflow_gcp -> validates -> skill:tensorflow;
RELATE certification:ml_tensorflow_gcp -> validates -> skill:gcp;

RELATE certification:adv_ml_tensorflow_gcp -> validates -> skill:ml;
RELATE certification:adv_ml_tensorflow_gcp -> validates -> skill:tensorflow;
RELATE certification:adv_ml_tensorflow_gcp -> validates -> skill:gcp;

RELATE certification:deep_learning -> validates -> skill:ml;
RELATE certification:deep_learning -> validates -> skill:tensorflow;

-- ── Skill ENABLES skill (dependency chains) ─────────────────────────────────

-- Language foundations enable higher-level skills
RELATE skill:python -> enables -> skill:ml;
RELATE skill:python -> enables -> skill:data_engineering;
RELATE skill:python -> enables -> skill:tensorflow;
RELATE skill:sql -> enables -> skill:postgresql;
RELATE skill:sql -> enables -> skill:data_engineering;
RELATE skill:rust -> enables -> skill:leptos;
RELATE skill:rust -> enables -> skill:wasm;
RELATE skill:leptos -> enables -> skill:wasm;

-- Infra dependency chain
RELATE skill:docker -> enables -> skill:kubernetes;
RELATE skill:docker -> enables -> skill:cloud_run;
RELATE skill:gcp -> enables -> skill:kubernetes;
RELATE skill:gcp -> enables -> skill:cloud_run;

-- ML dependency chain
RELATE skill:ml -> enables -> skill:tensorflow;
