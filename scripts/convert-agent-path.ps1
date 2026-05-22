param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [ValidateSet("windows", "wsl", "msys")]
    [string]$Target
)

function Convert-ToWindowsPath([string]$InputPath) {
    if ($InputPath -match '^/mnt/([a-zA-Z])/(.*)$') {
        $drive = $Matches[1].ToUpperInvariant()
        $rest = $Matches[2] -replace '/', '\'
        return "${drive}:\$rest"
    }
    if ($InputPath -match '^/([a-zA-Z])/(.*)$') {
        $drive = $Matches[1].ToUpperInvariant()
        $rest = $Matches[2] -replace '/', '\'
        return "${drive}:\$rest"
    }
    return $InputPath
}

function Convert-ToWslPath([string]$InputPath) {
    if ($InputPath -match '^([a-zA-Z]):[\\/](.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive/$rest"
    }
    return $InputPath
}

function Convert-ToMsysPath([string]$InputPath) {
    if ($InputPath -match '^([a-zA-Z]):[\\/](.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $rest = $Matches[2] -replace '\\', '/'
        return "/$drive/$rest"
    }
    if ($InputPath -match '^/mnt/([a-zA-Z])/(.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        return "/$drive/$($Matches[2])"
    }
    return $InputPath
}

$converted = switch ($Target) {
    "windows" { Convert-ToWindowsPath $Path }
    "wsl" { Convert-ToWslPath $Path }
    "msys" { Convert-ToMsysPath $Path }
}

[pscustomobject]@{
    Input = $Path
    Target = $Target
    Output = $converted
    QuoteForPowerShell = "'$($converted -replace "'", "''")'"
}
