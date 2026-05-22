param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Command
)

if (-not $Command -or $Command.Count -eq 0) {
    Write-Error "Usage: .\invoke-native.ps1 -- <command> [args...]"
    exit 64
}

if ($Command[0] -eq "--") {
    $Command = $Command[1..($Command.Count - 1)]
}

$exe = $Command[0]
$args = @()
if ($Command.Count -gt 1) {
    $args = $Command[1..($Command.Count - 1)]
}

$stdoutFile = [System.IO.Path]::GetTempFileName()
$stderrFile = [System.IO.Path]::GetTempFileName()

try {
    $process = Start-Process -FilePath $exe -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
    $stdout = Get-Content -Path $stdoutFile -Raw -ErrorAction SilentlyContinue
    $stderr = Get-Content -Path $stderrFile -Raw -ErrorAction SilentlyContinue

    "Command: $($Command -join ' ')"
    "ExitCode: $($process.ExitCode)"
    "----- stdout -----"
    if ($stdout) { $stdout.TrimEnd() }
    "----- stderr -----"
    if ($stderr) { $stderr.TrimEnd() }

    exit $process.ExitCode
}
finally {
    Remove-Item -LiteralPath $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
}
