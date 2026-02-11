# Project long-term memory

Persistent log of conversations, decisions, and context. Newest at bottom.

---

## 2025-02-11

- **Long-term memory implemented.** Added `.cursor/memory/MEMORY.md` and skill `long-term-memory`. Agent should read this file when context is needed and append a short dated entry after substantive conversations (what was asked, what was done, decisions).
- **User requested:** "note every communication in our memory." Implemented: (1) `.cursor/memory/MEMORY.md` as the single running log, newest at bottom; (2) skill `long-term-memory` that instructs the agent to read memory when context helps and to append one concise entry after each substantive conversation (request + what was done + decisions). Trivial single-line exchanges are not logged.
- **DockToggle.swift fix.** User reported: `Value of type 'Material' has no member 'clipShape'` at line 28. Cause: `Material` is a `ShapeStyle`, not a `View`. Fixed by replacing `Theme.cardMaterial(...).clipShape(Capsule())` with `Capsule().fill(Theme.cardMaterial(...))` for the tooltip background.
- **User requested:** (1) Update this fix into memory (done above). (2) Note every conversation in memory — skill updated so the agent appends an entry after every conversation, not only substantive ones.
- **Two-monitor selection bug.** On the second monitor, first click did not start rectangle selection (required two clicks). Cause: the key window was not the one under the cursor, so the first click was consumed to make that window key. Fix in SelectionOverlay.show(): after creating overlay windows, use NSEvent.mouseLocation to find the screen under the cursor, then call makeKeyAndOrderFront(nil) on that screen’s window so the first click starts the drag. Changed loop to orderFront(nil) only; key is assigned to the window under the mouse (fallback: first window).
