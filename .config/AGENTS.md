# Project Instructions — Rice & Dotfiles (Hyprland / Quickshell)

## 0. Non-negotiables (Project-Specific)
- Global `~/.agent-protocols/CARD.md` is the authoritative safety set. On conflict, follow the more restrictive rule and report it.
- **Rule 1 (Explicit Staging Only)**: NEVER execute blanket staging commands such as `yadm add .` or `yadm add -A` across `$HOME`. Stage only explicitly targeted configuration files.
- **Rule 2 (Secrets & Privacy Boundary)**: NEVER track sensitive credentials, private keys, authentication tokens, or personal data directories (e.g. `.ssh/`, `.gnupg/`, `.git-credentials`, `Documents/`, `Pictures/`). Refer to `.config/yadm/ignore`.
- **Rule 3 (Branch Protection & Workflow Flexibility)**: NEVER commit or push directly to `main`. Always create and operate within dedicated topic branches (e.g. `feat/quickshell-*`).
- **Rule 3.1 (Boss Exemption / Dotfiles Prerogative)**: By decree of the BIG BOSS (user), dotfiles management adheres to a relaxed and pragmatic workflow. Granularity may be adjusted flexibly, and automated push/PR creation on topic branches is explicitly pre-approved without requiring rigid step-by-step gate stops for every minor action.
- **Rule 4 (Scope Isolation)**: This repository manages user configuration and rice components (with primary active focus on `.config/quickshell`). Any standalone programs, tools, or custom services must be developed in separated isolated workspaces.
- **Language**: Deliverables (code, comments, commits, PRs, docs) strictly in English. Human interaction strictly in Japanese.

## 1. First 5 Minutes (Immediate Verification)
1. Verify working branch: `yadm status -s && yadm branch --show-current` (Confirm NOT on `main` before editing).
2. Check uncommitted diffs before starting any new task.
3. Run target verification command (Exit 0 required).
4. Hard limiter: Stop and report after 5 attempts on the same failure signature.

## 2. Roles & Archetypes
- **Orchestrator (Gemini)**: Macro scoping, Deliberation Gate reporting, user alignment, and safety auditing.
- **Implementer (OpenCode / Coder)**: Minimal diffs, QML/Lua/Shell script modifications, lint/runtime verification.
- **Reasoner (Auditor)**: Concurrency, UI performance, event loop checks, and safe degradation.

## 3. Architecture & Workspace Topology
- **Manager**: `yadm` managing dotfiles rooted in `$HOME`.
- **Primary Rice Component**: `.config/quickshell/`
  - `shell.qml`: Root entry point.
  - `layers/`: Wayland/Hyprland shell layers (TopBar, popups, widgets).
  - `components/`: Modular UI widgets (Workspaces, Clock, etc.).
  - `services/`: State collectors and backend listeners (HyprlandState, TimeService, etc.).
- **Related Rice Configs**: `.config/hypr/`, `.config/kitty/`, `.config/eww/` (reference/legacy).

## 4. Key Verification Commands (Fluid & Modular)
Verification commands are maintained dynamically based on active work targets:
- **Quickshell Syntax & Static Check**:
  ```bash
  qmllint /home/yukkkk1/.config/quickshell/shell.qml /home/yukkkk1/.config/quickshell/components/*.qml /home/yukkkk1/.config/quickshell/layers/*.qml /home/yukkkk1/.config/quickshell/services/*.qml
  ```
- **Quickshell Runtime Test (Foreground / Isolated)**:
  ```bash
  quickshell -p /home/yukkkk1/.config/quickshell/shell.qml
  ```

## 5. Fallback Safety Set
If `~/.agent-protocols/CARD.md` is unavailable:
1. Never commit or push directly to `main`; always use topic branches.
2. Irreversible or outward actions require explicit human approval.
3. Dialogue in Japanese; deliverables in English.
4. Stop on 5 consecutive failures of the same error signature.
