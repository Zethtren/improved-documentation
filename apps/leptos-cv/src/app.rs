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
            description: "I own the cloud. Designed and built the company's entire GCP architecture from the ground up — VPCs, secrets management, client storage, the works. Built internal tooling so the team can ship new services to Cloud Run or GKE without touching infrastructure. Led the migration of legacy GCP-managed apps into Kubernetes, and I review every line of code that goes to production.".into(),
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
                <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet" />
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
                        <span class="titlebar-path">"houston@zethtren.xyz: ~"</span>
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

    view! {
        <nav class="tui-tabs">
            <div class="tui-tabs-left">
                <A href="/">"0:home"</A>
                <A href="/about">"1:about"</A>
                <A href="/portfolio">"2:portfolio"</A>
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
            <span class="tmux-right">"zethtren.xyz"</span>
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

// ── Bat-style file viewer ───────────────────────────────────────────

#[component]
fn BatView(file: &'static str, content: &'static str) -> impl IntoView {
    let lines: Vec<&str> = content.lines().collect();
    let total = lines.len();
    let gutter_width = format!("{}", total).len();

    view! {
        <div class="bat-view">
            <div class="bat-header">
                <span class="bat-header-label">"File: "</span>
                <span class="bat-header-file">{file}</span>
            </div>
            <div class="bat-ruler" />
            <div class="bat-content">
                {lines.into_iter().enumerate().map(|(i, line)| {
                    let num = i + 1;
                    let padded = format!("{:>width$}", num, width = gutter_width);

                    // Simple markdown syntax coloring
                    let colored = if line.starts_with("# ") {
                        view! { <span class="bat-h1">{line}</span> }.into_any()
                    } else if line.starts_with("## ") {
                        view! { <span class="bat-h2">{line}</span> }.into_any()
                    } else if line.starts_with("- ") || line.starts_with("* ") {
                        let bullet = &line[..2];
                        let rest = &line[2..];
                        view! { <span class="bat-bullet">{bullet}</span><span class="bat-text">{rest}</span> }.into_any()
                    } else if line.starts_with("**") || line.starts_with("> ") {
                        view! { <span class="bat-emphasis">{line}</span> }.into_any()
                    } else if line.starts_with("```") {
                        view! { <span class="bat-fence">{line}</span> }.into_any()
                    } else if line.trim().is_empty() {
                        view! { <span>{" "}</span> }.into_any()
                    } else {
                        view! { <span class="bat-text">{line}</span> }.into_any()
                    };

                    view! {
                        <div class="bat-line">
                            <span class="bat-gutter">{padded}</span>
                            <span class="bat-sep">"│"</span>
                            {colored}
                        </div>
                    }
                }).collect_view()}
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
                <A href="/about">"$ bat about.md"</A>
                <A href="/portfolio">"$ ls projects/"</A>
            </div>
        </Section>

        <Section title="quickstats" cmd="fastfetch">
            <div class="fetch">
                <div class="fetch-logo-wrap">
                    <pre class="fetch-logo">{FETCH_LOGO}</pre>
                </div>
                <div class="fetch-info">
                    <div class="fetch-title">"houston"<span class="fetch-at">"@"</span>"zethtren.xyz"</div>
                    <div class="fetch-sep" />
                    <div class="fetch-row"><span class="fetch-key">"Contact"</span>" Houston@Zethtren.xyz"</div>
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
