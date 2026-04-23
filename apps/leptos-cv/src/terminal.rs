use leptos::prelude::*;
use leptos::ev;

#[derive(Clone)]
struct TerminalLine {
    prompt: Option<String>,
    content: String,
    is_error: bool,
    syntax: Option<String>,
}

// All completable tokens
const COMMANDS: &[&str] = &[
    "help", "whoami", "neofetch", "ls", "eza", "exa", "bat", "cat", "man",
    "uptime", "clear", "theme", "fortune", "cowsay", "sudo", "pwd", "echo",
    "ping", "ssh", "exit", "vim", "nvim",
];

const FILES: &[&str] = &[
    "README.md", "about.md", "contact.md",
    "skills/", "skills/languages.md", "skills/infra.md", "skills/tools.md", "skills/ml.md",
    "experience/", "experience/nicular.md", "experience/johnson-group.md",
    "experience/yawye.md", "experience/general-assembly.md",
    "projects/", "education/", "education/certifications.md",
    "blog/",
    "nicular.md", "johnson-group.md", "yawye.md", "general-assembly.md",
    "languages.md", "infra.md", "tools.md", "ml.md", "certifications.md",
];

const THEMES: &[&str] = &["mocha", "latte", "frappe", "macchiato"];

#[derive(Clone)]
struct Completions {
    candidates: Vec<String>,
    selected: usize,
    ghost: String, // the part to append on Tab
}

fn get_completions(input: &str) -> Option<Completions> {
    if input.is_empty() {
        return None;
    }

    let parts: Vec<&str> = input.split_whitespace().collect();
    let trimmed = input.trim_end();
    let has_trailing_space = input.len() > trimmed.len() && !parts.is_empty();

    if parts.is_empty() {
        return None;
    }

    let candidates: Vec<String>;
    let partial: String;

    if parts.len() == 1 && !has_trailing_space {
        // Completing a command name
        partial = parts[0].to_lowercase();
        candidates = COMMANDS.iter()
            .filter(|c| c.starts_with(&partial.as_str()) && **c != partial)
            .map(|c| c.to_string())
            .collect();
    } else {
        // Completing an argument
        let cmd = parts[0].to_lowercase();
        partial = if has_trailing_space { String::new() } else { parts.last().unwrap_or(&"").to_string() };

        let pool: Vec<&str> = match cmd.as_str() {
            "bat" | "cat" => FILES.to_vec(),
            "theme" => THEMES.to_vec(),
            "ls" | "eza" | "exa" => FILES.iter().filter(|f| f.ends_with('/')).copied().collect(),
            "man" => vec!["houston"],
            "sudo" => vec!["hire-me"],
            _ => vec![],
        };

        if partial.is_empty() {
            candidates = pool.iter().map(|s| s.to_string()).collect();
        } else {
            let lower = partial.to_lowercase();
            candidates = pool.iter()
                .filter(|f| f.to_lowercase().starts_with(&lower) && f.to_lowercase() != lower)
                .map(|f| f.to_string())
                .collect();
        }
    }

    if candidates.is_empty() {
        return None;
    }

    let ghost = if partial.is_empty() {
        candidates[0].clone()
    } else {
        candidates[0][partial.len()..].to_string()
    };

    Some(Completions {
        candidates,
        selected: 0,
        ghost,
    })
}

// Backward compat wrapper
fn get_suggestion(input: &str) -> Option<String> {
    get_completions(input).map(|c| c.ghost)
}

