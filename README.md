# Claude Code Infrastructure

Personal Claude Code infrastructure for Python AI development. Skills auto-activate by keyword, quality checks run on every edit, and context persists across sessions — all without manual intervention.

## Core Automation

```
┌─────────────────────────────────────────────────────────────┐
│  User Prompt                                                │
│  "LangChain으로 RAG 만들어줘"                               │
│          │                                                  │
│          ▼                                                  │
│  ┌─────────────────────┐    ┌──────────────────────┐        │
│  │ UserPromptSubmit    │───▶│ skill-activation.sh  │        │
│  │ Hook                │    │ keyword matching     │        │
│  └─────────────────────┘    └──────────┬───────────┘        │
│                                        │                    │
│                   "ai-engineering skill detected"           │
│                                        │                    │
│                                        ▼                    │
│                     Claude reads SKILL.md guidelines        │
│                     and implements with correct patterns     │
│                                        │                    │
│                                        ▼                    │
│  ┌─────────────────────┐    ┌──────────────────────┐        │
│  │ PostToolUse         │───▶│ quality-check.sh     │        │
│  │ Hook (Write/Edit)   │    │ ruff + mypy          │        │
│  └─────────────────────┘    └──────────┬───────────┘        │
│                                        │                    │
│                   "Quality issues found in app.py: ..."     │
│                   Claude auto-fixes and re-edits            │
└─────────────────────────────────────────────────────────────┘
```

## Skills

Domain-specific guidelines that auto-activate when relevant keywords are detected in your prompt.

| Skill | Triggers | Detail Level | Purpose |
|-------|----------|:------------:|---------|
| `ai-engineering` | langchain, langgraph, rag, create_agent, lcel, vectorstore, 멀티에이전트 | **Detailed** | LangChain v1 breaking changes, middleware system, LangGraph StateGraph/Functional API |
| `python-backend` | fastapi, django, flask, sqlalchemy, pydantic, django channels, celery | Concise | FastAPI (Pydantic v2, Annotated DI), Django (async views, Channels WebSocket) |
| `ml-training` | pytorch, transformers, fine-tuning, quantization, lora, peft, 파인튜닝 | **Detailed** | Transformers v5 breaking changes, PyTorch training patterns, LoRA/PEFT |
| `skill-developer` | skill 만들, create skill, SKILL.md | Concise | Meta-skill for authoring new skills following Anthropic best practices |

### Differential Detail

Skills follow a **differential detail** approach — the amount of documentation matches how much has changed since Claude's training data.

```
                    Detail Level
                        ▲
                        │
              Detailed  │  ┌──────────────┐   ┌──────────────┐
             (200-300L)  │  │ ai-engineering│   │  ml-training │
                        │  │ LangChain v1  │   │ Transformers │
                        │  │ breaking API  │   │   v5 breaks  │
                        │  └──────────────┘   └──────────────┘
                        │
              Concise   │  ┌──────────────┐   ┌──────────────┐
              (100-170L) │  │python-backend│   │skill-developer│
                        │  │ Django/FastAPI│   │  meta-skill  │
                        │  │ Claude knows  │   │  Anthropic   │
                        │  │  these well   │   │ best practice│
                        │  └──────────────┘   └──────────────┘
                        │
                        └────────────────────────────────────▶
                            Framework Stability
```

**Rationale:** Claude already knows stable frameworks (Django, FastAPI, PyTorch) well. Only frameworks with post-training breaking changes (LangChain v1, Transformers v5) need detailed code examples and migration guides.

### Key Breaking Changes Covered

<details>
<summary><b>LangChain v1</b> — <code>create_agent</code> replaces legacy chains</summary>

| Old (0.x) | New (v1+) |
|-----------|-----------|
| `create_react_agent` | `create_agent` |
| `AgentExecutor` | `create_agent` return value |
| `LLMChain`, `ConversationalChain` | LCEL or `create_agent` |
| Manual callbacks | Middleware system |
| `langchain.chains.*` | `langchain-classic` |

New middleware system: `SummarizationMiddleware`, `HumanInTheLoopMiddleware`, `PIIMiddleware`, custom `AgentMiddleware` subclasses.

</details>

<details>
<summary><b>Transformers v5</b> — Multiple renamed APIs</summary>

| Old | New (v5+) |
|-----|-----------|
| `load_in_8bit=True` | `quantization_config=BitsAndBytesConfig(...)` |
| `tokenizer.as_target_tokenizer()` | `tokenizer(text_target=...)` |
| `Trainer(tokenizer=tok)` | `Trainer(processing_class=tok)` |
| `evaluation_strategy="epoch"` | `eval_strategy="epoch"` |
| Fast/Slow tokenizer distinction | Backend architecture (TokenizersBackend, etc.) |

</details>

## Hooks

Automation scripts triggered by Claude Code events.

| Hook Type | Script | Trigger | Purpose |
|-----------|--------|---------|---------|
| `UserPromptSubmit` | `skill-activation.sh` | Every user prompt | Keyword-match → suggest relevant SKILL.md |
| `PostToolUse` | `quality-check.sh` | `Write` or `Edit` tool | Run lint/type check on changed file |

### Skill Activation Flow

```
User prompt (stdin)
    │
    ▼
skill-activation.sh
    │
    ├── Read skill-rules.json (keyword → skill mapping)
    │
    ├── Python: prompt.lower() → keyword match
    │
    └── Output: "Relevant skills detected: ai-engineering"
         → Claude reads ~/.claude/skills/ai-engineering/SKILL.md
```

Keywords are **framework-specific only** — no generic terms like "api", "async", or "websocket" that would trigger false positives across different stacks.

### Quality Check Flow

