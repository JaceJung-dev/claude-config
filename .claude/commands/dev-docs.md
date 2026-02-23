# Dev Docs — Strategic Planning

Create or update the development documentation for the current task.

## Instructions

1. Create the directory `dev/active/$TASK_NAME/` in the project root if it doesn't exist
2. Create or update three files:

### plan.md
- Task objective and scope
- Architecture decisions made
- Approach and implementation strategy
- Open questions or blockers

### context.md
- Key files involved and their roles
- Important patterns/conventions discovered
- Dependencies and relationships between components
- Environment or configuration notes

### tasks.md
- Checklist of subtasks (use `- [ ]` / `- [x]` format)
- Current progress status
- Next steps to take when resuming

## Format Rules

- Write in English
- Be concise — future you (or Claude) needs to resume quickly
- Include file paths with line numbers for key locations
- Mark completed items, note what's in progress
- If context window is getting full, prioritize saving tasks.md and context.md

## Usage

Run this command at the START of a task to plan, or when you need to restructure your approach.
