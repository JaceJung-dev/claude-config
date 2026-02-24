# Global Rules

## Language
- Communicate in Korean
- Code comments, variable names, and commit messages may be in English

## Workflow
- Always ask for confirmation before committing
- Commit messages: conventional commits (feat/fix/refactor/test/docs)
- Use plan mode before large-scale changes
- Ask clarifying questions before implementing ambiguous requirements
- Never implement based on assumptions

## Code Principles
- Understand existing code patterns first and follow them
- Do not modify files/modules outside the requested scope
- Notify before expanding the scope of changes
- Handle errors with specific exceptions only (no bare except)
- Do not add excessive comments/docstrings that don't match the existing style
- Default docstring style: Google-style
- Never commit .env or credential files

## Dev Docs
- Context preservation: use dev/active/[task-name]/ structure
- 3-file system: plan.md, context.md, tasks.md