```
PostToolUse (Write/Edit) → stdin: {tool_input: {file_path: "..."}}
    │
    ├── Extract file path from JSON
    ├── Detect file extension
    ├── Walk up to find project root (pyproject.toml, package.json, .git)
    │
    ├── Python (.py)
    │   ├── .venv/bin/ruff check  (linting)
    │   └── .venv/bin/mypy        (type checking)
    │
    └── TypeScript/JS (.ts/.tsx/.js/.jsx)
        ├── node_modules/.bin/eslint  (linting)
        └── node_modules/.bin/tsc     (type checking, TS only)
```

**Project-local tools only** — hooks look in `.venv/bin/` and `node_modules/.bin/`, never global installations. If tools aren't installed, the hook silently skips.

## Agents

Specialized sub-agents for delegation via Task tool.

| Agent | Role | Output |
|-------|------|--------|
| `code-architecture-reviewer` | Architecture analysis, code quality, security, performance review | Issues by severity (Critical/Warning/Suggestion) |
| `auto-error-resolver` | Error classification, root cause analysis, minimal fix proposal | Root cause + fix + verification steps |
| `web-research-specialist` | Web search with priority sources (official docs → GitHub → context7 → SO) | Answer + sources + caveats |

## Commands

Custom slash commands for context management.

| Command | When to Use | Creates |
|---------|-------------|---------|
| `/dev-docs` | Start of a task — strategic planning | `dev/active/{task}/plan.md`, `context.md`, `tasks.md` |
| `/dev-docs-update` | Before session ends or context fills up | Updates existing docs with current state |

### Context Preservation

```
Session Start                    Session End
    │                                │
    ▼                                ▼
/dev-docs                      /dev-docs-update
    │                                │
    ▼                                ▼
dev/active/{task}/             Update all three files:
├── plan.md       ◀────────── decisions, blockers
├── context.md    ◀────────── files touched, patterns
└── tasks.md      ◀────────── ✅ done, 🔄 in progress
                                     │
                                     ▼
                              ## Next Steps (Resume Here)
                              1. [Exact next action]
                              2. [Second action]
                              3. [Third action]
```

A fresh Claude session reads `tasks.md` and resumes immediately without asking questions.

## Project Structure

```
.claude/
├── CLAUDE.md                              # Global rules (language-agnostic)
├── settings.json                          # Permissions, hooks, plugins
│
├── skills/                                # Domain-specific guidelines
│   ├── ai-engineering/SKILL.md            # LangChain v1 + LangGraph
│   ├── python-backend/SKILL.md            # FastAPI + Django + Channels
│   ├── ml-training/SKILL.md               # PyTorch + Transformers v5
│   └── skill-developer/SKILL.md           # Meta-skill for creating skills
│
├── hooks/                                 # Automation scripts
│   ├── skill-rules.json                   # Keyword → skill mapping rules
│   ├── skill-activation.sh                # Auto-suggest skills on prompt
│   └── quality-check.sh                   # Auto lint/type check on file edit
│
├── agents/                                # Specialized sub-agents
│   ├── code-architecture-reviewer.md      # Code review + architecture analysis
│   ├── auto-error-resolver.md             # Error diagnosis + fix suggestions
│   └── web-research-specialist.md         # Web search + doc research
│
└── commands/                              # Custom slash commands
    ├── dev-docs.md                        # /dev-docs — task planning
    └── dev-docs-update.md                 # /dev-docs-update — context preservation
```

## Installation

### 1. Copy to `~/.claude/`

```bash
git clone https://github.com/<your-username>/claude-code-infrastructure.git
cp -r claude-code-infrastructure/.claude/* ~/.claude/
```

### 2. Make hooks executable

```bash
chmod +x ~/.claude/hooks/skill-activation.sh
chmod +x ~/.claude/hooks/quality-check.sh
```

### 3. Per-project dev tools

Quality check hooks require project-local tools:

```bash
# Python projects
uv add --dev ruff mypy pytest

# TypeScript/JS projects
npm install --save-dev eslint typescript
```

### 4. Install Superpowers plugin (optional)

```
/plugin install superpowers from claude-plugins-official --scope user
/plugin enable superpowers from claude-plugins-official
```

## Customization

### Add a new skill

1. Create `~/.claude/skills/{name}/SKILL.md` with YAML frontmatter
2. Add keywords to `~/.claude/hooks/skill-rules.json`
3. Use the `skill-developer` skill for authoring guidance

```json
{
  "name": "my-new-skill",
  "path": "~/.claude/skills/my-new-skill/SKILL.md",
  "keywords": ["specific-framework", "specific-tool"],
  "filePatterns": ["**/relevant-dir/**"]
}
```

### Project-level overrides

Create `<project>/.claude/CLAUDE.md` for project-specific rules that override global settings.

### Install community skills

Browse and install from [skills.sh](https://skills.sh):

```bash
npx skillsadd vercel-labs/agent-skills/react-best-practices
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Framework-specific keywords only | Generic terms ("api", "websocket") cause false activations across stacks |
| Project-local tools only | Global pip installs pollute environments; `.venv/bin/` ensures isolation |
| Silent skip on missing tools | Hooks should never block Claude — degrade gracefully |
| Differential detail in skills | Don't re-document what Claude already knows; focus on post-training changes |
| 3-file context system | `plan.md` + `context.md` + `tasks.md` = enough to resume any session cold |
| Language-agnostic global rules | `CLAUDE.md` has no framework-specific content — skills handle that |

## References

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [diet103 Infrastructure Showcase](https://github.com/diet103/claude-code-infrastructure-showcase)
- [skills.sh — Agent Skills Directory](https://skills.sh)
