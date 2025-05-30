# build_all.ps1
# Builds all supported target platforms

Clear-Host
Write-Host "Building all supported target platforms..." -ForegroundColor Cyan
$ErrorActionPreference = "Stop"

# Check for zig
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    Write-Host "Zig is not installed or not in PATH. Please install Zig and try again." -ForegroundColor Red
    exit 1
}

function Invoke-Build {
    param (
        [string]$Target
    )

    Write-Host "  Building for $Target..."
    zig build install "-Dtarget=${Target}" -Doptimize=ReleaseSafe

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed for $Target." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# Build for each target
Invoke-Build "x86_64-windows-gnu"
Invoke-Build "x86_64-linux-gnu"
Invoke-Build "x86_64-macos-none"
Invoke-Build "aarch64-macos-none"

Write-Host "Done. If successful, see binaries in zig-out/<target>" -ForegroundColor Green