#[component]
pub fn InteractiveTerminal() -> impl IntoView {
    let (history, set_history) = signal(Vec::<TerminalLine>::new());
    let (input, set_input) = signal(String::new());
    let (cmd_history, set_cmd_history) = signal(Vec::<String>::new());
    let (history_index, set_history_index) = signal(Option::<usize>::None);
    let input_ref = NodeRef::<leptos::html::Input>::new();

    // Fish-style completions derived from input
    let completions = move || get_completions(&input.get());

    // Focus the input when clicking anywhere in the terminal
    let focus_input = move |_| {
        if let Some(el) = input_ref.get() {
            let _ = el.focus();
        }
    };

    // Handle keydown for special keys
    let on_keydown = move |ev: ev::KeyboardEvent| {
        match ev.key().as_str() {
            "Tab" => {
                ev.prevent_default();
                if let Some(s) = get_suggestion(&input.get()) {
                    set_input.update(|i| i.push_str(&s));
                }
            }
            "ArrowRight" => {
                if let Some(s) = get_suggestion(&input.get()) {
                    ev.prevent_default();
                    set_input.update(|i| i.push_str(&s));
                }
            }
            "Enter" => {
                let cmd = input.get();
                if !cmd.is_empty() {
                    set_cmd_history.update(|h| h.push(cmd.clone()));
                    set_history_index.set(None);

                    set_history.update(|h| {
                        h.push(TerminalLine {
                            prompt: Some("visitor@houstonbova.com:~$".to_string()),
                            content: cmd.clone(),
                            is_error: false,
                            syntax: None,
                        });
                    });

                    if cmd.trim() == "clear" {
                        set_history.set(Vec::new());
                    } else {
                        let output = execute_command(&cmd);
                        set_history.update(|h| h.extend(output));
                    }

                    set_input.set(String::new());
                }
            }
            "ArrowUp" => {
                ev.prevent_default();
                let cmds = cmd_history.get();
                if !cmds.is_empty() {
                    let idx = history_index
                        .get()
                        .map(|i| if i > 0 { i - 1 } else { 0 })
                        .unwrap_or(cmds.len() - 1);
                    set_history_index.set(Some(idx));
                    set_input.set(cmds[idx].clone());
                }
            }
            "ArrowDown" => {
                ev.prevent_default();
                let cmds = cmd_history.get();
                if let Some(idx) = history_index.get() {
                    if idx < cmds.len() - 1 {
                        let new_idx = idx + 1;
                        set_history_index.set(Some(new_idx));
                        set_input.set(cmds[new_idx].clone());
                    } else {
                        set_history_index.set(None);
                        set_input.set(String::new());
                    }
                }
            }
            "l" if ev.ctrl_key() => {
                ev.prevent_default();
                set_history.set(Vec::new());
            }
            _ => {}
        }
    };

    // Initial welcome message
    let welcome = vec![TerminalLine {
        prompt: None,
        content: "Type 'help' for available commands.".to_string(),
        is_error: false,
        syntax: None,
    }];
    set_history.set(welcome);

    view! {
        <div class="interactive-terminal" on:click=focus_input>
            <div class="terminal-output">
                {move || {
                    history
                        .get()
                        .into_iter()
                        .enumerate()
                        .map(|(_i, line)| {
                            let cls = if line.is_error {
                                "terminal-line error".to_string()
                            } else if let Some(ref syn) = line.syntax {
                                format!("terminal-line {}", syn)
                            } else {
                                "terminal-line".to_string()
                            };
                            view! {
                                <div class=cls>
                                    {line
                                        .prompt
                                        .as_ref()
                                        .map(|p| {
                                            view! {
                                                <span class="term-prompt">{p.clone()}" "</span>
                                            }
                                        })}

                                    <span class="term-content">{line.content.clone()}</span>
                                </div>
                            }
                        })
                        .collect_view()
                }}

                <div class="terminal-input-line">
                    <span class="term-prompt">"visitor@houstonbova.com:~$"</span>
                    <span class="term-typed">{move || format!(" {}", input.get())}</span>
                    <span class="cursor" />
                </div>
                {move || completions().map(|c| {
                    let max_show = 12;
                    let showing: Vec<_> = c.candidates.iter().take(max_show).cloned().collect();
                    let more = c.candidates.len() > max_show;
                    view! {
                        <div class="term-completions">
                            {showing.into_iter().enumerate().map(|(i, candidate)| {
                                let cls = if i == c.selected { "term-completion selected" } else { "term-completion" };
                                view! { <span class=cls>{candidate.clone()}</span> }
                            }).collect_view()}
                            {more.then(|| view! { <span class="term-completion more">"..."</span> })}
                        </div>
                    }.into_any()
                })}
                <div class="terminal-line">" "</div>
            </div>
            <input
                node_ref=input_ref
                type="text"
                class="terminal-hidden-input"
                prop:value=move || input.get()
                on:input=move |ev| {
                    set_input.set(event_target_value(&ev));
                }
                on:keydown=on_keydown
                autocomplete="off"
                autofocus
            />
        </div>
    }
}

