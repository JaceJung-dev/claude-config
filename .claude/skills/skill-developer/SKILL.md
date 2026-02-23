---
name: skill-developer
description: Meta-skill for creating, evaluating, and iterating on Claude Code skills. Use when building new SKILL.md files, designing skill architecture, or optimizing existing skills. Triggers on tasks involving skill creation, skill authoring, SKILL.md writing, or skill optimization.
---

# Skill Developer

Create and maintain Claude Code skills following Anthropic's official best practices.

## When to Apply

- Creating new skills
- Reviewing or optimizing existing skills
- Designing skill directory structure

## Core Principles (from Anthropic Official Guide)

### 1. Concise is Key
> "Claude is already very smart. Only add context Claude doesn't already have."

Challenge each piece of information:
- Does Claude really need this explanation?
- Can I assume Claude knows this?
- Does this paragraph justify its token cost?

### 2. Progressive Disclosure
- SKILL.md = table of contents (under 500 lines)
- Detailed content → separate files in the skill directory
- Claude reads SKILL.md when triggered, additional files only as needed
- Keep references one level deep (SKILL.md → file.md, never file.md → another.md)

### 3. Match Freedom to Fragility
- **High freedom** (prose): Multiple valid approaches, context-dependent
- **Medium freedom** (pseudocode): Preferred pattern exists, some variation OK
- **Low freedom** (exact script): Fragile operations, consistency critical

## SKILL.md Structure

```markdown
---
name: lowercase-with-hyphens    # max 64 chars, no "anthropic"/"claude"
description: Third-person, specific, includes when to use. Max 1024 chars.
---

# Skill Title

## When to Apply
[Trigger conditions]

## Core Rules / Patterns
[What Claude doesn't already know]

## Anti-Patterns
[What to avoid — WRONG vs CORRECT if needed]

## Project Structure
[Directory conventions if applicable]

## Before Implementing
[Verification steps, context7 references]

## See Also
[Links to resources/ files for details]
```

## Naming Convention

Prefer gerund form: `processing-pdfs`, `analyzing-data`, `building-agents`

## Description Guidelines

- Write in **third person** (not "I can" or "You can")
- Include **what** it does AND **when** to use it
- Include trigger keywords for discovery
- Be specific, not vague ("Helps with documents" = bad)

## Skill Archetypes

| Type | Lines | Code | Best For |
|------|-------|------|----------|
| Index/Manifest | ~120 | None (refs external files) | Large rule sets |
| Behavioral | ~50 | None | Creative/process direction |
| Technical Reference | ~200-300 | Many examples | Framework-specific guides |
| Hybrid | ~100-150 | Key patterns only | Most skills |

## Differential Detail Rule

- Framework Claude knows well (Django, React) → **concise** (rules + anti-patterns)
- Framework with recent breaking changes (LangChain v1) → **detailed** (code examples)
- Creative/process skills → **behavioral** (prose, no code)

## Iteration Process

1. Complete a task without a Skill → note what context you repeatedly provide
2. Create minimal SKILL.md addressing gaps
3. Test with real tasks
4. Observe: Does Claude follow the rules? Miss anything?
5. Iterate based on observed behavior, not assumptions

## Anti-Patterns

- **Do NOT** explain things Claude already knows
- **Do NOT** exceed 500 lines in SKILL.md
- **Do NOT** nest references deeper than one level
- **Do NOT** include time-sensitive information
- **Do NOT** use inconsistent terminology
- **Do NOT** offer too many equivalent options — provide a default

## See Also

- Anthropic official guide: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- `resources/skill-template.md` for blank template
