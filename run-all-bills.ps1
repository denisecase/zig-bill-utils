# run-all-bills.ps1

$ErrorActionPreference = "Stop"

# Base folders from root
$exeDir = "zig-out/bin"
$dataRoot = "data"
$outputRoot = "output"

# Find all bill folders inside data/
$billFolders = Get-ChildItem -Path $dataRoot -Directory

foreach ($bill in $billFolders) {
    $billName = $bill.Name
    $dataDir = Join-Path $dataRoot $billName
    $outputDir = Join-Path $outputRoot $billName

    Write-Host "`n========================================"
    Write-Host "  Processing bill: $billName"
    Write-Host "========================================"

    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

    # Step 1: Clean bill text
    Write-Host "`n[1/6] Creating clean.txt using clean_bill..."
    & "$exeDir\clean_bill.exe" --path "$dataDir\bill.txt" --outdir "$outputDir"
    Write-Host " clean.txt created in output folder."

    # Step 2: Extract section headings
    Write-Host "`n[2/6] Extracting headings using extract_headings..."
    & "$exeDir\extract_headings.exe" --path "$outputDir\clean.txt" --outdir "$outputDir"
    Write-Host " headings.txt created in output folder."

    # Step 3: Extract amendments
    Write-Host "`n[3/6] Extracting amendments using extract_amendments..."
    & "$exeDir\extract_amendments.exe" --path "$dataDir" --outdir "$outputDir"
    Write-Host " amendment .txt files created in output folder."

    # Step 4: Extract monetary references
    Write-Host "`n[4/6] Extracting money lines using extract_money..."
    & "$exeDir\extract_money.exe" --path "$outputDir\clean.txt" --outdir "$outputDir"
    Write-Host " money_lines.txt created in output folder."

    # Step 5: Filter lines by keywords
    Write-Host "`n[5/6] Filtering by keywords using filter_keywords..."
    & "$exeDir\filter_keywords.exe" --path "$outputDir\clean.txt" --outdir "$outputDir"
    Write-Host " keyword_hits.txt created in output folder."

    # Step 6: Split by sections
    Write-Host "`n[6/6] Splitting sections using split_sections..."
    & "$exeDir\split_sections.exe" --path "$outputDir\clean.txt" --outdir "$outputDir"
    Write-Host " section .txt files created in output folder."

    Write-Host "`n Completed processing for: $billName"
}

Write-Host "`n All bills processed successfully."
