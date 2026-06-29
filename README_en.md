# Claude Code Infrastructure

> · 한국어: [README.md](README.md)

Personal Claude Code infrastructure built around a **lean global + per-project
opt-in** model. The git repo is the single source of truth; global config is
deployed to `~/.claude` via symlinks, and each project opts into only the
skills/plugins it needs.

## Project Structure

```
017_Claude-config/
├── global/                      # deployed to ~/.claude via symlinks (lean, always-on)
│   ├── CLAUDE.md                #   language / workflow / code rules
│   ├── settings.json            #   permissions, statusline, quality-check hook,
│   │                            #     plugins (plannotator, skill-creator)
│   ├── statusline-command.sh
│   ├── commands/
│   │   └── init-project.md      #   /init-project slash command
│   └── hooks/
│       ├── quality-check.sh     #   lint/type check on file edit
│       └── notify-*.sh          #   input / stop / record-start notifications
│
├── library/
│   ├── skills/                  # my own opt-in skills (NOT auto-loaded globally)
│   │   └── skill-developer/             #   meta-skill for authoring skills
│   └── skill-lock.json          # third-party skill manifest (npx lockfile snapshot)
│
├── templates/
│   └── project/.claude/         # starter config copied by init-project.sh
│       └── settings.json
│
├── bin/
│   ├── deploy-global.sh         # symlink global/* → ~/.claude/
│   ├── init-project.sh          # scaffold a project's .claude/ + chosen skills
│   ├── install-skills.sh        # install third-party skills from the lockfile (bootstrap)
│   └── sync-skills.sh           # capture the lockfile into the repo after updates
│
└── docs/superpowers/            # design specs & implementation plans
```

## Skills

Skills fall into **two kinds, by origin.**

### My own skills (vendored, opt-in)

Kept as real files in `library/skills/` — this repo is the source of truth. They
are **not** loaded globally; enable them per project with `init-project.sh`.
Claude Code auto-discovers a project's `.claude/skills/` at session start.

| Skill             | Purpose                                                               |
| ----------------- | --------------------------------------------------------------------- |
| `skill-developer` | Meta-skill for authoring new skills following Anthropic best practices |

### Third-party skills (npx + lockfile)

Skills authored by others are **not** copied into the repo. The Vercel `skills`
CLI (`npx skills`) installs/manages them globally; the repo tracks **only the
lockfile** (`library/skill-lock.json`) as the single source of truth. (Same idea
as not committing `node_modules` but committing `package-lock.json`.)

| Skill                         | Source                   | Purpose                                  |
| ----------------------------- | ------------------------ | ---------------------------------------- |
| `find-skills`                 | vercel-labs/skills       | Discover and install agent skills        |
| `vercel-react-best-practices` | vercel-labs/agent-skills | React/Next.js performance patterns       |
| `web-design-guidelines`       | vercel-labs/agent-skills | UI review against web interface guidelines |
| `pptx`                        | anthropics/skills        | Create / edit / extract .pptx            |

Add / update / remove via npx, then run `sync-skills.sh` to reflect the lockfile
into the repo and commit. `install-skills.sh` **derives its commands from the
lockfile**, so you never edit it by hand.

```bash
npx skills add <repo> -g -s <skill> -y && bin/sync-skills.sh    # add     → commit
npx skills update -g && bin/sync-skills.sh                      # update  → commit
npx skills remove -g -s <skill> -y && bin/sync-skills.sh        # remove  → commit

bin/install-skills.sh             # fresh machine: install from the lockfile (bootstrap)
bin/install-skills.sh --dry-run   # preview the generated commands without running them
npx skills list -g                # list installed global skills
```

## Hooks (global)

| Hook Type                                    | Script             | Trigger                    | Purpose                             |
| -------------------------------------------- | ------------------ | -------------------------- | ----------------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` or `Edit` tool     | Run lint/type check on changed file |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | permission / stop / prompt | Terminal notifications              |

**Project-local tools only** — `quality-check.sh` looks in `.venv/bin/` and
`node_modules/.bin/`, never global installs. Python runs `ruff`+`mypy`, TS/JS runs
`eslint`+`tsc`, and if the tools aren't present it skips silently.

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
named plugins, and symlinks the chosen skills from `library/skills/` (my own) or
`~/.agents/skills/` (npx third-party).

**Inside Claude Code:** once `bin/deploy-global.sh` has been run, the `/init-project`
slash command does the same thing. Pass arguments to run directly (`/init-project
skill-developer superpowers`), or omit them and Claude lists the available
skills/plugins for you to choose.

## Customization

### Add a new skill to the library

1. Create `library/skills/<name>/SKILL.md` with YAML frontmatter.
2. Use the `skill-developer` skill for authoring guidance.
3. Enable it in a project with `init-project.sh --skills <name>`.

### Make one of my skills global

To use a skill from `library/skills/` globally, just symlink it (third-party
skills are already installed globally by `npx skills`):

```bash
ln -s ~/Jace_Dev/017_Claude-config/library/skills/<name> ~/.claude/skills/<name>
```

## Design Decisions

| Decision                         | Rationale                                                                   |
| -------------------------------- | --------------------------------------------------------------------------- |
| Lean global + per-project opt-in | Always-on global config fired skills/plugins when unwanted                  |
| Repo = source of truth (symlink) | One version-controlled copy; edits in repo propagate to `~/.claude`         |
| Third-party tracked via manifest | npx is upstream, so commit a lockfile + bootstrap instead of vendoring bodies (small diffs) |
| Project-local tools only         | Global installs pollute environments; `.venv/bin/` ensures isolation        |
| Silent skip on missing tools     | Hooks should never block Claude — degrade gracefully                        |

## References

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
