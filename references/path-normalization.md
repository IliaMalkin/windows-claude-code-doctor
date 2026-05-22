# Path Normalization

Use this when an agent, hook, plugin, or IDE passes paths across Windows, WSL, Git Bash, and MSYS2 boundaries.

## Common Forms

| Form | Example | Runtime |
| --- | --- | --- |
| Windows drive | `C:\Users\V\repo` | PowerShell, cmd.exe, Windows tools |
| WSL mount | `/mnt/c/Users/V/repo` | WSL Linux tools |
| MSYS/Git Bash | `/c/Users/V/repo` | Git Bash/MSYS2 |
| UNC | `\\server\share\repo` | Windows network path |

## Rules

- Convert to the runtime that will open the file.
- Do not feed `C:\...` directly to Linux tools inside WSL.
- Do not feed `/mnt/c/...` to Windows-native tools unless the tool explicitly understands WSL paths.
- Quote paths with spaces at the final command boundary.
- Avoid string concatenation for paths in PowerShell; prefer `Join-Path`.

## Agent Prompt Pattern

When a Windows path is pasted into a WSL session:

```text
Convert Windows paths to WSL before accessing files. Example:
C:\Users\V\Pictures\a.png -> /mnt/c/Users/V/Pictures/a.png
```

When a WSL path must be used by Windows tools:

```text
Convert WSL paths to Windows before calling Windows-native tools. Example:
/mnt/c/Users/V/project -> C:\Users\V\project
```
