# PowerShell Agent Gotchas

Use this reference when an AI coding agent writes Bash syntax into PowerShell or cmd.exe.

## Command Translation

| Bash habit | PowerShell replacement |
| --- | --- |
| `ls -la` | `Get-ChildItem -Force` |
| `rm -rf path` | `Remove-Item -LiteralPath path -Recurse -Force` |
| `mkdir -p path` | `New-Item -ItemType Directory -Force -Path path` |
| `cat file` | `Get-Content -Path file` |
| `grep pattern` | `Select-String -Pattern pattern` |
| `$VAR` | `$env:VAR` for environment variables |
| `cmd1 && cmd2` | `cmd1; if ($LASTEXITCODE -eq 0) { cmd2 }` for native executables |
| `2>/dev/null` | `2>$null` |
| `which node` | `Get-Command node` |

## Native Executables

PowerShell cmdlets and native executables have different success semantics:

- `$?` is PowerShell pipeline success.
- `$LASTEXITCODE` is the exit code from the last native executable.
- Some native tools write important diagnostics to stderr even when exit code is 0.

For agent-visible diagnostics, prefer `scripts/invoke-native.ps1 -- <command>`.

## Quoting

- Prefer single quotes for literal strings.
- Use `-LiteralPath` for file operations when paths may contain brackets, wildcards, or special characters.
- Use here-strings for multi-line content:

```powershell
$text = @'
line 1
line 2
'@
```

## Execution Policy

If a local script is blocked, do not weaken machine policy first. Prefer:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\script.ps1
```

Use machine-wide policy changes only when the user explicitly wants that.
