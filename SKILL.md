---
name: windows-claude-code-doctor
description: Diagnose and fix Windows-specific AI coding agent failures in Claude Code, Codex CLI, Cursor, OpenClaw, VS Code agents, and similar tools. Use when an agent is on Windows, PowerShell, cmd.exe, Git Bash, MSYS2, or WSL and hits Linux command leakage, broken path translation, WSL/native runtime confusion, PowerShell exit-code loss, CRLF diff/context pollution, SQLite database locks, EADDRINUSE ports, EBUSY/EPERM file locks, Defender interference, or Git Bash/IDE integration failures.
---

# Windows Claude Code Doctor

Use this skill to turn vague "AI coding agent is broken on Windows" reports into a shell-aware diagnosis and a small, testable fix.

This is a Productivity/DevOps skill for AI coding agents, not a general Windows setup guide. Keep the work scoped to failures that block agent coding loops: running commands, editing files, seeing diffs, starting dev servers, running tests, and cleaning up local resources.

## Triage First

Run this three-question triage before editing code or retrying commands:

1. Identify the execution environment: PowerShell, cmd.exe, Git Bash/MSYS2, WSL, or a VS Code/IDE agent shell.
2. Classify the failure: command syntax, path translation, runtime mismatch, exit-code capture, line endings, database/file lock, or port conflict.
3. Prefer the matching bundled script before writing a one-off diagnostic.

Useful scripts:

- `scripts/diagnose-shell.ps1` - detect shell, OS, common tools, command translation risk.
- `scripts/convert-agent-path.ps1` - convert Windows, WSL, MSYS/Git Bash, and UNC-style paths.
- `scripts/detect-runtime.ps1` - detect WSL/native mismatch for node, npm, python, git, and code.
- `scripts/invoke-native.ps1` - run native commands and preserve stdout, stderr, and exit code for the agent.
- `scripts/check-line-endings.ps1` - find CRLF/LF churn before `git diff` pollutes context.
- `scripts/check-sqlite-locks.ps1` - inspect SQLite journal mode and sidecar lock files.
- `scripts/find-port-holder.ps1` - map a port to the owning process.
- `scripts/find-file-handle.ps1` - find common local processes likely holding a file or directory.

## Cross-Agent Use

Use the same playbooks in Claude Code, Codex CLI, Cursor, OpenClaw, VS Code agents, and terminal-based coding agents. Adapt only the command runner:

- From PowerShell: run scripts as `.\scripts\name.ps1`.
- From cmd.exe: run scripts as `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\name.ps1`.
- From Git Bash/MSYS2: run scripts through `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/name.ps1` when diagnosing Windows-native resources.
- From WSL: use Linux tools for Linux resources; call `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <windows-path-to-script>` only when inspecting Windows-native paths, ports, Git Bash, Defender, or Windows processes.

Do not assume the agent's brand determines the shell. Always diagnose the actual runtime.

## Playbooks

### 1. Linux Commands Leaking Into Windows

Symptoms: `ls`, `rm -rf`, `mkdir -p`, `grep`, `$VAR`, `2>/dev/null`, here-docs, or `&&` fail in PowerShell/cmd.exe.

Run:

```powershell
.\scripts\diagnose-shell.ps1
```

Rules:

- In PowerShell, use `Get-ChildItem`, `Remove-Item`, `New-Item -ItemType Directory`, `$env:NAME`, `$LASTEXITCODE`, and `if ($?) { ... }`.
- Use `;` for sequencing. Use `if ($LASTEXITCODE -eq 0) { ... }` when the second command depends on a native executable succeeding.
- Do not use Bash here-docs in PowerShell. Use PowerShell here-strings or temporary files.
- If the agent is intentionally using Git Bash, verify the command is actually running under Git Bash/MSYS2, not PowerShell.

More detail: read `references/powershell-agent-gotchas.md`.

### 2. Path Translation Breaks Tool Calls

Symptoms: edit tools fail mid-session, `/mnt/c/...` and `C:\...` get mixed, `D:\dev` becomes `D:\d\dev`, spaces in `Program Files` break hooks, UNC paths behave differently.

