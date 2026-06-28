# Claude Code Infrastructure

> · 한국어: [README.md](README.md)

Personal Claude Code infrastructure built around a **lean global + per-project
opt-in** model. The git repo is the single source of truth; global config is
deployed to `~/.claude` via symlinks, and each project opts into only the
skills/plugins it needs.

## Philosophy

Earlier this setup loaded everything globally and always-on, which fired
skills/plugins even when unwanted. The new model separates concerns:

- **Lean global** — `~/.claude` keeps only language/workflow rules, base settings,
  the quality-check hook, the statusline, and a few standalone skills.
- **Repo = source of truth** — every managed file lives in this repo and is
  symlinked into `~/.claude`. Edits happen here, tracked in git.
- **Per-project opt-in** — a project enables specific skills/plugins via a single
  bootstrap command, instead of inheriting a heavy global config.

```
글로벌(~/.claude)  ──symlink──  repo(017_Claude-config)
   lean, always-on              source of truth
        +                              +
   project .claude/  ◀── init-project.sh ── library / templates
```

## Project Structure

```
017_Claude-config/
├── global/                      # deployed to ~/.claude via symlinks (lean, always-on)
│   ├── CLAUDE.md                #   language / workflow / code rules
│   ├── settings.json            #   permissions, statusline, quality-check hook,
│   │                            #     plugins (plannotator, skill-creator)
│   ├── statusline-command.sh
│   └── hooks/
│       ├── quality-check.sh     #   lint/type check on file edit
│       └── notify-*.sh          #   input / stop / record-start notifications
│
├── library/
│   └── skills/                  # opt-in skills (NOT auto-loaded globally)
│       ├── skill-developer/             #   meta-skill for authoring skills
│       ├── find-skills/                 #   skill discovery & install
│       ├── vercel-react-best-practices/ #   React/Next performance
│       └── web-design-guidelines/       #   UI / accessibility review
│
├── templates/
│   └── project/.claude/         # starter config copied by init-project.sh
│       └── settings.json
│
├── bin/
│   ├── deploy-global.sh         # symlink global/* → ~/.claude/
│   └── init-project.sh          # scaffold a project's .claude/ + chosen skills
│
└── docs/superpowers/            # design specs & implementation plans
```

## Skills (opt-in library)

Domain-specific guidelines kept in `library/skills/`. They are **not** loaded
globally — enable them per project with `init-project.sh` (see below). Claude
Code auto-discovers a project's `.claude/skills/` at session start.

| Skill                         | Purpose                                                                |
| ----------------------------- | ---------------------------------------------------------------------- |
| `skill-developer`             | Meta-skill for authoring new skills following Anthropic best practices |
| `find-skills`                 | Discover and install agent skills                                      |
| `vercel-react-best-practices` | React/Next.js performance optimization patterns                        |
| `web-design-guidelines`       | UI / accessibility / UX review against web interface guidelines        |

## Hooks (global)

| Hook Type                                    | Script             | Trigger                    | Purpose                             |
| -------------------------------------------- | ------------------ | -------------------------- | ----------------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` or `Edit` tool     | Run lint/type check on changed file |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | permission / stop / prompt | Terminal notifications              |

**Project-local tools only** — `quality-check.sh` looks in `.venv/bin/` and
`node_modules/.bin/`, never global installs. If tools aren't present, it skips
silently (never blocks Claude).

```
PostToolUse (Write/Edit) → quality-check.sh
    ├── Python (.py)         → .venv/bin/ruff check + .venv/bin/mypy
    └── TS/JS (.ts/.tsx/...) → node_modules/.bin/eslint + tsc
```

## Usage

### 1. Deploy global config

```bash
bin/deploy-global.sh            # symlink global/* into ~/.claude (idempotent)
bin/deploy-global.sh --dry-run  # preview without changing anything
```

Existing real files are backed up to `*.bak` before being replaced by symlinks.

### 2. Set up a project (opt-in)

```bash
# inside a project, enable specific skills and plugins
bin/init-project.sh --skills web-design-guidelines,find-skills --plugin superpowers

# or target another path
bin/init-project.sh --skills skill-developer --path ~/Dev/my-project
```

This creates `<project>/.claude/settings.json` from the template, enables the
named plugins, and symlinks the chosen skills from `library/skills/`. Run it
yourself in a terminal, or ask Claude Code to run it for you.

## Customization

### Add a new skill to the library

1. Create `library/skills/<name>/SKILL.md` with YAML frontmatter.
2. Use the `skill-developer` skill for authoring guidance.
3. Enable it in a project with `init-project.sh --skills <name>`.

### Re-enable a skill globally

The repo keeps every skill, so to make one global again just symlink it:

```bash
ln -s ~/Jace_Dev/017_Claude-config/library/skills/<name> ~/.claude/skills/<name>
```

## Design Decisions

| Decision                         | Rationale                                                                   |
| -------------------------------- | --------------------------------------------------------------------------- |
| Lean global + per-project opt-in | Always-on global config fired skills/plugins when unwanted                  |
| Repo = source of truth (symlink) | One version-controlled copy; edits in repo propagate to `~/.claude`         |
| Project-local tools only         | Global installs pollute environments; `.venv/bin/` ensures isolation        |
| Silent skip on missing tools     | Hooks should never block Claude — degrade gracefully                        |
| Differential detail in skills    | Don't re-document what Claude already knows; focus on post-training changes |

## References

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
