# zig-bill-utils

[![Built with Zig](https://img.shields.io/badge/Built%20with-Zig-ec912d?logo=zig&logoColor=white&style=flat-square)](https://ziglang.org)


> Toolkit for analyzing U.S. legislative bills. 

Tested with **H.Con.Res.14:**  _Establishing the congressional budget for the United States Government for fiscal year 2025 and setting forth the appropriate budgetary levels for fiscal years 2026 through 2034._
- 119th Congress (2025-2026)

Built with most current version of [Zig](https://ziglang.org/documentation/) - 0.15+

## CLI Tools

This project provides six CLI tools in `zig-out/bin`:

| Tool                | Description                                           |
|---------------------|-------------------------------------------------------|
| `clean-bill`        | Cleans bill text (removes line numbers, whitespace)   |
| `extract-amendments`| Extracts amendments            |
| `extract-headings`  | Extracts section headers (`TITLE`, `SEC.`)            |
| `extract-money`     | Extracts funding amounts (e.g., `$5,000,000`)         |
| `filter-keywords`   | Filters lines by keyword (listed in keywords.txt)     |
| `split-sections`    | Splits full bill into files by section                |

## Features

- **Fast & lightweight**: Built with Zig for speed and clarity
- **No runtime dependencies**: Fully static executables
- **Self-documenting**: Every tool has `--help`

## Quick Start

Run pipeline on each `data/billname` folder:

```pwsh
./run-all-bills.ps1
```

## Development

Build all tools (Zig 0.15+ required):

```pwsh
zig build -Doptimize=ReleaseSafe
```

Binaries are written to `zig-out/bin/`.

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

## License

MIT License © 2025 Denise Case
