param(
    [string]$Path = ".",
    [int]$MaxFiles = 5000
)

$root = Resolve-Path -LiteralPath $Path
$skipDirs = @(".git", "node_modules", ".next", "dist", "build", "coverage", ".venv", "venv")
$extensions = @(".ps1", ".cmd", ".bat", ".sh", ".js", ".jsx", ".ts", ".tsx", ".json", ".md", ".yml", ".yaml", ".py", ".cs", ".go", ".rs", ".java", ".html", ".css")

$files = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $full = $_.FullName
        -not ($skipDirs | Where-Object { $full -match [regex]::Escape("\$_\") }) -and
        $extensions -contains $_.Extension.ToLowerInvariant()
    } |
    Select-Object -First $MaxFiles

$results = foreach ($file in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes.Length -eq 0) { continue }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $crlf = ([regex]::Matches($text, "`r`n")).Count
    $withoutCrlf = $text -replace "`r`n", ""
    $lf = ([regex]::Matches($withoutCrlf, "`n")).Count
    if ($crlf -gt 0 -or $lf -gt 0) {
        [pscustomobject]@{
            Path = $file.FullName
            CRLF = $crlf
            LFOnly = $lf
            Mixed = ($crlf -gt 0 -and $lf -gt 0)
        }
    }
}

$summary = [pscustomobject]@{
    Root = $root.Path
    Scanned = @($files).Count
    WithMixedEndings = @($results | Where-Object Mixed).Count
    WithCRLF = @($results | Where-Object { $_.CRLF -gt 0 }).Count
    WithLFOnly = @($results | Where-Object { $_.LFOnly -gt 0 }).Count
}

$summary | Format-List
$results |
    Sort-Object -Property @{Expression = "Mixed"; Descending = $true}, Path |
    Select-Object -First 100 |
    Format-Table -AutoSize
