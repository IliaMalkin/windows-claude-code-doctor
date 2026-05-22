param(
    [Parameter(Mandatory = $true)]
    [string]$Database
)

$dbPath = Resolve-Path -LiteralPath $Database -ErrorAction SilentlyContinue
if (-not $dbPath) {
    Write-Error "Database not found: $Database"
    exit 2
}

$full = $dbPath.Path
$sidecars = @("$full-wal", "$full-shm", "$full-journal")

[pscustomobject]@{
    Database = $full
    Exists = Test-Path -LiteralPath $full
    SizeBytes = (Get-Item -LiteralPath $full).Length
} | Format-List

"SQLite sidecar files:"
"---------------------"
$sidecarResults = foreach ($path in $sidecars) {
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Path = $path
        Exists = [bool]$item
        SizeBytes = if ($item) { $item.Length } else { 0 }
        LastWriteTime = if ($item) { $item.LastWriteTime } else { $null }
    }
}
$sidecarResults | Format-Table -AutoSize

"Likely related processes:"
"-------------------------"
Get-Process |
    Where-Object { $_.ProcessName -match 'node|python|sqlite|dotnet|java|code|cursor|claude|codex' } |
    Select-Object Id, ProcessName, Path |
    Sort-Object ProcessName |
    Format-Table -AutoSize

$sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
if ($sqlite) {
    "PRAGMA journal_mode:"
    & sqlite3 $full "PRAGMA journal_mode;"
} else {
    "sqlite3 not found on PATH; skipping PRAGMA journal_mode check."
}
