# Claude Code Configuration

> · 한국어: [README.md](README.md)

A repo that collects my personal Claude Code setup.
Config and skills are symlinked into `~/.claude`; install and sync are handled by shell scripts in `bin/`.

## Project Structure

```
006_Claude-config/
├── global/                      # symlinked into ~/.claude (always-on)
│   ├── CLAUDE.md                #   global rules
│   ├── settings.json            #   permissions, hooks, plugins
│   ├── statusline-command.sh
│   ├── commands/                #   slash commands
│   └── hooks/                   #   event hooks (checks, notifications)
│
├── library/
│   ├── skills/                  # markdown source skills (linked globally)
│   ├── skill-lock.json          # third-party skill list
│   └── plugin-lock.json         # plugin list
│
├── templates/
│   └── project/.claude/         # starter config copied by init-project.sh
│
├── bin/
│   ├── bootstrap.sh             # fresh machine, one command (deploy + install)
│   ├── deploy-global.sh         # symlink global/* → ~/.claude
│   ├── init-project.sh          # set up a project + link skills
│   ├── install.sh               # install skills + plugins (wrapper)
│   ├── install-skills.sh        # install skills
│   ├── install-plugins.sh       # install plugins
│   ├── sync.sh                  # sync lists (wrapper)
│   ├── sync-skills.sh           # sync the skill list
│   └── sync-plugins.sh          # sync the plugin list
│
└── docs/
    ├── skills-and-plugins.md    # list of installed skills & plugins
    └── superpowers/             # design & implementation docs (git-ignored)
```

## Skills

> See **[docs/skills-and-plugins.md](docs/skills-and-plugins.md)** for the full list of installed skills and plugins.

### Markdown source skills

Kept as real files in `library/skills/`; `install-skills.sh` symlinks them into `~/.claude/skills/`
so they are **available everywhere** (the same place the third-party ones land).
To scope one to a single project, link it there with `init-project.sh --skills`.

### Third-party skills (npx)

Skills installed via the Vercel `skills` CLI (`npx skills`) are tracked as a list in
`library/skill-lock.json`.

- **Install**: `install-skills.sh` installs from the `skill-lock.json` list
- **Update**: add/update/remove via npx, then refresh `skill-lock.json` with `sync-skills.sh`

```bash
npx skills add <repo> -g -s <skill> -y && bin/sync-skills.sh    # add     → commit
npx skills update -g && bin/sync-skills.sh                      # update  → commit
npx skills remove -g -s <skill> -y && bin/sync-skills.sh        # remove  → commit

bin/install-skills.sh             # fresh machine: install latest from the list (bootstrap)
bin/install-skills.sh --dry-run   # preview the generated commands without running
npx skills list -g                # list installed global skills
```

## Plugins (claude plugin)

> See [docs/skills-and-plugins.md](docs/skills-and-plugins.md) for the list of installed plugins.

Plugin bodies aren't kept in the repo; they're tracked as a list (marketplaces + plugins) in
`library/plugin-lock.json`.

- **Install**: `install-plugins.sh` installs from the `plugin-lock.json` list — **doesn't touch enable** (`settings.json` decides)
- **Update**: add/change via `claude plugin install`, then refresh `plugin-lock.json` with `sync-plugins.sh`

```bash
claude plugin install <p>@<mkt> && bin/sync-plugins.sh   # add/change → commit
bin/install-plugins.sh             # fresh machine: install from the list (bootstrap)
bin/install-plugins.sh --dry-run   # preview commands without running
```

> ⚠️ `claude plugin install` has no `--yes`; a new marketplace prompts for trust on first use (interactive only — fails in headless/CI).

## Hooks (global)

| Hook Type                                    | Script             | Trigger                    | Purpose                         |
| -------------------------------------------- | ------------------ | -------------------------- | ------------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` or `Edit` tool     | lint/type check on changed file |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | permission / stop / prompt | terminal notifications          |

**Project-local tools only** — `quality-check.sh` looks only in `.venv/bin/` and `node_modules/.bin/` (no global installs).
Python runs `ruff`+`mypy`, TS/JS runs `eslint`+`tsc`, and if a tool is missing it skips.

## Usage

### 0. Bootstrap a fresh machine (one command)

Full setup right after cloning:

```bash
bin/bootstrap.sh            # deploy-global + install-skills + install-plugins
bin/bootstrap.sh --dry-run  # preview everything
```

### 1. Deploy global config

```bash
bin/deploy-global.sh            # symlink global/* into ~/.claude (idempotent)
bin/deploy-global.sh --dry-run  # preview without changes
```

Existing real files are backed up to `*.bak` before being replaced by symlinks.

### 2. Set up a project

```bash
# inside a project: enable plugins (skills are already global)
bin/init-project.sh --plugin superpowers

# link a specific skill to this project only / target another path
bin/init-project.sh --skills skill-developer --path ~/Dev/my-project
```

This creates `<project>/.claude/settings.json` from the template and enables the named plugins.
With `--skills`, it also links those skills into the project's `.claude/skills/` (usually unnecessary,
since skills are already global).

**Inside Claude Code:** once `bin/deploy-global.sh` has run, the `/init-project` slash command does the
same thing. Pass arguments to run directly (`/init-project skill-developer superpowers`), or omit them
and Claude lists the available skills/plugins for you to choose.

### 3. Sync back to the repo

After changing skills/plugins, update the repo's list files and commit:

```bash
bin/sync.sh           # skill-lock.json + plugin-lock.json together
bin/sync-skills.sh    # skills list only
bin/sync-plugins.sh   # plugins list only
```

## Customization

### Add a new skill to the library

1. Write `library/skills/<name>/SKILL.md` with YAML frontmatter.
2. Use the `skill-developer` skill for authoring guidance.
3. Run `install-skills.sh` to link it into `~/.claude/skills/` → enabled globally.

### Make my skills global

Adding a skill to `library/skills/` and running `install-skills.sh` links it into `~/.claude/skills/`
automatically. To link just one immediately, symlink it yourself (the same thing the script does):

```bash
ln -sfn ~/Jace_Dev/006_Claude-config/library/skills/<name> ~/.claude/skills/<name>
```
