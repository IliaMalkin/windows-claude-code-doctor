param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
if (-not $resolved) {
    Write-Error "Path not found: $Path"
    exit 2
}

$target = $resolved.Path
"Target: $target"

$handle = Get-Command handle.exe -ErrorAction SilentlyContinue
if ($handle) {
    "Using Sysinternals handle.exe:"
    & $handle.Source -nobanner $target
    exit $LASTEXITCODE
}

"handle.exe not found on PATH. Showing common processes that often hold workspace files:"
Get-Process |
    Where-Object { $_.ProcessName -match 'node|npm|pnpm|yarn|python|dotnet|java|code|cursor|devenv|msbuild|git|sqlite|claude|codex' } |
    Select-Object Id, ProcessName, Path |
    Sort-Object ProcessName |
    Format-Table -AutoSize

"Install Sysinternals handle.exe for exact handle ownership, or close editors/watchers/indexers touching the target."
