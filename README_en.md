# Claude Code Configuration

[한국어](README.md)

A single repo that version-controls my personal Claude Code setup (global rules, hooks, skills, plugins).
One run of `bootstrap.sh` restores my environment on a fresh machine.

The config itself lives in this repo; only **symlinks** point into `~/.claude`. Edit the repo and changes
apply right away. Third-party skills and plugins aren't vendored — they're tracked as a **lock file** (a list)
and reinstalled on a new machine.

| What                  | How it's managed                    | On a fresh machine   |
| --------------------- | ----------------------------------- | -------------------- |
| Global config & hooks | source in repo, **symlinked**       | `deploy-global.sh`   |
| My skills             | real files in `library/skills/`     | `install-skills.sh`  |
| Third-party skills    | `skill-lock.json` **list**          | `install-skills.sh`  |
| Plugins               | `plugin-lock.json` **list**         | `install-plugins.sh` |

## Quick Start

```bash
git clone git@github.com:JaceJung-dev/claude-config.git
cd claude-config

bin/bootstrap.sh            # deploy global + install skills & plugins (one command)
bin/bootstrap.sh --dry-run  # preview everything first
```

`bootstrap.sh` runs all three at once — `deploy-global` + `install-skills` + `install-plugins`.
To run each step on its own, see [Usage](#usage).

## Usage

For running the steps that bootstrap bundles together on their own.

### 1. Deploy global config

```bash
bin/deploy-global.sh            # symlink global/* into ~/.claude (idempotent)
bin/deploy-global.sh --dry-run  # preview without changes
```

> [!TIP]
> Existing real files are backed up to `*.bak` before being replaced by symlinks.

### 2. Sync back to the repo

After changing skills/plugins, update the repo's list files and commit:

```bash
bin/sync.sh           # skill-lock.json + plugin-lock.json together
bin/sync-skills.sh    # skills list only
bin/sync-plugins.sh   # plugins list only
```

## Project Structure

<details>
<summary>Expand the tree</summary>

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
    ├── components.md            # component list (skills, plugins, hooks)
    └── superpowers/             # design & implementation docs (local only, not in repo)
```

</details>

## Skills

> See **[docs/components.md](docs/components.md)** for the full list of installed skills and plugins.

### Markdown source skills

Kept as real files in `library/skills/`; `install-skills.sh` symlinks them into `~/.claude/skills/`
so they're **available everywhere** (the same place third-party skills land).
To scope one to a single project, link it there with `init-project.sh --skills`.

### Third-party skills (npx)

Skills installed via the Vercel `skills` CLI (`npx skills`) are tracked as a list in `library/skill-lock.json`.

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

## Plugins

> See [docs/components.md](docs/components.md) for the list of installed plugins.

Plugin bodies aren't kept in the repo; they're tracked as a list (marketplaces + plugins) in `library/plugin-lock.json`.

- **Install**: `install-plugins.sh` installs from the `plugin-lock.json` list — **doesn't touch enable** (`settings.json` decides)
- **Update**: add/change via `claude plugin install`, then refresh `plugin-lock.json` with `sync-plugins.sh`

```bash
claude plugin install <p>@<mkt> && bin/sync-plugins.sh   # add/change → commit
bin/install-plugins.sh             # fresh machine: install from the list (bootstrap)
bin/install-plugins.sh --dry-run   # preview commands without running
```

> [!WARNING]
> `claude plugin install` has no `--yes`; a new marketplace prompts for trust on first use (fails in headless/CI).
