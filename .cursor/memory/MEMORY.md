# Project long-term memory

Persistent log of conversations, decisions, and context. Newest at bottom.

---

## 2025-02-11

- **Long-term memory implemented.** Added `.cursor/memory/MEMORY.md` and skill `long-term-memory`. Agent should read this file when context is needed and append a short dated entry after substantive conversations (what was asked, what was done, decisions).
- **User requested:** "note every communication in our memory." Implemented: (1) `.cursor/memory/MEMORY.md` as the single running log, newest at bottom; (2) skill `long-term-memory` that instructs the agent to read memory when context helps and to append one concise entry after each substantive conversation (request + what was done + decisions). Trivial single-line exchanges are not logged.
