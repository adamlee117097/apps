# Decisions

Each entry: date, decision, reason. Newest at the bottom.

## 2026-11-25: Project lives in `necromancer-tactics/` for now

- **Decision:** Keep all project files inside the `necromancer-tactics/`
  subdirectory of `adamlee117097/apps`, on branch `claude/new-session-jfevon`.
- **Reason:** The session was started against `adamlee117097/apps`, whose root
  is an existing Pixlet apps repository with its own `README.md`, `.gitignore`
  and CI. Writing the game's files at the root would overwrite those. A
  subdirectory touches nothing that exists and can be moved to a dedicated
  repository later.
- **Status:** Provisional. Made by Claude to avoid blocking; Adam to confirm or
  name a dedicated repository.

## 2026-11-25: Separate cloud environment for research

- **Decision:** Created a personal Claude Code cloud environment
  `necromancer-tactics` that allows `www.apple.com`, `support.apple.com`,
  `docs.godotengine.org`, `godotengine.org`, `docs.unity3d.com`, `unity.com`.
- **Reason:** The default environment blocked these hosts, and the brief
  requires primary sources. Adam approved it on the approval prompt.

## Gates

| Gate | Status | Date | Outcome |
|---|---|---|---|
| GATE 1: engine, build pipeline, feature feasibility | Not reached | | |
| GATE 2: GDD review, items in brief 3.5 | Not reached | | |
| GATE 3: vertical slice played on device | Not reached | | |