fn bat_output(file: &str, content: &[&str]) -> Vec<TerminalLine> {
    let mut out = vec![
        styled(&format!("File: {}", file), "bat-file-header"),
        styled(&"─".repeat(40), "bat-ruler-line"),
    ];
    for (i, l) in content.iter().enumerate() {
        let syntax = if l.starts_with("# ") {
            "bat-syn-h1"
        } else if l.starts_with("## ") {
            "bat-syn-h2"
        } else if l.starts_with("- ") || l.starts_with("* ") {
            "bat-syn-bullet"
        } else if l.starts_with("> ") {
            "bat-syn-quote"
        } else if l.starts_with("```") {
            "bat-syn-fence"
        } else if l.trim().is_empty() {
            "bat-syn-empty"
        } else {
            "bat-syn-text"
        };
        out.push(styled(&format!("{:>3} │ {}", i + 1, l), syntax));
    }
    out.push(styled(&"─".repeat(40), "bat-ruler-line"));
    out.push(line(""));
    out
}

fn eza_output(entries: &[(&str, &str)]) -> Vec<TerminalLine> {
    let mut out = Vec::new();
    for (kind, name) in entries {
        out.push(line(&format!(".rw-r--r--  {}  {}", kind, name)));
    }
    out.push(line(""));
    out
}

