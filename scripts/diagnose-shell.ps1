param()

$ErrorActionPreference = "Continue"

function Show-Command($Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        [pscustomobject]@{
            Name = $Name
            Found = $true
            Source = $cmd.Source
            CommandType = $cmd.CommandType
        }
    } else {
        [pscustomobject]@{
            Name = $Name
            Found = $false
            Source = ""
            CommandType = ""
        }
    }
}

$shell = if ($PSVersionTable.PSEdition) { "PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" } else { "Windows PowerShell" }
# NOTE: not $isWindows - PowerShell 6+ declares $IsWindows as a read-only
# automatic variable, and PowerShell variable names are case-insensitive, so
# assigning to $isWindows throws "Cannot overwrite variable IsWindows".
$onWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$onWsl = $false
if ($env:WSL_DISTRO_NAME -or $env:WSL_INTEROP) { $onWsl = $true }

[pscustomobject]@{
    Shell = $shell
    OS = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    IsWindows = $onWindows
    IsWSL = $onWsl
    CurrentDirectory = (Get-Location).Path
    ExecutionPolicy = if ($onWindows) { Get-ExecutionPolicy -Scope Process } else { "n/a" }
} | Format-List

"Common command availability:"
"----------------------------"
@("pwsh", "powershell", "cmd", "bash", "sh", "git", "node", "npm", "python", "python3", "code", "where", "wsl") |
    ForEach-Object { Show-Command $_ } |
    Format-Table -AutoSize

"Translation risks:"
"------------------"
if ($PSVersionTable.PSVersion) {
    "- Active shell is PowerShell. Translate Bash syntax before running commands."
    "- Use `$env:NAME for environment variables, not `$NAME."
    "- Use `$LASTEXITCODE for native executable exit codes."
    "- Use -LiteralPath for file operations on paths with brackets, spaces, or wildcard characters."
}
if ($isWsl) {
    "- WSL markers are present. Convert Windows paths to /mnt/<drive>/... before Linux tools open files."
}
