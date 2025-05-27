# zig-bill-utils

[![Built with Zig](https://img.shields.io/badge/Built%20with-Zig-ec912d?logo=zig&logoColor=white&style=flat-square)](https://ziglang.org)


> Toolkit for analyzing U.S. legislative bills. 

Tested with **H.Con.Res.14:**  _Establishing the congressional budget for the United States Government for fiscal year 2025 and setting forth the appropriate budgetary levels for fiscal years 2026 through 2034._
- 119th Congress (2025-2026)

Built a recent version of [Zig](https://ziglang.org/documentation/)
 - [zig-version.txt](zig-version.txt)

## CLI Tools

This project provides six CLI tools in `zig-out` os-specific folders:

| Tool                | Description                                           |
|---------------------|-------------------------------------------------------|
| `clean_bill`        | Cleans bill text (removes line numbers, whitespace)   |
| `extract_amendments`| Extracts amendments            |
| `extract_headings`  | Extracts section headers (`TITLE`, `SEC.`)            |
| `extract_money`     | Extracts funding amounts (e.g., `$5,000,000`)         |
| `filter_keywords`   | Filters lines by keyword (listed in keywords.txt)     |
| `split_sections`    | Splits full bill into files by section                |

## Features

- **Fast & lightweight**: Built with Zig for speed and clarity
- **No runtime dependencies**: Fully static executables
- **Self-documenting**: Every tool has `--help`

## Quick Start

Run pipeline on each `data/billname` folder:

```pwsh
./zig-bill-utils-run.ps1
```

## Development

Choose commands to build for each target as needed (Zig 0.15+ required) or run them all with PowerShell Core.

```pwsh
zig build install -Dtarget=aarch64-macos -Doptimize=ReleaseSafe
zig build install -Dtarget=x86_64-linux -Doptimize=ReleaseSafe
zig build install -Dtarget=x86_64-macos -Doptimize=ReleaseSafe
zig build install -Dtarget=x86_64-windows -Doptimize=ReleaseSafe 


./build_all.ps1
```

Binaries are written to `zig-out/` in operating-system specific folders.

## Project Organization

- `data/billname/` 
  - bill.txt
  - amendments.csv
  - keywords.txt
- `src/` — Zig files for the CLI tools and shared utils and logger
- `output/billname/`
  - amendments/
  - sections/
  - clean.txt
  - headings.txt
  - keyword_hits_amendments.txt
  - keyword_hits.txt
  - money_lines.csv 

## Reference

- [Congress.gov](https://www.congress.gov/)
  - [2025-hconres0014](https://www.congress.gov/bill/119th-congress/house-concurrent-resolution/14)
- [Zig](https://ziglang.org/)
  - [Language Reference](https://ziglang.org/documentation/master/)
  - [Standard Library](https://ziglang.org/documentation/master/std/)
  - [Build System](https://ziglang.org/learn/build-system/)

## License

MIT License © 2025 Denise Case
