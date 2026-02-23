# Dev Docs Update — Context Preservation

Save current working context before the session ends or context window fills up.

## Instructions

1. Find the active task directory in `dev/active/`
2. Update all three files with the CURRENT state:

### Update plan.md
- Mark any decisions that were made during this session
- Update approach if it changed
- Note any new blockers discovered

### Update context.md
- Add any new files that were touched
- Update patterns or conventions learned
- Note any environment changes

### Update tasks.md (MOST IMPORTANT)
- Check off completed subtasks
- Add new subtasks discovered during work
- Clearly mark what is IN PROGRESS right now
- Write specific next steps so the next session can resume immediately

## Critical: Next Steps Section

At the bottom of tasks.md, always include:

```markdown
## Next Steps (Resume Here)
1. [Exact next action to take]
2. [Second action]
3. [Third action]

## Current State
- Working on: [what's in progress]
- Blocked by: [any blockers, or "none"]
- Last file edited: [path:line]
```

## When to Run

- When you notice context is getting long
- Before ending a session
- After completing a major subtask
- When Claude suggests running this command

## Format Rules

- Write in English
- Be specific enough that a fresh Claude session can resume without asking questions
- Include exact file paths and line numbers
- Timestamp the update (ISO format)
