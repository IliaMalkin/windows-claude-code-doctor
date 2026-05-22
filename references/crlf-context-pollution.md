# CRLF Context Pollution

Use this when `git diff` suddenly becomes huge after an agent works in Windows plus WSL, Git Bash, or mixed editor settings.

## Why It Matters For Agents

Line-ending churn can make every touched file appear modified. AI coding agents often read the full diff into context, so whitespace-only CRLF/LF changes can consume the context window and hide the real code change.

## Safe Sequence

1. Run `git status --short`.
2. Run `git diff --numstat` before reading full diffs.
3. Run `git diff --check` for whitespace warnings.
4. Run `scripts/check-line-endings.ps1 -Path .` for a repository scan.
5. If many files changed only by line endings, stop feature work and create a separate normalization change.

## Policy

Prefer a repository-level `.gitattributes` policy:

```gitattributes
* text=auto
*.ps1 text eol=crlf
*.sh text eol=lf
*.cmd text eol=crlf
*.bat text eol=crlf
*.js text eol=lf
*.ts text eol=lf
*.json text eol=lf
*.md text eol=lf
```

Set `core.autocrlf` deliberately:

```powershell
git config --get core.autocrlf
```

Do not change global Git config unless the user asks for a machine-wide policy.
