Overwrite `.claude/current-bug.md` with a detailed bug investigation report for the next session.

This file is separate from `.claude/context.md` (general session context). Bug investigations go in `current-bug.md` so they can be cleared independently when the bug is resolved without losing general project context.

This is a verbose, investigation-focused handoff. Include ALL information needed to continue debugging without re-reading code or re-tracing logic.

Include:

1. **Bug title and symptoms** - What the user observes. Exact button sequence or steps to reproduce. What should happen vs what does happen.

2. **Root cause analysis** - What you've determined so far. Include:
   - The specific code path that executes (function call chain with file:line references)
   - What each function does in the chain
   - Where the behavior diverges from expected
   - Any reference implementation analysis (original source, what it does differently)

3. **State machine context** - For state-related bugs:
   - What state value(s) are involved
   - What transitions occur and in what order
   - Any flag values that matter

4. **Changes made so far** - Every file:line changed, what the old code was, what the new code is, and WHY. Include the exact diff if possible.

5. **What worked and what didn't** - Results of each test attempt. What the user reported after each change.

6. **Debug traces added** - List any debug output calls added, what they trace, and what output to look for.

7. **Open questions** - What you still don't know. What needs to be verified. What the next debugging step should be.

8. **Key code locations** - Every file and line number referenced during the investigation. Include brief description of what each location does.

9. **Reference implementation** - Relevant original/reference code, locations, and how the original behavior works.

10. **Test procedure** - Step-by-step instructions to reproduce the bug and verify a fix.

This file will be read at the start of the next session. Be thorough — assume the next session has NO context about this bug.

When the bug is resolved, the user can simply delete `.claude/current-bug.md` to clear it.
