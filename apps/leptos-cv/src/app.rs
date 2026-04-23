use leptos::prelude::*;
use leptos_meta::*;
use leptos_router::components::*;
use leptos_router::path;

// ── Data Structs ─────────────────────────────────────────────────────

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct SkillData {
    pub name: String,
    pub category: String,
    pub proficiency: i32,
    pub hours: Option<f64>,
    pub years: Option<f64>,
    pub description: Option<String>,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct ProjectData {
    pub title: String,
    pub description: String,
    pub tags: Vec<String>,
    pub source_url: Option<String>,
    pub status: Option<String>,
    pub sort_order: Option<i32>,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct ExperienceData {
    pub title: String,
    pub company: String,
    pub start_date: String,
    pub end_date: Option<String>,
    pub description: String,
    pub current: Option<bool>,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct CertificationData {
    pub title: String,
    pub issuer: String,
    pub date: String,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct BlogPostData {
    pub id: Option<String>,
    pub title: String,
    pub slug: String,
    pub content: String,
    pub published: Option<String>,
    pub tags: Vec<String>,
    pub draft: Option<bool>,
}

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct RecommendedLink {
    pub title: String,
    pub description: Option<String>,
    pub url: String,
    pub source: Option<String>,
}

// ── Server Functions ─────────────────────────────────────────────────

#[server]
pub async fn record_page_view(path: String, referrer: Option<String>) -> Result<(), ServerFnError> {
    let sql = format!(
        "CREATE page_view SET path = '{}', referrer = {}, timestamp = time::now();",
        path.replace('\'', ""),
        referrer
            .map(|r| format!("'{}'", r.replace('\'', "")))
            .unwrap_or("NONE".to_string())
    );
    crate::db::query_surreal(&sql)
        .await
        .map_err(|e| ServerFnError::new(e))?;
    Ok(())
}

#[server]
pub async fn get_skills() -> Result<Vec<SkillData>, ServerFnError> {
    let result = crate::db::query_surreal(
        "SELECT name, category, proficiency, hours, years, description FROM skill ORDER BY proficiency DESC;",
    )
    .await
    .map_err(|e| ServerFnError::new(e))?;

    let skills: Vec<SkillData> =
        serde_json::from_value(result).map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(skills)
}

#[server]
pub async fn get_projects() -> Result<Vec<ProjectData>, ServerFnError> {
    let result = crate::db::query_surreal(
        "SELECT title, description, tags, source_url, status, sort_order FROM project WHERE visible = true ORDER BY sort_order ASC;",
    )
    .await
    .map_err(|e| ServerFnError::new(e))?;

    let projects: Vec<ProjectData> =
        serde_json::from_value(result).map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(projects)
}

#[server]
pub async fn get_experience() -> Result<Vec<ExperienceData>, ServerFnError> {
    let result = crate::db::query_surreal(
        "SELECT title, company, start_date, end_date, description, current FROM experience ORDER BY start_date DESC;",
    )
    .await
    .map_err(|e| ServerFnError::new(e))?;

    let experience: Vec<ExperienceData> =
        serde_json::from_value(result).map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(experience)
}

#[server]
pub async fn get_certifications() -> Result<Vec<CertificationData>, ServerFnError> {
    let result = crate::db::query_surreal(
        "SELECT title, issuer, date FROM certification ORDER BY date DESC;",
    )
    .await
    .map_err(|e| ServerFnError::new(e))?;

    let certs: Vec<CertificationData> =
        serde_json::from_value(result).map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(certs)
}

#[server]
pub async fn get_blog_posts() -> Result<Vec<BlogPostData>, ServerFnError> {
    let result = crate::db::query_surreal(
        "SELECT * FROM blog_post WHERE draft = false ORDER BY published DESC;",
    )
    .await
    .map_err(|e| ServerFnError::new(e))?;

    let posts: Vec<BlogPostData> =
        serde_json::from_value(result).map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(posts)
}

#[server]
pub async fn get_blog_post(slug: String) -> Result<Option<BlogPostData>, ServerFnError> {
    let result = crate::db::query_surreal(&format!(
        "SELECT * FROM blog_post WHERE slug = '{}' AND draft = false LIMIT 1;",
        slug.replace('\'', "")
    ))
    .await
    .map_err(|e| ServerFnError::new(e))?;

    let posts: Vec<BlogPostData> =
        serde_json::from_value(result).map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(posts.into_iter().next())
}

#[server]
pub async fn get_recommendations(blog_post_id: String) -> Result<Vec<RecommendedLink>, ServerFnError> {
    let result = crate::db::query_surreal(
        &format!("SELECT * FROM recommended_link WHERE blog_post_id = '{}' ORDER BY relevance_score DESC;",
            blog_post_id.replace('\'', ""))
    ).await.map_err(|e| ServerFnError::new(e))?;
    let links: Vec<RecommendedLink> = serde_json::from_value(result)
        .map_err(|e| ServerFnError::new(e.to_string()))?;
    Ok(links)
}

// ── Fallback Data ────────────────────────────────────────────────────

fn fallback_projects() -> Vec<ProjectData> {
    vec![
        ProjectData {
            title: "DockerScraper".into(),
            description: "Spins up containers that scrape live crypto ticker data and pipe it straight into Postgres — ready for ML models to chew on.".into(),
            tags: vec!["Python".into(), "Docker".into(), "PostgreSQL".into()],
            source_url: Some("https://github.com/Zethtren/DockerScraper".into()),
            status: None,
            sort_order: Some(1),
        },
        ProjectData {
            title: "RoamChat".into(),
            description: "Unofficial API for Roam Chat. Send messages, handle failures gracefully, and wrap it all in a clean decorator pattern. Open-sourced because APIs should just work.".into(),
            tags: vec!["Python".into(), "API".into(), "Open Source".into()],
            source_url: Some("https://github.com/Zethtren/RoamUnofficial".into()),
            status: None,
            sort_order: Some(2),
        },
        ProjectData {
            title: "Nicular Cloud Platform".into(),
            description: "Built an entire production GCP environment from scratch — VPCs, secrets, storage, deploy pipelines. The team ships to Cloud Run and GKE without touching infra.".into(),
            tags: vec!["GCP".into(), "Kubernetes".into(), "Cloud Run".into()],
            source_url: None,
            status: None,
            sort_order: Some(3),
        },
        ProjectData {
            title: "Marketing Intelligence".into(),
            description: "Replaced 4+ hours of daily manual reporting with 15-minute automated pipelines. Added predictive baselines and geographic lead tracking that clients actually used.".into(),
            tags: vec!["Python".into(), "SQL".into(), "ML".into()],
            source_url: None,
            status: None,
            sort_order: Some(4),
        },
        ProjectData {
            title: "Crypto ML Pipeline".into(),
            description: "End-to-end machine learning pipeline for crypto market analysis. Ingests live data, trains models, and surfaces predictions — all containerized and cloud-native.".into(),
            tags: vec!["Python".into(), "ML".into(), "Docker".into()],
            source_url: None,
            status: None,
            sort_order: Some(5),
        },
        ProjectData {
            title: "leptos-cv".into(),
            description: "You're looking at it. A terminal-themed CV compiled to WASM with Leptos, styled in Catppuccin, because resumes should have a theme switcher.".into(),
            tags: vec!["Rust".into(), "Leptos".into(), "WASM".into()],
            source_url: Some("https://github.com/Zethtren/leptos-cv".into()),
            status: None,
            sort_order: Some(6),
        },
    ]
}

fn fallback_experience() -> Vec<ExperienceData> {
    vec![
        ExperienceData {
            title: "Lead Developer".into(),
            company: "Nicular LLC".into(),
            start_date: "Jul 2022".into(),
            end_date: None,
            description: "Lead dev on the cloud side. Helped design and build much of the company's GCP architecture — VPCs, secrets management, client storage, and the supporting bits — and built internal tooling so the team can ship services to Cloud Run or GKE without wrestling with infra. Helped drive the migration of legacy GCP-managed apps into Kubernetes, and review a lot of what goes to production.".into(),
            current: Some(true),
        },
        ExperienceData {
            title: "Data Scientist / Analyst".into(),
            company: "Johnson Group Marketing".into(),
            start_date: "Feb 2021".into(),
            end_date: Some("Apr 2022".into()),
            description: "Turned a daily reporting grind — 4+ hours of manual spreadsheet work — into a set of scripts that ran in 15 minutes. Built predictive models to establish baseline marketing performance, and created geographic tracking tools that fed hiring leads and market opportunities directly to clients.".into(),
            current: Some(false),
        },
        ExperienceData {
            title: "QA Analyst".into(),
            company: "Yawye (Start-up)".into(),
            start_date: "May 2020".into(),
            end_date: Some("May 2020".into()),
            description: "Short contract, big migration. Moved the startup's analytics layer from MongoDB to PostgreSQL, built Metabase dashboards for data quality monitoring, and helped define what data was actually worth collecting in the first place.".into(),
            current: Some(false),
        },
        ExperienceData {
            title: "Data Scientist".into(),
            company: "General Assembly".into(),
            start_date: "Dec 2019".into(),
            end_date: Some("Mar 2020".into()),
            description: "Where it all started. Immersive program focused on building real things — ML models, data pipelines, SQL-driven analytics — with a personal obsession for writing readable, portable code. Built tools designed to run on distributed cloud architectures from day one.".into(),
            current: Some(false),
        },
    ]
}

fn fallback_certifications() -> Vec<CertificationData> {
    vec![
        CertificationData {
            title: "ML for Trading Specialization".into(),
            issuer: "Coursera".into(),
            date: "Oct 2020".into(),
        },
        CertificationData {
            title: "Advanced Data Science with IBM".into(),
            issuer: "Coursera".into(),
            date: "May 2020".into(),
        },
        CertificationData {
            title: "ML with TensorFlow on Google Cloud".into(),
            issuer: "Coursera".into(),
            date: "Mar 2020".into(),
        },
        CertificationData {
            title: "Adv. ML with TensorFlow on Google Cloud".into(),
            issuer: "Coursera".into(),
            date: "Mar 2020".into(),
        },
        CertificationData {
            title: "Deep Learning Specialization (Andrew Ng)".into(),
            issuer: "Coursera".into(),
            date: "Feb 2020".into(),
        },
    ]
}

fn fallback_skills() -> Vec<SkillData> {
    vec![
        SkillData {
            name: "Python".into(),
            category: "Language".into(),
            proficiency: 95,
            hours: None,
            years: None,
            description: Some("pipelines, ML, the glue that holds everything together".into()),
        },
        SkillData {
            name: "Rust".into(),
            category: "Language".into(),
            proficiency: 85,
            hours: None,
            years: None,
            description: Some("systems code, WASM, the reason I have strong opinions about lifetimes".into()),
        },
        SkillData {
            name: "Go".into(),
            category: "Language".into(),
            proficiency: 80,
            hours: None,
            years: None,
            description: Some("services, CLI tools, concurrency that doesn't hurt".into()),
        },
        SkillData {
            name: "SQL".into(),
            category: "Language".into(),
            proficiency: 90,
            hours: None,
            years: None,
            description: Some("PostgreSQL, analytics, the query that probably needs an index".into()),
        },
        SkillData {
            name: "GCP".into(),
            category: "Infra".into(),
            proficiency: 90,
            hours: None,
            years: None,
            description: Some("Cloud Run, GKE, VPCs, Secrets, Storage (most of the acronyms)".into()),
        },
        SkillData {
            name: "Docker & K8s".into(),
            category: "Infra".into(),
            proficiency: 88,
            hours: None,
            years: None,
            description: Some("containerize it, orchestrate it, ship it".into()),
        },
    ]
}

// ── Shell (HTML document wrapper for SSR) ────────────────────────────

pub fn shell(options: LeptosOptions) -> impl IntoView {
    view! {
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>"~/houston — Houston Kelly Bova"</title>
                <AutoReload options=options.clone() />
                <HydrationScripts options />
                <MetaTags />
                <Stylesheet href="/pkg/leptos-cv.css" />
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/mshaugh/nerdfont-webfonts@v3.3.0/build/nerdfont-webfonts.min.css" />
                <link rel="preconnect" href="https://fonts.googleapis.com" />
                <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="" />
                <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=Victor+Mono:ital,wght@0,400;1,400&display=swap" rel="stylesheet" />
                <link href="https://cdn.jsdelivr.net/gh/ryanoasis/nerd-fonts@v3.3.0/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf" />
                <style>{"
                    @font-face {
                        font-family: 'JetBrainsMono NF';
                        src: url('https://cdn.jsdelivr.net/gh/ryanoasis/nerd-fonts@v3.3.0/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf') format('truetype');
                        font-weight: 400;
                        font-style: normal;
                        font-display: swap;
                    }
                "}</style>
            </head>
            <body>
                <App />
            </body>
        </html>
    }
}

// ── Theme persistence helpers ────────────────────────────────────────
// These use web_sys which only exists on the client (wasm32) side.

#[cfg(target_arch = "wasm32")]
fn stored_theme() -> String {
    web_sys::window()
        .and_then(|w| w.local_storage().ok().flatten())
        .and_then(|s| s.get_item("ctp-theme").ok().flatten())
        .unwrap_or_else(|| "mocha".into())
}

#[cfg(not(target_arch = "wasm32"))]
fn stored_theme() -> String {
    "mocha".into()
}

#[cfg(target_arch = "wasm32")]
fn save_theme(name: &str) {
    if let Some(storage) = web_sys::window()
        .and_then(|w| w.local_storage().ok().flatten())
    {
        let _ = storage.set_item("ctp-theme", name);
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn save_theme(_name: &str) {}

#[cfg(target_arch = "wasm32")]
fn apply_theme(name: &str) {
    if let Some(doc) = web_sys::window().and_then(|w| w.document()) {
        if let Some(el) = doc.document_element() {
            let _ = el.set_attribute("data-theme", name);
        }
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn apply_theme(_name: &str) {}

// ── Page View Tracker ────────────────────────────────────────────────

#[component]
fn PageTracker() -> impl IntoView {
    #[cfg(feature = "hydrate")]
    {
        use leptos::prelude::*;
        let location = leptos_router::hooks::use_location();
        let path = move || location.pathname.get();

        // Fire on every path change
        Effect::new(move |_| {
            let p = path();
            leptos::task::spawn_local(async move {
                let _ = record_page_view(p, None).await;
            });
        });
    }
    view! {}
}

// ── Root App ─────────────────────────────────────────────────────────

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    let initial = stored_theme();
    let (theme, set_theme) = signal(initial.clone());
    apply_theme(&initial);

    view! {
        <Router>
            <div class="crt-screen">
                <div class="terminal-window terminal-main">
                    <div class="terminal-titlebar">
                        <span class="terminal-dot red" />
                        <span class="terminal-dot yellow" />
                        <span class="terminal-dot green" />
                        <span class="titlebar-path">"contact@houstonbova.com: ~"</span>
                    </div>
                    <div class="terminal-body terminal-main-body">
                        <Nav theme=theme writer=set_theme />
                        <pre class="hero-ascii" role="img" aria-label="HOUSTON in block letters">{ASCII_ART}</pre>
                        <PageTracker />
                        <div class="terminal-content">
                            <Routes fallback=|| view! { <p class="prompt">"404 — not found"</p> }>
                                <Route path=path!("/") view=Home />
                                <Route path=path!("/about") view=About />
                                <Route path=path!("/portfolio") view=Portfolio />
                                <Route path=path!("/blog") view=Blog />
                                <Route path=path!("/blog/:slug") view=BlogPost />
                            </Routes>
                        </div>
                        <StatusBar />
                    </div>
                </div>
            </div>
        </Router>
    }
}

// ── Navigation (tmux-style tab bar) ─────────────────────────────────

#[component]
fn Nav(
    theme: ReadSignal<String>,
    writer: WriteSignal<String>,
) -> impl IntoView {
    let flavors: [&'static str; 4] = ["latte", "frappe", "macchiato", "mocha"];

    let location = leptos_router::hooks::use_location();
    let path = move || location.pathname.get();

    let tab_class = move |href: &'static str| {
        let p = path();
        if (href == "/" && p == "/") || (href != "/" && p.starts_with(href)) {
            "tui-tab active"
        } else {
            "tui-tab"
        }
    };

    view! {
        <nav class="tui-tabs">
            <div class="tui-tabs-left">
                <a href="/" class=move || tab_class("/")>"0:home"</a>
                <a href="/about" class=move || tab_class("/about")>"1:about"</a>
                <a href="/portfolio" class=move || tab_class("/portfolio")>"2:portfolio"</a>
                <a href="/blog" class=move || tab_class("/blog")>"3:blog"</a>
            </div>
            <div class="tui-tabs-right">
                <div class="theme-switcher">
                    <span class="theme-label">"theme:"</span>
                    {flavors
                        .into_iter()
                        .map(|f| {
                            let is_active = {
                                let theme = theme.clone();
                                move || if theme.get() == f { " active" } else { "" }
                            };
                            view! {
                                <button
                                    class=move || format!("theme-btn{}", is_active())
                                    data-flavor=f
                                    title=f
                                    on:click=move |_| {
                                        writer.set(f.to_string());
                                        save_theme(f);
                                        apply_theme(f);
                                    }
                                />
                            }
                        })
                        .collect_view()}
                </div>
            </div>
        </nav>
    }
}

// ── Status Bar (tmux-style bottom bar) ──────────────────────────────

#[component]
fn StatusBar() -> impl IntoView {
    view! {
        <div class="tmux-bar">
            <span class="tmux-left">"[houston]"</span>
            <span class="tmux-center">"Built with Leptos · Styled with Catppuccin"</span>
            <span class="tmux-right">"houstonbova.com"</span>
        </div>
    }
}

// ── Section Divider (replaces nested TerminalWindow) ────────────────

#[component]
fn Section(title: &'static str, #[prop(optional)] cmd: Option<&'static str>, children: Children) -> impl IntoView {
    view! {
        <div class="tui-section">
            <div class="tui-section-header">
                <span class="tui-section-title">{title}</span>
            </div>
            {cmd.map(|c| view! {
                <p class="prompt">{c}</p>
                <br />
            })}
            {children()}
        </div>
    }
}

// ── Code syntax highlighting (regex-based, Catppuccin tokens) ───────

fn highlight_code_line(line: &str) -> String {
    let mut result = String::new();
    let chars: Vec<char> = line.chars().collect();
    let len = chars.len();
    let mut i = 0;

    while i < len {
        // String literals (double quotes)
        if chars[i] == '"' {
            let mut s = String::from("\"");
            i += 1;
            while i < len && chars[i] != '"' {
                if chars[i] == '\\' && i + 1 < len {
                    s.push(chars[i]);
                    s.push(chars[i + 1]);
                    i += 2;
                } else {
                    s.push(chars[i]);
                    i += 1;
                }
            }
            if i < len { s.push('"'); i += 1; }
            result.push_str(&format!("<span class=\"syn-str\">{}</span>", html_escape(&s)));
            continue;
        }

        // Atoms/symbols (:word)
        if chars[i] == ':' && i + 1 < len && chars[i + 1].is_alphabetic() {
            let mut s = String::from(":");
            i += 1;
            while i < len && (chars[i].is_alphanumeric() || chars[i] == '_') {
                s.push(chars[i]);
                i += 1;
            }
            result.push_str(&format!("<span class=\"syn-atom\">{}</span>", html_escape(&s)));
            continue;
        }

        // Numbers
        if chars[i].is_ascii_digit() {
            let mut s = String::new();
            while i < len && (chars[i].is_ascii_digit() || chars[i] == '.' || chars[i] == '_') {
                s.push(chars[i]);
                i += 1;
            }
            result.push_str(&format!("<span class=\"syn-num\">{}</span>", html_escape(&s)));
            continue;
        }

        // Words (keywords, functions, etc.)
        if chars[i].is_alphabetic() || chars[i] == '_' || chars[i] == '@' {
            let mut word = String::new();
            while i < len && (chars[i].is_alphanumeric() || chars[i] == '_' || chars[i] == '!' || chars[i] == '?' || chars[i] == '@') {
                word.push(chars[i]);
                i += 1;
            }
            let class = match word.as_str() {
                // Keywords (mauve)
                "def" | "defp" | "defmodule" | "defmacro" | "defstruct" | "defimpl" | "defprotocol"
                | "do" | "end" | "if" | "else" | "unless" | "case" | "cond" | "when" | "with"
                | "fn" | "for" | "in" | "not" | "and" | "or" | "true" | "false" | "nil"
                | "import" | "use" | "alias" | "require" | "raise" | "rescue" | "try" | "catch" | "after"
                | "receive" | "send" | "spawn" | "self"
                // Rust keywords
                | "let" | "mut" | "const" | "static" | "pub" | "mod" | "struct" | "enum" | "impl"
                | "trait" | "type" | "where" | "async" | "await" | "move" | "return" | "match"
                | "loop" | "while" | "break" | "continue" | "unsafe" | "ref" | "as"
                // Python keywords
                | "class" | "lambda" | "yield" | "from" | "pass" | "global" | "nonlocal"
                | "assert" | "del" | "exec" | "print" | "is" | "elif" | "except" | "finally"
                // Go keywords
                | "func" | "package" | "var" | "range" | "defer" | "go" | "chan" | "select"
                | "interface" | "map" | "make" | "new" | "append" | "len" | "cap"
                // JS/TS
                | "function" | "export" | "default" | "typeof" | "instanceof" | "void"
                | "throw" | "extends" | "super" | "this" | "null" | "undefined"
                // SQL
                | "SELECT" | "FROM" | "WHERE" | "INSERT" | "UPDATE" | "DELETE" | "CREATE"
                | "TABLE" | "INTO" | "VALUES" | "SET" | "ORDER" | "BY" | "GROUP" | "HAVING"
                | "JOIN" | "LEFT" | "RIGHT" | "INNER" | "OUTER" | "ON" | "AS" | "LIMIT"
                | "DEFINE" | "FIELD" | "TYPE" | "INDEX" | "UNIQUE" | "DEFAULT" | "RELATE"
                => "syn-kw",
                // Built-in types (yellow)
                "String" | "Integer" | "Float" | "List" | "Map" | "Tuple" | "Atom" | "Keyword"
                | "GenServer" | "Supervisor" | "Agent" | "Task" | "Enum" | "Stream"
                | "Ok" | "Err" | "Some" | "None" | "Result" | "Option" | "Vec" | "Box" | "Arc" | "Rc"
                | "i32" | "i64" | "u32" | "u64" | "f32" | "f64" | "usize" | "bool" | "str"
                => "syn-type",
                // Module-like (starts with uppercase)
                _ if word.starts_with(|c: char| c.is_uppercase()) => "syn-type",
                // @-prefixed (decorators/module attributes)
                _ if word.starts_with('@') => "syn-attr",
                _ => "",
            };
            if class.is_empty() {
                result.push_str(&html_escape(&word));
            } else {
                result.push_str(&format!("<span class=\"{}\">{}</span>", class, html_escape(&word)));
            }
            continue;
        }

        // Operators
        if "|>=<+-*/%&!^~".contains(chars[i]) {
            let mut op = String::new();
            while i < len && "|>=<+-*/%&!^~".contains(chars[i]) {
                op.push(chars[i]);
                i += 1;
            }
            result.push_str(&format!("<span class=\"syn-op\">{}</span>", html_escape(&op)));
            continue;
        }

        // Everything else
        result.push(chars[i]);
        i += 1;
    }

    result
}

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

// ── Bat-style file viewer ───────────────────────────────────────────

fn render_bat_lines(lines: &[&str]) -> Vec<AnyView> {
    let total = lines.len();
    let gutter_width = format!("{}", total).len();
    let mut in_code_block = false;
    let mut result: Vec<AnyView> = Vec::new();

    for (i, line) in lines.iter().enumerate() {
        let num = i + 1;
        let padded = format!("{:>width$}", num, width = gutter_width);

        // Detect code fence boundaries
        if line.starts_with("```") {
            if !in_code_block {
                in_code_block = true;
                let lang = line.trim_start_matches('`').trim().to_string();
                let label = if lang.is_empty() { "code".to_string() } else { lang };
                // Nerd Font Unicode icons for languages
                let icon = match label.as_str() {
                    "rust" => "\u{e7a8}",      //
                    "elixir" => "\u{e62d}",    //
                    "python" | "py" => "\u{e73c}", //
                    "javascript" | "js" => "\u{e74e}", //
                    "typescript" | "ts" => "\u{e628}", //
                    "go" | "golang" => "\u{e626}",     //
                    "ruby" | "rb" => "\u{e791}",       //
                    "bash" | "sh" | "shell" | "zsh" => "\u{e795}", //
                    "sql" => "\u{e706}",       //
                    "docker" | "dockerfile" => "\u{e7b0}", //
                    "html" => "\u{e736}",      //
                    "css" => "\u{e749}",        //
                    "yaml" | "yml" => "\u{e6a8}", //
                    "toml" => "\u{e6b2}",      //
                    "json" => "\u{e60b}",      //
                    _ => "\u{e7a8}",           // default: code
                };
                result.push(view! {
                    <div class="bat-line bat-line-fence-open">
                        <span class="bat-gutter">{padded}</span>
                        <span class="bat-sep">"│"</span>
                        <span class="bat-fence-open">
                            <span class="bat-lang-icon">{icon}</span>
                            " "
                            <span class="bat-fence-lang-label">{label}</span>
                        </span>
                    </div>
                }.into_any());
            } else {
                in_code_block = false;
                result.push(view! {
                    <div class="bat-line bat-line-fence-close">
                        <span class="bat-gutter">{padded}</span>
                        <span class="bat-sep">"│"</span>
                    </div>
                }.into_any());
            }
            continue;
        }

        if in_code_block {
            let trimmed = line.trim();
            let is_comment = trimmed.starts_with("//") || trimmed.starts_with("--")
                || (trimmed.starts_with('#') && !trimmed.starts_with("#!") && !trimmed.starts_with("#["));
            if is_comment {
                result.push(view! {
                    <div class="bat-line bat-line-code">
                        <span class="bat-gutter">{padded}</span>
                        <span class="bat-sep">"│"</span>
                        <span class="bat-code-comment">{line.to_string()}</span>
                    </div>
                }.into_any());
            } else {
                let highlighted = highlight_code_line(line);
                result.push(view! {
                    <div class="bat-line bat-line-code">
                        <span class="bat-gutter">{padded}</span>
                        <span class="bat-sep">"│"</span>
                        <span class="bat-code" inner_html=highlighted />
                    </div>
                }.into_any());
            }
            continue;
        }

        // Regular markdown
        let colored = if line.starts_with("# ") {
            view! { <span class="bat-h1">{line.to_string()}</span> }.into_any()
        } else if line.starts_with("## ") || line.starts_with("### ") {
            view! { <span class="bat-h2">{line.to_string()}</span> }.into_any()
        } else if line.starts_with("- ") || line.starts_with("* ") {
            let bullet = &line[..2];
            let rest = &line[2..];
            view! { <span class="bat-bullet">{bullet.to_string()}</span><span class="bat-text">{rest.to_string()}</span> }.into_any()
        } else if line.starts_with("> ") {
            view! { <span class="bat-emphasis">{line.to_string()}</span> }.into_any()
        } else if line.starts_with("**") {
            view! { <span class="bat-emphasis">{line.to_string()}</span> }.into_any()
        } else if line.trim().is_empty() {
            view! { <span>{" "}</span> }.into_any()
        } else {
            view! { <span class="bat-text">{line.to_string()}</span> }.into_any()
        };

        result.push(view! {
            <div class="bat-line">
                <span class="bat-gutter">{padded}</span>
                <span class="bat-sep">"│"</span>
                {colored}
            </div>
        }.into_any());
    }

    result
}

#[component]
fn BatView(file: &'static str, content: &'static str) -> impl IntoView {
    let lines: Vec<&str> = content.lines().collect();

    view! {
        <div class="bat-view">
            <div class="bat-header">
                <span class="bat-header-label">"File: "</span>
                <span class="bat-header-file">{file}</span>
            </div>
            <div class="bat-ruler" />
            <div class="bat-content">
                {render_bat_lines(&lines)}
            </div>
            <div class="bat-ruler" />
        </div>
    }
}

/// Dynamic bat viewer for runtime content (blog posts)
#[component]
pub fn DynBatView(
    #[prop(into)] file: String,
    #[prop(into)] content: String,
) -> impl IntoView {
    let lines: Vec<&str> = content.lines().collect();

    view! {
        <div class="bat-view">
            <div class="bat-header">
                <span class="bat-header-label">"File: "</span>
                <span class="bat-header-file">{file.clone()}</span>
            </div>
            <div class="bat-ruler" />
            <div class="bat-content">
                {render_bat_lines(&lines)}
            </div>
            <div class="bat-ruler" />
        </div>
    }
}

// ── Home / Landing ───────────────────────────────────────────────────

#[component]
fn Home() -> impl IntoView {
    view! {
        <Section title="welcome" cmd="bat README.md">
            <BatView file="README.md" content=
"# Houston Kelly Bova

> Lead Developer & Cloud Architect

I build infrastructure that stays up and tools
that don't get in the way.

## Quick Links

- **about** — $ bat about.md
- **portfolio** — $ ls projects/" />
            <br />
            <div class="hero-links">
                <a href="/about">"$ bat about.md"</a>
                <a href="/portfolio">"$ ls projects/"</a>
            </div>
        </Section>

        <Section title="quickstats" cmd="fastfetch">
            <div class="fetch">
                <div class="fetch-logo-wrap">
                    <pre class="fetch-logo">{FETCH_LOGO}</pre>
                </div>
                <div class="fetch-info">
                    <div class="fetch-title">"contact"<span class="fetch-at">"@"</span>"houstonbova.com"</div>
                    <div class="fetch-sep" />
                    <div class="fetch-row"><span class="fetch-key">"Contact"</span>" contact@houstonbova.com"</div>
                    <div class="fetch-row"><span class="fetch-key">"Languages"</span>" Python, Rust, Go, SQL"</div>
                    <div class="fetch-row"><span class="fetch-key">"Infra"</span>" GCP, Docker, Kubernetes"</div>
                    <div class="fetch-row"><span class="fetch-key">"GitHub"</span>" "<a href="https://github.com/Zethtren" target="_blank">"github.com/Zethtren"</a></div>
                    <div class="fetch-row"><span class="fetch-key">"Focus"</span>" Cloud Architecture, Data Eng"</div>
                    <div class="fetch-row"><span class="fetch-key">"Status"</span>" Open to opportunities"</div>
                    <br />
                    <div class="fetch-colors">
                        <span class="fc fc-0" />
                        <span class="fc fc-1" />
                        <span class="fc fc-2" />
                        <span class="fc fc-3" />
                        <span class="fc fc-4" />
                        <span class="fc fc-5" />
                        <span class="fc fc-6" />
                        <span class="fc fc-7" />
                    </div>
                </div>
            </div>
        </Section>

        <Section title="whoami" cmd="bat ~/.profile">
            <BatView file="~/.profile" content=
"# whoami

Lead developer, cloud architect, and recovering
data scientist.

## Day-to-Day

- Designing GCP infrastructure
- Migrating things into Kubernetes
- Writing deploy tooling that makes life less painful

## Origin Story

> Previously, I turned 4-hour reporting jobs into
> 15-minute scripts — and I've been chasing that
> feeling ever since." />
        </Section>

        <Section title="terminal">
            <crate::terminal::InteractiveTerminal />
        </Section>
    }
}

// ── About ────────────────────────────────────────────────────────────

#[component]
fn About() -> impl IntoView {
    let skills = Resource::new(|| (), |_| get_skills());
    let certifications = Resource::new(|| (), |_| get_certifications());
    let experience = Resource::new(|| (), |_| get_experience());

    view! {
        <Section title="about" cmd="bat about.md">
            <BatView file="about.md" content=
"# About

I'm Houston — a lead developer and cloud architect
who ships production infrastructure on GCP and writes
the tooling that makes deploys boring (in the best way).

## Stack

- **Languages** — Python, Rust, Go, SQL
- **Cloud** — GCP, Cloud Run, GKE, Docker, Kubernetes
- **Philosophy** — If a task takes more than 15 minutes
  and happens more than twice, it's getting a script

## Background

> Before all this, I was a data scientist — I still
> nerd out over ML papers and have five Coursera
> specializations to prove it.

When I'm not in a terminal, you'll find me tinkering
with open-source side projects or convincing someone
that Rust is worth the borrow checker." />
        </Section>

        <Section title="skills" cmd="tree ~/.skills/">
            <pre class="tui-text" style="color: var(--ctp-blue); font-weight: 700;">"~/.skills/"</pre>
            <Suspense fallback=move || view! { <p class="prompt">"Loading..."</p> }>
                {move || skills.get().map(|result| {
                    let skills_list = match result {
                        Ok(s) => s,
                        Err(_) => fallback_skills(),
                    };
                    // Group by category
                    let mut categories: Vec<(String, Vec<SkillData>)> = Vec::new();
                    for skill in skills_list {
                        if let Some(cat) = categories.iter_mut().find(|(c, _)| *c == skill.category) {
                            cat.1.push(skill);
                        } else {
                            categories.push((skill.category.clone(), vec![skill]));
                        }
                    }
                    let cat_len = categories.len();
                    view! {
                        <div class="tree-view">
                            {categories.into_iter().enumerate().map(|(ci, (cat, skills))| {
                                let is_last_cat = ci == cat_len - 1;
                                let cat_branch = if is_last_cat { "└── " } else { "├── " };
                                let cat_pipe = if is_last_cat { "    " } else { "│   " };
                                let skill_len = skills.len();
                                view! {
                                    <div class="tree-node">
                                        <span class="tree-branch">{cat_branch}</span>
                                        <span class="tree-dir">{cat.clone()}</span>
                                    </div>
                                    {skills.into_iter().enumerate().map(|(si, s)| {
                                        let is_last_skill = si == skill_len - 1;
                                        let skill_branch = if is_last_skill { "└── " } else { "├── " };
                                        let desc = s.description.map(|d| format!(" — {}", d)).unwrap_or_default();
                                        view! {
                                            <div class="tree-node">
                                                <span class="tree-branch">{cat_pipe}</span>
                                                <span class="tree-leaf">{skill_branch}</span>
                                                <span class="tree-file">{s.name}</span>
                                                <span class="tree-meta">{desc}</span>
                                            </div>
                                        }
                                    }).collect_view()}
                                }
                            }).collect_view()}
                            <pre class="tui-text" style="color: var(--ctp-overlay1); margin-top: 0.25rem;">{format!("\n{} directories", cat_len)}</pre>
                        </div>
                    }
                    .into_any()
                })}
            </Suspense>
        </Section>

        <Section title="certifications" cmd="eza -l --icons ~/certs/">
            <Suspense fallback=move || view! { <p class="prompt">"Loading..."</p> }>
                {move || certifications.get().map(|result| {
                    let certs_list = match result {
                        Ok(c) => c,
                        Err(_) => fallback_certifications(),
                    };
                    view! {
                        <ul class="eza-list">
                            {certs_list
                                .into_iter()
                                .map(|c| {
                                    view! {
                                        <li>
                                            <span class="eza-date">{c.date}</span>
                                            <span class="eza-issuer">{c.issuer}</span>
                                            <span class="eza-name">{c.title}</span>
                                        </li>
                                    }
                                })
                                .collect_view()}
                        </ul>
                    }
                    .into_any()
                })}
            </Suspense>
        </Section>

        <Section title="experience">
            <Suspense fallback=move || view! { <p class="prompt">"Loading..."</p> }>
                {move || experience.get().map(|result| {
                    let exp_list = match result {
                        Ok(e) => e,
                        Err(_) => fallback_experience(),
                    };
                    view! {
                        <div class="timeline">
                            {exp_list
                                .into_iter()
                                .map(|e| {
                                    let date_str = if e.current.unwrap_or(false) {
                                        format!("{} — Present", e.start_date)
                                    } else if let Some(end) = &e.end_date {
                                        format!("{} — {}", e.start_date, end)
                                    } else {
                                        e.start_date.clone()
                                    };
                                    view! {
                                        <div class="timeline-item">
                                            <div class="timeline-date">{date_str}</div>
                                            <div class="timeline-title">{e.title.clone()}</div>
                                            <div class="timeline-subtitle">{e.company.clone()}</div>
                                            <div class="timeline-desc">{e.description.clone()}</div>
                                        </div>
                                    }
                                })
                                .collect_view()}
                        </div>
                    }
                    .into_any()
                })}
            </Suspense>
        </Section>

        <Section title="education" cmd="bat ~/education.log">
            <BatView file="~/education.log" content=
"# Education

## Data Science Immersive
> General Assembly (2019–2020)

- Hands-on ML, statistical modeling, data engineering
- Built for the cloud from the start
- Personal obsession for readable, portable code" />
        </Section>
    }
}

// ── Portfolio ────────────────────────────────────────────────────────

#[component]
fn Portfolio() -> impl IntoView {
    let projects = Resource::new(|| (), |_| get_projects());

    view! {
        <Section title="portfolio" cmd="exa --icons ~/projects/">
            <Suspense fallback=move || view! { <p class="prompt">"Loading..."</p> }>
                {move || projects.get().map(|result| {
                    let project_list = match result {
                        Ok(p) => p,
                        Err(_) => fallback_projects(),
                    };

                    view! {
                        <div class="exa-listing">
                            {project_list.iter().map(|p| {
                                view! {
                                    <span class="exa-item">
                                        <span class="nf nf-custom-folder exa-icon" />
                                        <span class="exa-name">{p.title.clone()}</span>
                                    </span>
                                }
                            }).collect_view()}
                        </div>

                        <div class="tui-grid tui-projects">
                            {project_list
                                .into_iter()
                                .map(|p| {
                                    let has_source = p.source_url.is_some();
                                    let source_url = p.source_url.clone().unwrap_or_default();
                                    view! {
                                        <div class="tui-cell">
                                            <span class="tui-label">{p.title.clone()}</span>
                                            <p class="tui-desc">{p.description.clone()}</p>
                                            <div class="tui-tags">
                                                {p
                                                    .tags
                                                    .iter()
                                                    .map(|t| view! { <span class="tag">{t.clone()}</span> })
                                                    .collect_view()}
                                            </div>
                                            {has_source.then(|| view! {
                                                <div class="tui-links">
                                                    <a href=source_url target="_blank">"source"</a>
                                                </div>
                                            })}
                                        </div>
                                    }
                                })
                                .collect_view()}
                        </div>
                    }
                    .into_any()
                })}
            </Suspense>
        </Section>
    }
}

// ── Blog Listing ─────────────────────────────────────────────────────

#[component]
fn Blog() -> impl IntoView {
    let posts = Resource::new(|| (), |_| get_blog_posts());

    view! {
        <Section title="blog" cmd="eza -l --icons ~/blog/">
            <Suspense fallback=move || view! { <p class="prompt">"Loading..."</p> }>
                {move || posts.get().map(|result| {
                    let post_list = match result {
                        Ok(p) => p,
                        Err(_) => vec![],
                    };

                    if post_list.is_empty() {
                        view! {
                            <p class="prompt">"No published posts yet. Check back soon."</p>
                        }.into_any()
                    } else {
                        view! {
                            <ul class="eza-list">
                                {post_list
                                    .into_iter()
                                    .map(|p| {
                                        let date = p.published.clone().unwrap_or_default();
                                        let date_short = if date.len() >= 10 { &date[..10] } else { &date };
                                        let tags_str = if p.tags.is_empty() {
                                            String::new()
                                        } else {
                                            format!(" [{}]", p.tags.join(", "))
                                        };
                                        let slug = p.slug.clone();
                                        let href = format!("/blog/{}", slug);
                                        view! {
                                            <li>
                                                <span class="eza-date">{date_short.to_string()}</span>
                                                <a href=href class="eza-name">{p.title.clone()}</a>
                                                <span class="eza-issuer">{tags_str}</span>
                                            </li>
                                        }
                                    })
                                    .collect_view()}
                            </ul>
                        }.into_any()
                    }
                })}
            </Suspense>
        </Section>
    }
}

// ── Blog Post Detail ─────────────────────────────────────────────────

#[component]
fn BlogPostRecommendations(post_id: String) -> impl IntoView {
    let recs = Resource::new(move || post_id.clone(), |id| get_recommendations(id));

    view! {
        <Suspense fallback=|| view! {}>
            {move || recs.get().map(|result| {
                match result {
                    Ok(links) if !links.is_empty() => {
                        view! {
                            <div class="recommendations">
                                <p class="rec-header">
                                    "Continued Reading "<span class="rec-tag">"(AI Generated)"</span>
                                </p>
                                {links.into_iter().map(|link| {
                                    let desc = link.description.clone();
                                    view! {
                                        <div class="rec-item">
                                            <a href=link.url target="_blank" rel="noopener" class="rec-title">{link.title}</a>
                                            {desc.map(|d| view! {
                                                <span class="rec-desc">" \u{2014} " {d}</span>
                                            })}
                                        </div>
                                    }
                                }).collect_view()}
                            </div>
                        }.into_any()
                    }
                    _ => view! { <div /> }.into_any()
                }
            })}
        </Suspense>
    }
}

#[component]
fn BlogPost() -> impl IntoView {
    let params = leptos_router::hooks::use_params_map();
    let slug = move || params.get().get("slug").unwrap_or_default();
    let post = Resource::new(slug, |s| get_blog_post(s));

    view! {
        <Suspense fallback=move || view! { <p class="prompt">"Loading..."</p> }>
            {move || post.get().map(|result| {
                match result {
                    Ok(Some(p)) => {
                        let file_name = format!("blog/{}.md", p.slug);
                        let content = p.content.clone();
                        let post_id = p.id.clone().unwrap_or_default();

                        view! {
                            <Section title="blog">
                                <DynBatView file=file_name content=content />
                                <BlogPostRecommendations post_id=post_id />
                                <br />
                                <div class="hero-links">
                                    <a href="/blog">"$ ls blog/"</a>
                                </div>
                            </Section>
                        }.into_any()
                    }
                    Ok(None) => {
                        view! {
                            <Section title="blog">
                                <p class="prompt">"Post not found."</p>
                                <br />
                                <div class="hero-links">
                                    <a href="/blog">"$ ls blog/"</a>
                                </div>
                            </Section>
                        }.into_any()
                    }
                    Err(_) => {
                        view! {
                            <Section title="blog">
                                <p class="prompt">"Error loading post."</p>
                                <br />
                                <div class="hero-links">
                                    <a href="/blog">"$ ls blog/"</a>
                                </div>
                            </Section>
                        }.into_any()
                    }
                }
            })}
        </Suspense>
    }
}

// ── Reusable Terminal Window (kept for compatibility) ────────────────

#[component]
fn TerminalWindow(title: &'static str, children: Children) -> impl IntoView {
    view! {
        <div class="terminal-window">
            <div class="terminal-titlebar">
                <span class="terminal-dot red" />
                <span class="terminal-dot yellow" />
                <span class="terminal-dot green" />
                <span>{title}</span>
            </div>
            <div class="terminal-body">{children()}</div>
        </div>
    }
}

// ── ASCII Art ────────────────────────────────────────────────────────

const FETCH_LOGO: &str = r#"
 ▄▄▄▄▄▄▄▄▄▄▄▄
 █▀▀▀▀▀▀▀▀██▀
           █▀
          █▀
         █▀
    ▄▄▄▄█▀▄▄▄
       █▀
      █▀
     █▀
 ▄▄██▀▀▀▀▀▀▀
 ▀██▄▄▄▄▄▄▄▄▄
  ▀▀▀▀▀▀▀▀▀▀▀"#;

const ASCII_ART: &str = r#"
 ██╗  ██╗ ██████╗ ██╗   ██╗███████╗████████╗ ██████╗ ███╗   ██╗
 ██║  ██║██╔═══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗████╗  ██║
 ███████║██║   ██║██║   ██║███████╗   ██║   ██║   ██║██╔██╗ ██║
 ██╔══██║██║   ██║██║   ██║╚════██║   ██║   ██║   ██║██║╚██╗██║
 ██║  ██║╚██████╔╝╚██████╔╝███████║   ██║   ╚██████╔╝██║ ╚████║
 ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═══╝
"#;
