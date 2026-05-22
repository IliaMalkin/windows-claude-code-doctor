# Windows Agent Gotchas Checklist

Use this as a pre-flight checklist before a long agent run on Windows.

- Confirm shell: PowerShell, cmd.exe, Git Bash, or WSL.
- Confirm workspace path form matches the shell.
- Confirm `node`, `npm`, `python`, `git`, and `code` resolve from the intended runtime.
- Run `git status --short` and avoid full `git diff` if many files look modified.
- Check the dev server port before starting a new server.
- Stop watchers before deleting `node_modules`, build output, SQLite files, or lock-heavy directories.
- For SQLite local tests on Windows, know whether WAL sidecar files are expected.
- Quote paths with spaces and use `-LiteralPath` in PowerShell file operations.
