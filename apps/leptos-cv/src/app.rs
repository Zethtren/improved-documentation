use leptos::prelude::*;
use leptos_meta::*;
use leptos_router::components::*;
use leptos_router::path;

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

// ── Root App ─────────────────────────────────────────────────────────

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    let initial = stored_theme();
    let (theme, set_theme) = signal(initial.clone());
    apply_theme(&initial);

    view! {
        <Router>
            <div class="shell">
                <Nav theme=theme writer=set_theme />
                <Routes fallback=|| view! { <p>"404 — not found"</p> }>
                    <Route path=path!("/") view=Home />
                    <Route path=path!("/about") view=About />
                    <Route path=path!("/portfolio") view=Portfolio />
                </Routes>
                <Footer />
            </div>
        </Router>
    }
}

// ── Navigation ───────────────────────────────────────────────────────

#[component]
fn Nav(
    theme: ReadSignal<String>,
    writer: WriteSignal<String>,
) -> impl IntoView {
    let flavors: [&'static str; 4] = ["latte", "frappe", "macchiato", "mocha"];

    view! {
        <nav class="nav">
            <span class="nav-logo">"~/ houston"</span>
            <div class="nav-links">
                <A href="/">"home"</A>
                <A href="/about">"about"</A>
                <A href="/portfolio">"portfolio"</A>

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

// ── Home / Landing ───────────────────────────────────────────────────

#[component]
fn Home() -> impl IntoView {
    view! {
        <section class="hero">
            <pre class="hero-ascii">{ASCII_ART}</pre>
            <h1>"Hey, I'm "<span class="accent">"Houston"</span></h1>
            <p class="tagline">"I build infrastructure that stays up and tools that don't get in the way."</p>
            <div class="hero-links">
                <A href="/about">"$ cat about.md"</A>
                <A href="/portfolio">"$ ls projects/"</A>
            </div>
        </section>

        <TerminalWindow title="~/ quickstats">
            <p class="prompt">"fastfetch"</p>
            <br />
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
        </TerminalWindow>

        <TerminalWindow title="~/ whoami">
            <p class="prompt">"cat ~/.profile"</p>
            <br />
            <p style="color: var(--ctp-subtext1)">
                "Lead developer, cloud architect, and recovering data scientist. I spend most of my "
                "time designing GCP infrastructure, migrating things into Kubernetes, and writing the "
                "kind of deploy tooling that makes a team's life measurably less painful. "
                "Previously, I turned 4-hour reporting jobs into 15-minute scripts — and I've been "
                "chasing that feeling ever since."
            </p>
            <br />
            <span class="cursor" />
        </TerminalWindow>
    }
}

// ── About ────────────────────────────────────────────────────────────

#[component]
fn About() -> impl IntoView {
    view! {
        <h2 class="section-heading">"about"</h2>

        <div class="about-grid">
            <div class="avatar-frame">
                <img
                    src="https://placehold.co/360x360/313244/cdd6f4?text=%3E_&font=source-code-pro"
                    alt="avatar"
                />
            </div>
            <div class="about-text">
                // Layer 1: Professional identity
                <p>
                    "I'm Houston — a lead developer and cloud architect who ships production "
                    "infrastructure on GCP and writes the tooling that makes deploys boring "
                    "(in the best way). My day-to-day is Python, Rust, and Go, with a heavy "
                    "side of Kubernetes, Cloud Run, and whatever else keeps the lights on."
                </p>
                // Layer 2: Philosophy
                <p>
                    "I care about code that reads well six months later, systems that fail "
                    "gracefully, and automating myself out of repetitive work. If a task takes "
                    "more than 15 minutes and happens more than twice, it's getting a script."
                </p>
                // Layer 3: Human details
                <p>
                    "Before all this, I was a data scientist — I still nerd out over ML papers "
                    "and have five Coursera specializations to prove it. When I'm not in a "
                    "terminal, you'll probably find me tinkering with open-source side projects "
                    "or convincing someone that Rust is worth the borrow checker."
                </p>
            </div>
        </div>

        <TerminalWindow title="~/ skills">
            <p class="prompt">"tree ~/.skills"</p>
            <br />
            <ul class="skill-list">
                <li>"Python — pipelines, ML, the glue that holds everything together"</li>
                <li>"Rust — systems code, WASM, the reason I have strong opinions about lifetimes"</li>
                <li>"Go — services, CLI tools, concurrency that doesn't hurt"</li>
                <li>"SQL — PostgreSQL, analytics, the query that probably needs an index"</li>
                <li>"GCP — Cloud Run, GKE, VPCs, Secrets, Storage (most of the acronyms)"</li>
                <li>"Docker & K8s — containerize it, orchestrate it, ship it"</li>
            </ul>
        </TerminalWindow>

        <TerminalWindow title="~/ certifications">
            <p class="prompt">"ls ~/certs/"</p>
            <br />
            <ul class="skill-list">
                <li>"ML for Trading Specialization — Coursera, Oct 2020"</li>
                <li>"Advanced Data Science with IBM — Coursera, May 2020"</li>
                <li>"ML with TensorFlow on Google Cloud — Coursera, Mar 2020"</li>
                <li>"Adv. ML with TensorFlow on Google Cloud — Coursera, Mar 2020"</li>
                <li>"Deep Learning Specialization (Andrew Ng) — Coursera, Feb 2020"</li>
            </ul>
        </TerminalWindow>

        <h2 class="section-heading">"experience"</h2>
        <div class="timeline">
            <div class="timeline-item">
                <div class="timeline-date">"Jul 2022 — Present"</div>
                <div class="timeline-title">"Lead Developer"</div>
                <div class="timeline-subtitle">"Nicular LLC"</div>
                <div class="timeline-desc">
                    "I own the cloud. Designed and built the company's entire GCP architecture from "
                    "the ground up — VPCs, secrets management, client storage, the works. Built "
                    "internal tooling so the team can ship new services to Cloud Run or GKE without "
                    "touching infrastructure. Led the migration of legacy GCP-managed apps into "
                    "Kubernetes, and I review every line of code that goes to production."
                </div>
            </div>
            <div class="timeline-item">
                <div class="timeline-date">"Feb 2021 — Apr 2022"</div>
                <div class="timeline-title">"Data Scientist / Analyst"</div>
                <div class="timeline-subtitle">"Johnson Group Marketing"</div>
                <div class="timeline-desc">
                    "Turned a daily reporting grind — 4+ hours of manual spreadsheet work — into "
                    "a set of scripts that ran in 15 minutes. Built predictive models to establish "
                    "baseline marketing performance, and created geographic tracking tools that fed "
                    "hiring leads and market opportunities directly to clients."
                </div>
            </div>
            <div class="timeline-item">
                <div class="timeline-date">"May 2020"</div>
                <div class="timeline-title">"QA Analyst"</div>
                <div class="timeline-subtitle">"Yawye (Start-up)"</div>
                <div class="timeline-desc">
                    "Short contract, big migration. Moved the startup's analytics layer from MongoDB "
                    "to PostgreSQL, built Metabase dashboards for data quality monitoring, and helped "
                    "define what data was actually worth collecting in the first place."
                </div>
            </div>
            <div class="timeline-item">
                <div class="timeline-date">"Dec 2019 — Mar 2020"</div>
                <div class="timeline-title">"Data Scientist"</div>
                <div class="timeline-subtitle">"General Assembly"</div>
                <div class="timeline-desc">
                    "Where it all started. Immersive program focused on building real things — "
                    "ML models, data pipelines, SQL-driven analytics — with a personal obsession "
                    "for writing readable, portable code. Built tools designed to run on distributed "
                    "cloud architectures from day one."
                </div>
            </div>
        </div>

        <TerminalWindow title="~/ education">
            <p class="prompt">"cat ~/education.log"</p>
            <br />
            <p style="color: var(--ctp-subtext1)">
                "Data Science Immersive — General Assembly (2019–2020)"
            </p>
            <p style="color: var(--ctp-subtext1)">
                "Hands-on ML, statistical modeling, and data engineering. "
                "Built for the cloud from the start."
            </p>
            <br />
            <span class="cursor" />
        </TerminalWindow>
    }
}

// ── Portfolio ────────────────────────────────────────────────────────

#[component]
fn Portfolio() -> impl IntoView {
    let projects = vec![
        Project {
            title: "DockerScraper",
            desc: "Spins up containers that scrape live crypto ticker data and pipe it straight into Postgres — ready for ML models to chew on.",
            tags: &["Python", "Docker", "PostgreSQL"],
            source: "https://github.com/Zethtren/DockerScraper",
        },
        Project {
            title: "RoamChat",
            desc: "Unofficial API for Roam Chat. Send messages, handle failures gracefully, and wrap it all in a clean decorator pattern. Open-sourced because APIs should just work.",
            tags: &["Python", "API", "Open Source"],

            source: "https://github.com/Zethtren/RoamUnofficial",
        },
        Project {
            title: "Nicular Cloud Platform",
            desc: "Built an entire production GCP environment from scratch — VPCs, secrets, storage, deploy pipelines. The team ships to Cloud Run and GKE without touching infra.",
            tags: &["GCP", "Kubernetes", "Cloud Run"],

            source: "#",
        },
        Project {
            title: "Marketing Intelligence",
            desc: "Replaced 4+ hours of daily manual reporting with 15-minute automated pipelines. Added predictive baselines and geographic lead tracking that clients actually used.",
            tags: &["Python", "SQL", "ML"],

            source: "#",
        },
        Project {
            title: "Crypto ML Pipeline",
            desc: "End-to-end machine learning pipeline for crypto market analysis. Ingests live data, trains models, and surfaces predictions — all containerized and cloud-native.",
            tags: &["Python", "ML", "Docker"],

            source: "#",
        },
        Project {
            title: "leptos-cv",
            desc: "You're looking at it. A terminal-themed CV compiled to WASM with Leptos, styled in Catppuccin, because resumes should have a theme switcher.",
            tags: &["Rust", "Leptos", "WASM"],

            source: "https://github.com/Zethtren/leptos-cv",
        },
    ];

    let listing = projects
        .iter()
        .map(|p| format!("./projects/{}", p.title))
        .collect::<Vec<_>>()
        .join("\n");

    view! {
        <h2 class="section-heading">"portfolio"</h2>

        <TerminalWindow title="~/ ls projects/">
            <p class="prompt">"find ~/projects -maxdepth 1 -type d | sort"</p>
            <br />
            <p style="color: var(--ctp-subtext1)">{listing}</p>
            <br />
            <span class="cursor" />
        </TerminalWindow>

        <div class="tui-grid tui-projects">
            {projects
                .into_iter()
                .map(|p| {
                    view! {
                        <div class="tui-cell">
                            <span class="tui-label">{p.title}</span>
                            <p class="tui-desc">{p.desc}</p>
                            <div class="tui-tags">
                                {p
                                    .tags
                                    .iter()
                                    .map(|t| view! { <span class="tag">{*t}</span> })
                                    .collect_view()}
                            </div>
                            {(p.source != "#").then(|| view! {
                                <div class="tui-links">
                                    <a href=p.source target="_blank">"source"</a>
                                </div>
                            })}
                        </div>
                    }
                })
                .collect_view()}
        </div>
    }
}

struct Project {
    title: &'static str,
    desc: &'static str,
    tags: &'static [&'static str],
    source: &'static str,
}

// ── Reusable Terminal Window ─────────────────────────────────────────

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

// ── Footer ───────────────────────────────────────────────────────────

#[component]
fn Footer() -> impl IntoView {
    view! {
        <footer class="footer">
            <p>"Built with Leptos · Styled with Catppuccin · "<span class="cursor" /></p>
        </footer>
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
