# zig-bill-utils-run.ps1
$ErrorActionPreference = "Stop"
Clear-Host

function Get-OSFolder {
    $arch = $env:PROCESSOR_ARCHITECTURE
    $os = $env:OS

    if ($arch -eq "AMD64") {
        $arch = "x86_64"
    } elseif ($arch -eq "ARM64") {
        $arch = "aarch64"
    } else {
        throw "Unsupported architecture: $arch"
    }

    if ($os -like "*Windows*") {
        $os = "windows"
    } elseif ($IsLinux) {
        $os = "linux"
    } elseif ($IsMacOS) {
        $os = "macos"
    } else {
        throw "Unsupported operating system: $os"
    }

    return "$arch-$os"
}

# Resolve platform
$osDir = Get-OSFolder
$exeExt = if ($osDir -like "*windows") { ".exe" } else { "" }
Write-Host "Operating System Folder: $osDir"

# Confirm zig is available
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    Write-Host "Zig is not installed or not in PATH. Please install Zig and try again."
    exit 1
}

# Base folders
$cwd = (Get-Location).Path
$exeDir = Join-Path "zig-out" $osDir
$dataRoot = "data"
$outputRoot = "output"

Write-Host "Executable Directory: $exeDir"
Write-Host "Data Directory: $dataRoot"
Write-Host "Output Directory: $outputRoot"

# Get bills
$billFolders = Get-ChildItem -Path $dataRoot -Directory

foreach ($bill in $billFolders) {
    $billName = $bill.Name
    $dataDir = Join-Path $dataRoot $billName
    $outputDir = Join-Path $outputRoot $billName

    Write-Host "`n========================================"
    Write-Host "  Processing bill: $billName"
    Write-Host "========================================"

    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

    $toolNames = @(
        "clean_bill",
        "extract_headings",
        "extract_amendments",
        "extract_money",
        "filter_keywords",
        "split_sections"
    )

    $argsMap = @{
        "clean_bill"         = @("--path", (Join-Path $dataDir "bill.txt"), "--outdir", $outputDir)
        "extract_headings"   = @("--path", (Join-Path $outputDir "clean.txt"), "--outdir", $outputDir)
        "extract_amendments" = @("--path", $dataDir, "--outdir", $outputDir)
        "extract_money"      = @("--path", (Join-Path $outputDir "clean.txt"), "--outdir", $outputDir)
        "filter_keywords"    = @("--path", (Join-Path $outputDir "clean.txt"), "--outdir", $outputDir)
        "split_sections"     = @("--path", (Join-Path $outputDir "clean.txt"), "--outdir", $outputDir)
    }

    $step = 1
    foreach ($toolName in $toolNames) {
        $exeFile  = Join-Path $exeDir ($toolName + $exeExt)
        $toolPath = Join-Path $cwd $exeFile

        if (-not (Test-Path $toolPath)) {
            Write-Warning "❌ Skipping missing tool: $toolPath"
            continue
        }

        Write-Host "→ Running: $toolPath"
        & $toolPath @($argsMap[$toolName])
    }
    Write-Host "`n Done processing: $billName"
}
Write-Host "`nAll bills processed successfully."
