# windows-claude-code-doctor

A diagnostic skill for AI coding agents on Windows. Turns vague "Claude Code is broken on Windows" reports into a shell-aware diagnosis and a small, testable fix.

Works with Claude Code, Codex CLI, Cursor, OpenClaw, VS Code agents, and any terminal-based coding agent that drives PowerShell, cmd.exe, Git Bash, MSYS2, or WSL.

## Why this exists

AI coding agents are still mostly built and tested on Linux and macOS. When the same agent runs on Windows, it breaks in seven recurring ways that look like model failures but are really shell and platform failures:

- Linux command syntax leaking into PowerShell (`ls`, `rm -rf`, `$VAR`, here-docs, `&&`).
- Path translation drift between Windows, WSL, MSYS/Git Bash, and UNC paths.
- WSL vs native runtime confusion for `node`, `npm`, `python`, `git`, `code`.
- PowerShell silently losing the exit code of a native command.
- CRLF/LF churn polluting `git diff` and burning the agent's context window.
- SQLite `database is locked` loops caused by `.wal` / `.shm` sidecars and Windows file locking.
- Resource locks: `EADDRINUSE` on ports, `EBUSY` / `EPERM` on files held by Defender, indexers, editors, or test watchers.

This skill encodes those seven failure classes in `SKILL.md` and backs them with small PowerShell diagnostics. An agent that loads the skill stops guessing and starts diagnosing.

## What's inside

```
windows-claude-code-doctor/
├── SKILL.md                 # Skill entry point: triage, failure classes, output pattern.
├── scripts/                 # PowerShell diagnostics for the common Windows failure modes.
│   ├── diagnose-shell.ps1
│   ├── convert-agent-path.ps1
│   ├── detect-runtime.ps1
│   ├── invoke-native.ps1
│   ├── check-line-endings.ps1
│   ├── check-sqlite-locks.ps1
│   ├── find-port-holder.ps1
│   └── find-file-handle.ps1
├── references/              # Deeper notes per failure class.
│   ├── powershell-agent-gotchas.md
│   ├── path-normalization.md
│   ├── crlf-context-pollution.md
│   ├── sqlite-windows.md
│   └── gotchas-checklist.md
└── agents/
    └── openai.yaml          # OpenAI-compatible agent definition.
```

## Install

### As a Claude Code skill

Drop the folder under `~/.claude/skills/` (or your configured skills directory) so Claude Code discovers it:

```powershell
Copy-Item -Recurse .\windows-claude-code-doctor $env:USERPROFILE\.claude\skills\
```

The skill activates whenever an agent is on Windows and hits one of the seven failure classes.

### As a standalone toolkit

Clone and run the scripts directly:

```powershell
git clone https://github.com/IliaMalkin/windows-claude-code-doctor.git
cd windows-claude-code-doctor
.\scripts\diagnose-shell.ps1
```

All scripts are pure PowerShell (Windows PowerShell 5.1 and PowerShell 7+), no installs required.

## Quick triage

Before retrying a failed command, answer three questions:

1. **What shell is actually running?** PowerShell, cmd.exe, Git Bash/MSYS2, WSL, or an IDE-spawned shell. Brand of the agent does not tell you this — `diagnose-shell.ps1` does.
2. **Which failure class?** One of the seven above.
3. **Is there a bundled script for it?** If yes, run it before writing a one-off diagnostic.

The full triage flow, command examples, and per-class rules live in `SKILL.md`.

## Example: SQLite lock loop

Symptom: `database is locked` on every test run, `.wal` and `.shm` files keep reappearing, tests pass on macOS CI.

```powershell
.\scripts\check-sqlite-locks.ps1 -Database .\app.db
```

The script reports the journal mode, lists any processes holding sidecar files, and tells you whether deleting them is safe right now. Documentation on the underlying Windows file-locking behavior is in `references/sqlite-windows.md`.

## Example: PowerShell exit code lost

Symptom: agent reports a successful build, but `npm test` actually failed.

```powershell
.\scripts\invoke-native.ps1 -- npm test
```

The wrapper preserves stdout, stderr, and `$LASTEXITCODE` separately so the agent sees the real result. Background: `references/powershell-agent-gotchas.md`.

## Output pattern

When using this skill an agent should report:

- **Environment**: shell, OS, WSL/native state, working directory.
- **Failure class**: one of the seven failure classes.
- **Evidence**: exact command/script output that supports the diagnosis.
- **Fix**: smallest safe change or command.
- **Verification**: command that proves the issue is gone.

Keep answers practical. Avoid broad Windows setup essays unless the evidence points to a machine-wide configuration problem.

## Scope

In scope: failures that block an agent's coding loop — running commands, editing files, seeing diffs, starting dev servers, running tests, cleaning up local resources.

Out of scope: general Windows configuration, GPU/driver issues, Windows Update problems, Active Directory, enterprise group policy.

## Compatibility

| Shell / Runtime | Status |
| --- | --- |
| Windows PowerShell 5.1 | Supported |
| PowerShell 7+ | Supported |
| cmd.exe | Call scripts via `powershell -NoProfile -ExecutionPolicy Bypass -File ...` |
| Git Bash / MSYS2 | Call scripts via `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...` |
| WSL | Use for inspecting Windows-native resources from inside WSL |

## License

MIT.

## Author

[@IliaMalkin](https://github.com/IliaMalkin)
