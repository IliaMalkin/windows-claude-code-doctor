param(
    [Parameter(Mandatory = $true)]
    [int]$Port
)

$connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
if (-not $connections) {
    "No TCP listener or connection found on local port $Port."
    exit 0
}

$connections |
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess,
        @{Name = "ProcessName"; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName }},
        @{Name = "Path"; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path }} |
    Format-Table -AutoSize
