# build_all.ps1
# Builds all supported target platforms

Clear-Host
Write-Host "Building all supported target platforms..."
$ErrorActionPreference = "Stop"
# Ensure zig is installed and available in PATH
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    Write-Host "Zig is not installed or not in PATH. Please install Zig and try again."
    exit 1
}

Write-Host "Building for x86_64-windows..."
zig build install -Dtarget=x86_64-windows -Doptimize=ReleaseSafe

Write-Host "Building for x86_64-linux..."
zig build install -Dtarget=x86_64-linux -Doptimize=ReleaseSafe

Write-Host "Building for x86_64-macos..."
zig build install -Dtarget=x86_64-macos -Doptimize=ReleaseSafe

Write-Host "Building for aarch64-macos..."
zig build install -Dtarget=aarch64-macos -Doptimize=ReleaseSafe

Write-Host "Done. See binaries in zig-out/<target>"
