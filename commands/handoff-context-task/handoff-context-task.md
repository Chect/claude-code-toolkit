Overwrite `.claude/current-task.md` with a detailed task progress report for the next session.

This file is separate from `.claude/context.md` (general session context) and `.claude/current-bug.md` (bug investigations). Long-running tasks go in `current-task.md` so they persist across many sessions without polluting other context files.

This is designed for multi-session tasks that may span dozens of context windows. Include ALL information needed to continue work without re-reading code or re-tracing decisions.

Include:

1. **Task title and goal** - One-line summary. What the end result should be. Acceptance criteria if known.

2. **Overall progress** - High-level status. What percentage is roughly complete. What phases remain.

3. **Architecture/design decisions** - Decisions made so far and WHY. Include alternatives considered and rejected. This prevents re-litigating the same decisions every session.

4. **What's been completed** - Each completed item with:
   - What was done (brief)
   - Key files created or modified (file:line references)
   - Any gotchas or non-obvious details about the implementation

5. **What's in progress** - Current work item. Where you left off. What the immediate next step is.

6. **What's remaining** - Ordered list of remaining work items. Include enough detail that a fresh session can pick up any item without extensive exploration.

7. **Key code locations** - Every important file and line number for this task. Brief description of what each location does. This is the "map" for navigating the relevant code.

8. **Reference materials** - Documentation, specs, datasheets, manual sections, or reference implementations relevant to this task. Include file paths and section references.

9. **Known issues and constraints** - Problems discovered during implementation. Hardware limitations. Timing constraints. Things that seemed like they'd work but didn't.

10. **Test procedure** - How to verify completed work. Hardware test steps if applicable.

11. **Session log** - Brief log of what each session accomplished. Format:
    ```
    Session N (YYYY-MM-DD): Brief description of what was done
    ```
    This builds up over time and provides a history of the task.

This file will be read at the start of every session until the task is complete. Keep it updated — it IS the task's memory.

When the task is complete, the user can archive or delete `.claude/current-task.md` to clear it.
