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

# Detect platform
$osDir = Get-OSFolder
$exeExt = if ($osDir -like "*windows") { ".exe" } else { "" }
Write-Host "Operating System Folder: $osDir"

# Confirm Zig is available
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    Write-Host "Zig is not installed or not in PATH. Please install Zig and try again."
    exit 1
}

# Base folders
#$cwd = (Get-Location).Path
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

    $tools = @(
        "clean_bill",
        "extract_headings",
        "extract_amendments",
        "extract_money",
        "filter_keywords",
        "split_sections"
    )

    $variants = @("file", "stream")

   foreach ($tool in $tools) {
        foreach ($variant in $variants) {
            $exeName = "${tool}_${variant}${exeExt}"
            $exePath = Join-Path $exeDir $exeName

            if (-not (Test-Path $exePath)) {
                Write-Warning "Skipping missing tool: $exePath"
                continue
            }

            Write-Host "→ Running: $exeName"

            $cleanPath = Join-Path $outputDir "clean.txt"

            $arguments = switch ($tool) {
                "clean_bill"         { @("--path", (Join-Path $dataDir "bill.txt"), "--outdir", $outputDir) }
                "extract_headings"   { @("--path", $cleanPath, "--outdir", $outputDir) }
                "extract_amendments" { @("--path", $dataDir, "--outdir", $outputDir) }
                "extract_money"      { @("--path", $cleanPath, "--outdir", $outputDir) }
                "filter_keywords"    { @("--path", $cleanPath, "--outdir", $outputDir) }
                "split_sections"     { @("--path", $cleanPath, "--outdir", $outputDir) }
            }

            if ($variant -eq "file") {
                & $exePath @arguments
            } else {
                # Handle stdin for stream tools
                $inputPath = if ($tool -eq "clean_bill") {
                    Join-Path $dataDir "bill.txt"
                } else {
                    $cleanPath
                }

                if (-not (Test-Path $inputPath)) {
                    Write-Warning "Missing input for stream: $inputPath"
                    continue
                }

                Get-Content $inputPath | & $exePath @("--outdir", $outputDir)
            }
        }
    }

    Write-Host "Done processing: $billName"
}

Write-Host "All bills processed successfully."