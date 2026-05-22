param()

function Resolve-Tool($Name) {
    $items = Get-Command $Name -All -ErrorAction SilentlyContinue
    if (-not $items) {
        return [pscustomobject]@{ Tool = $Name; Found = $false; Paths = "" }
    }
    [pscustomobject]@{
        Tool = $Name
        Found = $true
        Paths = ($items | Select-Object -ExpandProperty Source -Unique) -join "; "
    }
}

$isWsl = [bool]($env:WSL_DISTRO_NAME -or $env:WSL_INTEROP)
$cwd = (Get-Location).Path

[pscustomobject]@{
    IsWSL = $isWsl
    WslDistro = $env:WSL_DISTRO_NAME
    OS = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    CurrentDirectory = $cwd
    PathLooksWindows = ($cwd -match '^[A-Za-z]:\\')
    PathLooksWslMount = ($cwd -match '^/mnt/[a-zA-Z]/')
} | Format-List

"Tool resolution:"
"----------------"
@("node", "npm", "pnpm", "yarn", "python", "python3", "git", "code", "cmd", "powershell", "pwsh", "wsl") |
    ForEach-Object { Resolve-Tool $_ } |
    Format-Table -AutoSize

"Runtime notes:"
"--------------"
if ($isWsl) {
    "- This session has WSL markers. Use Linux paths for Linux tools."
    "- Call Windows-native tools explicitly with cmd.exe /c, powershell.exe, or full .exe paths."
} else {
    "- This session appears Windows-native PowerShell/cmd-compatible."
    "- Do not use /mnt/c paths unless a WSL process will open them."
}