fn execute_command(cmd: &str) -> Vec<TerminalLine> {
    let parts: Vec<&str> = cmd.trim().split_whitespace().collect();
    let command = parts
        .first()
        .map(|s| s.to_lowercase())
        .unwrap_or_default();

    match command.as_str() {
        "help" => vec![
            line("Available commands:"),
            line("  help            — Show this help message"),
            line("  whoami          — Who am I?"),
            line("  neofetch        — System info"),
            line("  ls [path]       — List directory (eza -l --icons)"),
            line("  bat <file>      — View file with syntax highlighting"),
            line("  cat <file>      — Alias for bat"),
            line("  man houston     — Read the manual"),
            line("  uptime          — How long has this been running"),
            line("  clear           — Clear terminal (or Ctrl+L)"),
            line("  theme <name>    — Switch theme (mocha/latte/frappe/macchiato)"),
            line("  fortune         — Random wisdom"),
            line("  cowsay <msg>    — Moo"),
            line("  sudo <cmd>      — Try it..."),
            line(""),
        ],
        "whoami" => vec![
            line("Houston Kelly Bova — Lead Developer & Cloud Architect"),
            line("Level 6 Terminal Dweller | Catppuccin Enthusiast"),
            line(""),
        ],
        "neofetch" => vec![
            line("contact@houstonbova.com"),
            line("---------------------"),
            line("OS:        leptos-cv 0.1.0 (WASM)"),
            line("Host:      Catppuccin Terminal v1"),
            line("Shell:     leptos 0.8"),
            line("Languages: Python, Rust, Go, SQL"),
            line("Infra:     GCP, Docker, Kubernetes"),
            line("Editor:    Neovim (the correct choice)"),
            line("Theme:     Catppuccin Mocha"),
            line(""),
        ],
        "uptime" => vec![
            line(" up since Dec 2019, load average: mass_migration 3.14, automation 2.72, coffee 1.41"),
            line(""),
        ],
        "ls" | "exa" | "eza" => {
            let path = if command == "ls" { parts.get(1).unwrap_or(&"~") }
                       else { parts.last().unwrap_or(&"~") };
            match *path {
                "~" | "." | "/" => eza_output(&[
                    ("d ", "skills/"),
                    ("d ", "experience/"),
                    ("d ", "projects/"),
                    ("d ", "education/"),
                    ("d ", "blog/"),
                    ("  ", "README.md"),
                    ("  ", "about.md"),
                    ("  ", "contact.md"),
                ]),
                "skills" | "skills/" | "~/.skills/" => eza_output(&[
                    ("  ", "languages.md"),
                    ("  ", "infra.md"),
                    ("  ", "tools.md"),
                    ("  ", "ml.md"),
                ]),
                "projects" | "projects/" | "~/projects/" => eza_output(&[
                    ("d ", "DockerScraper/"),
                    ("d ", "RoamChat/"),
                    ("d ", "NicularCloud/"),
                    ("d ", "MarketingIntel/"),
                    ("d ", "CryptoML/"),
                    ("d ", "leptos-cv/"),
                ]),
                "experience" | "experience/" => eza_output(&[
                    ("  ", "nicular.md"),
                    ("  ", "johnson-group.md"),
                    ("  ", "yawye.md"),
                    ("  ", "general-assembly.md"),
                ]),
                "education" | "education/" => eza_output(&[
                    ("  ", "general-assembly.md"),
                    ("  ", "certifications.md"),
                ]),
                "blog" | "blog/" | "blogs" | "blogs/" => vec![
                    line("Blog posts are loaded from the database."),
                    line("Visit /blog for the full listing."),
                    line(""),
                    line("Hint: try 'bat blog/hello-world.md' or visit /blog in the browser."),
                    line(""),
                ],
                _ => vec![
                    err(&format!("eza: '{}': No such file or directory", path)),
                    line(""),
                ],
            }
        }
        "bat" | "cat" => {
            let file = parts.get(1).unwrap_or(&"");
            match *file {
                "README.md" | "readme.md" => bat_output("README.md", &[
                    "# Houston Kelly Bova",
                    "",
                    "> Lead Developer & Cloud Architect",
                    "",
                    "I build infrastructure that stays up and tools",
                    "that don't get in the way.",
                    "",
                    "## Quick Links",
                    "",
                    "- **about** — $ bat about.md",
                    "- **portfolio** — $ ls projects/",
                ]),
                "about.md" => bat_output("about.md", &[
                    "# About",
                    "",
                    "I'm Houston — a lead developer and cloud architect",
                    "who ships production infrastructure on GCP and writes",
                    "the tooling that makes deploys boring (in the best way).",
                    "",
                    "## Stack",
                    "",
                    "- **Languages** — Python, Rust, Go, SQL",
                    "- **Cloud** — GCP, Cloud Run, GKE, Docker, Kubernetes",
                    "- **Philosophy** — If it takes more than 15 minutes and",
                    "  happens more than twice, it's getting a script",
                    "",
                    "## Background",
                    "",
                    "> Before all this, I was a data scientist — I still",
                    "> nerd out over ML papers and have five Coursera",
                    "> specializations to prove it.",
                ]),
                "contact.md" => bat_output("contact.md", &[
                    "# Contact",
                    "",
                    "- **Email**  — contact@houstonbova.com",
                    "- **GitHub** — https://github.com/Zethtren",
                ]),
                "skills/languages.md" | "languages.md" => bat_output("skills/languages.md", &[
                    "# Languages",
                    "",
                    "- **Python** — Pipelines, ML, automation",
                    "- **Rust** — Systems code, WASM, lifetimes",
                    "- **Go** — Services, CLI tools, concurrency",
                    "- **SQL** — PostgreSQL, analytics",
                ]),
                "skills/infra.md" | "infra.md" => bat_output("skills/infra.md", &[
                    "# Infrastructure",
                    "",
                    "- **GCP** — Cloud Run, GKE, VPCs, Secrets, Storage",
                    "- **Docker** — Containerize it, orchestrate it, ship it",
                    "- **Kubernetes** — GKE orchestration, service meshes",
                    "- **Cloud Run** — Serverless container deployments",
                ]),
                "skills/tools.md" | "tools.md" => bat_output("skills/tools.md", &[
                    "# Tools",
                    "",
                    "- **Data Engineering** — Pipelines, ETL, warehouse design",
                    "- **PostgreSQL** — Primary relational database",
                    "- **Leptos** — Rust web framework compiled to WASM",
                    "- **Metabase** — BI dashboarding and data quality",
                    "- **API Design** — RESTful APIs, decorator patterns",
                ]),
                "skills/ml.md" | "ml.md" => bat_output("skills/ml.md", &[
                    "# Machine Learning",
                    "",
                    "- **ML** — Predictive models, deep learning",
                    "- **TensorFlow** — Training and serving models",
                ]),
                "experience/nicular.md" | "nicular.md" => bat_output("experience/nicular.md", &[
                    "# Lead Developer — Nicular LLC",
                    "> Jul 2022 — Present",
                    "",
                    "Lead dev on the cloud side. Helped design and build much",
                    "of the company's GCP architecture — VPCs, secrets",
                    "management, client storage, and the supporting bits.",
                    "",
                    "Built internal tooling so the team can ship services to",
                    "Cloud Run or GKE without wrestling with infra. Helped",
                    "drive the migration of legacy GCP-managed apps into",
                    "Kubernetes, and review a lot of what goes to production.",
                ]),
                "experience/johnson-group.md" | "johnson-group.md" => bat_output("experience/johnson-group.md", &[
                    "# Data Scientist / Analyst — Johnson Group Marketing",
                    "> Feb 2021 — Apr 2022",
                    "",
                    "Turned a daily reporting grind — 4+ hours of manual",
                    "spreadsheet work — into scripts that ran in 15 minutes.",
                    "Built predictive models for baseline marketing performance",
                    "and geographic tracking tools for hiring leads.",
                ]),
                "experience/yawye.md" | "yawye.md" => bat_output("experience/yawye.md", &[
                    "# QA Analyst — Yawye (Start-up)",
                    "> May 2020",
                    "",
                    "Short contract, big migration. Moved analytics from",
                    "MongoDB to PostgreSQL, built Metabase dashboards for",
                    "data quality monitoring.",
                ]),
                "experience/general-assembly.md" | "general-assembly.md" => bat_output("experience/general-assembly.md", &[
                    "# Data Scientist — General Assembly",
                    "> Dec 2019 — Mar 2020",
                    "",
                    "Where it all started. Immersive program focused on",
                    "building real things — ML models, data pipelines,",
                    "SQL-driven analytics.",
                ]),
                "education/certifications.md" | "certifications.md" => bat_output("education/certifications.md", &[
                    "# Certifications",
                    "",
                    "- ML for Trading Specialization — Coursera, Oct 2020",
                    "- Advanced Data Science with IBM — Coursera, May 2020",
                    "- ML with TensorFlow on GCP — Coursera, Mar 2020",
                    "- Adv. ML with TensorFlow on GCP — Coursera, Mar 2020",
                    "- Deep Learning Specialization (Andrew Ng) — Feb 2020",
                ]),
                "/etc/shadow" | "/etc/passwd" => vec![
                    err("Access denied. But nice security instincts."),
                    line(""),
                ],
                "" => vec![
                    err("bat: missing operand. Try 'bat README.md' or 'bat about.md'"),
                    line(""),
                ],
                _ if file.starts_with("blog/") => {
                    let slug = file.trim_start_matches("blog/").trim_end_matches(".md");
                    vec![
                        line(&format!("Blog posts are dynamically loaded from the database.")),
                        line(&format!("To read '{}', visit /blog/{} in your browser.", file, slug)),
                        line(""),
                    ]
                },
                _ => vec![
                    err(&format!("bat: {}: No such file or directory", file)),
                    line(""),
                ],
            }
        }
        "man" => {
            if parts.get(1) == Some(&"houston") {
                vec![
                    line("HOUSTON(1)                   Developer Manual                   HOUSTON(1)"),
                    line(""),
                    line("NAME"),
                    line("       houston — lead developer, cloud architect, terminal enthusiast"),
                    line(""),
                    line("SYNOPSIS"),
                    line("       houston [--hire] [--collaborate] [--chat]"),
                    line(""),
                    line("DESCRIPTION"),
                    line("       Houston is a lead developer specializing in GCP infrastructure,"),
                    line("       Kubernetes orchestration, and build tooling that makes teams'"),
                    line("       lives measurably less painful."),
                    line(""),
                    line("ENVIRONMENT"),
                    line("       STACK    Python, Rust, Go, SQL"),
                    line("       CLOUD    GCP, Cloud Run, GKE, Docker, Kubernetes"),
                    line("       EDITOR   Neovim (the correct choice)"),
                    line("       THEME    Catppuccin Mocha (the correct choice)"),
                    line(""),
                    line("BUGS"),
                    line("       Occasionally mass-migrates things into Kubernetes when a simpler"),
                    line("       solution exists. Considers this a feature."),
                    line(""),
                    line("SEE ALSO"),
                    line("       github(1), linkedin(1), email(1)"),
                    line(""),
                ]
            } else {
                vec![
                    err("What manual page do you want? Try 'man houston'"),
                    line(""),
                ]
            }
        }
        "fortune" => {
            let fortunes = [
                "There are only two hard things in CS: cache invalidation and naming things. — Phil Karlton",
                "Premature optimization is the root of all evil. — Donald Knuth",
                "Simplicity is prerequisite for reliability. — Edsger Dijkstra",
                "Debugging is twice as hard as writing the code. — Brian Kernighan",
                "Real artists ship. — Steve Jobs",
            ];
            let idx = cmd.len() % fortunes.len();
            vec![line(fortunes[idx]), line("")]
        }
        "cowsay" => {
            let msg = if parts.len() > 1 {
                parts[1..].join(" ")
            } else {
                "moo".to_string()
            };
            let border = "-".repeat(msg.len() + 2);
            vec![
                line(&format!(" {}", border)),
                line(&format!("< {} >", msg)),
                line(&format!(" {}", border)),
                line("        \\   ^__^"),
                line("         \\  (oo)\\_______"),
                line("            (__)\\       )\\/\\"),
                line("                ||----w |"),
                line("                ||     ||"),
                line(""),
            ]
        }
        "sudo" => {
            let subcmd = parts
                .get(1)
                .map(|s| s.to_lowercase())
                .unwrap_or_default();
            match subcmd.as_str() {
                "hire-me" => vec![
                    line(""),
                    line("  ╔══════════════════════════════════════╗"),
                    line("  ║       ACCESS GRANTED                 ║"),
                    line("  ╠══════════════════════════════════════╣"),
                    line("  ║  Email:  contact@houstonbova.com        ║"),
                    line("  ║  GitHub: github.com/Zethtren         ║"),
                    line("  ╚══════════════════════════════════════╝"),
                    line(""),
                ],
                _ => vec![
                    err("visitor is not in the sudoers file. This incident will be reported."),
                    line(""),
                ],
            }
        }
        "vim" | "nvim" | "nano" | "emacs" => vec![
            err("This terminal does not support text editors. But I use Neovim, btw."),
            line(""),
        ],
        "exit" => vec![
            line("There is no escape. This terminal is your life now."),
            line("(But you can close the browser tab.)"),
            line(""),
        ],
        "rm" => {
            if cmd.contains("-rf") {
                vec![
                    err("Nice try. Permission denied. Also, this is a website."),
                    line(""),
                ]
            } else {
                vec![err("rm: cannot remove: Permission denied"), line("")]
            }
        }
        "pwd" => vec![line("/home/visitor"), line("")],
        "echo" => {
            let msg = if parts.len() > 1 {
                parts[1..].join(" ")
            } else {
                String::new()
            };
            vec![line(&msg), line("")]
        }
        "ping" => vec![
            line("64 bytes from cloud-architect: time=0.42ms — yep, still here."),
            line(""),
        ],
        "ssh" => vec![
            err("Connection refused. But you can reach me at contact@houstonbova.com"),
            line(""),
        ],
        "clear" => vec![],
        "theme" => {
            let theme = parts.get(1).unwrap_or(&"");
            match *theme {
                "mocha" | "latte" | "frappe" | "macchiato" => {
                    vec![line(&format!("Switched to Catppuccin {}", theme)), line("")]
                }
                "" => vec![
                    line("Current themes: mocha, latte, frappe, macchiato"),
                    line("Usage: theme <name>"),
                    line(""),
                ],
                _ => vec![
                    err(&format!(
                        "Unknown theme '{}'. Try: mocha, latte, frappe, macchiato",
                        theme
                    )),
                    line(""),
                ],
            }
        }
        "" => vec![],
        _ => vec![
            err(&format!(
                "{}: command not found. Type 'help' for available commands.",
                command
            )),
            line(""),
        ],
    }
}

fn line(s: &str) -> TerminalLine {
    TerminalLine {
        prompt: None,
        content: s.to_string(),
        is_error: false,
        syntax: None,
    }
}

fn styled(s: &str, class: &str) -> TerminalLine {
    TerminalLine {
        prompt: None,
        content: s.to_string(),
        is_error: false,
        syntax: Some(class.to_string()),
    }
}

fn err(s: &str) -> TerminalLine {
    TerminalLine {
        prompt: None,
        content: s.to_string(),
        is_error: true,
        syntax: None,
    }
}
