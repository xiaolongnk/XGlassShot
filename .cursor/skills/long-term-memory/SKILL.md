---
name: long-term-memory
description: Maintains project long-term memory by reading and appending to .cursor/memory/MEMORY.md. Use at the start of sessions for context and after substantive conversations to log what was communicated and decided.
---

# Long-term memory

## Location

- **Memory file**: [.cursor/memory/MEMORY.md](.cursor/memory/MEMORY.md) (project root relative)

## When to read

- At the start of a conversation when the user's request may depend on prior work, decisions, or context.
- When the user refers to "what we did before", "last time", or "remember".

## When to append

After **any substantive conversation** (feature work, bugfix, refactor, design decision, or multi-turn Q&A that changes project state or understanding), append one entry to MEMORY.md.

## Entry format

Add under a date section. Use `## YYYY-MM-DD` only when that date does not already exist. Then add a bullet:

```markdown
## YYYY-MM-DD

- **Short title.** One or two sentences: what was requested, what was done, and any decision or follow-up. No need to log trivial single-line replies.
```

Keep entries concise (1–3 sentences). Include: user intent, outcome (e.g. file/feature changed), and decisions or open points if any.

## Rules

- Append by adding to the **bottom** of MEMORY.md (newest last).
- Do not remove or edit older entries except to fix obvious typos.
- If the conversation was trivial (e.g. single clarification, no code or decision), skip appending.