Run:

```powershell
.\scripts\convert-agent-path.ps1 -Path "C:\Users\me\project\file.ts" -Target wsl
.\scripts\convert-agent-path.ps1 -Path "/mnt/c/Users/me/project/file.ts" -Target windows
```

Rules:

- Convert paths at the boundary where the tool runs, not where the prompt was written.
- Quote every path with spaces. In PowerShell prefer `-LiteralPath`.
- Treat UNC paths (`\\server\share`) as Windows-native unless the active runtime explicitly supports them.
- In WSL, Windows drives are usually under `/mnt/<drive-letter>/`.

More detail: read `references/path-normalization.md`.

### 3. WSL vs Native Runtime Confusion

Symptoms: `node not found`, wrong `npm`, Windows `code.exe` expected but Linux `code` runs, VS Code diff/IDE integration works only in WSL or only native.

Run:

```powershell
.\scripts\detect-runtime.ps1
```

Rules:

- Do not mix package installs between WSL and Windows unless the repo explicitly supports it.
- If the workspace is under `/mnt/c`, confirm whether the agent should use Linux tools against Windows files.
- When a tool must be Windows-native from WSL, call it explicitly via `cmd.exe /c`, `powershell.exe -NoProfile -Command`, or the full `.exe` path.

### 4. PowerShell Exit Code Is Lost

Symptoms: agent reports success after a failed native command, CI fails locally but agent continues, stderr redirection hides the real problem.

Run native commands through:

```powershell
.\scripts\invoke-native.ps1 -- npm test
.\scripts\invoke-native.ps1 -- git diff --check
```

Rules:

- `$?` answers whether the last PowerShell pipeline succeeded; native tools need `$LASTEXITCODE`.
- Avoid Bash-style `2>&1` habits when the distinction between stdout and stderr matters.
- Always show the command, exit code, and a short tail of stderr before proposing a fix.

### 5. CRLF Diff Churn Pollutes Agent Context

Symptoms: `git diff` shows many files with no semantic changes, LF/CRLF warnings, context explodes after a whitespace-only diff.

Run before large diffs:

```powershell
.\scripts\check-line-endings.ps1 -Path .
git diff --check
```

Rules:

- Inspect `git diff --numstat` before reading full diffs.
- Fix policy in `.gitattributes`; do not normalize the whole repository during an unrelated task.
- If context is already polluted, start a fresh session after committing or stashing the line-ending-only cleanup.

More detail: read `references/crlf-context-pollution.md`.

### 6. SQLite Lock Loop on Windows

Symptoms: `database is locked`, `.wal` or `.shm` sidecar files remain, tests hang after a previous agent run, Windows file locking keeps the DB busy.

Run:

```powershell
.\scripts\check-sqlite-locks.ps1 -Database .\path\to\app.db
```

Rules:

- Check for live processes before deleting sidecar files.
- For local agent/test workflows on Windows, consider `PRAGMA journal_mode=DELETE;` when WAL sidecars create repeated lock loops.
- Keep production defaults separate from Windows-local test mitigations.

More detail: read `references/sqlite-windows.md`.

### 7. Resource Locks: Ports and Files

Symptoms: `EADDRINUSE`, `bind: address already in use`, `EBUSY`, `EPERM`, file cannot be deleted, dev server refuses to start.

Run:

```powershell
.\scripts\find-port-holder.ps1 -Port 3000
.\scripts\find-file-handle.ps1 -Path .\node_modules
```

Rules:

- Identify the process before killing anything.
- On Windows, Defender, indexers, editors, preview panes, test watchers, and dev servers commonly hold files.
- Prefer stopping the owning app gracefully. Use forced termination only when the process is clearly disposable.

## Output Pattern

When using this skill, report:

- `Environment`: shell, OS, WSL/native state, working directory.
- `Failure class`: one of the seven playbooks above.
- `Evidence`: exact command/script output that supports the diagnosis.
- `Fix`: smallest safe change or command.
- `Verification`: command that proves the issue is gone.

Keep the answer practical. Avoid broad Windows setup essays unless the evidence points to a machine-wide configuration problem.
