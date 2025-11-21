# OMEGA Project Changelog

## 2025-11-18

- Fixed recursion in the production wrapper (`build/omega_production_wrapper.cpp`):
  - The executable now delegates to the repository root PowerShell CLI (`omega.ps1` or `omega-cli.ps1`) instead of `bin/omega.ps1` to avoid calling itself.
  - Added robust path resolution using `std::filesystem` to locate backend scripts in the project root.

- Windows build environment updates:
  - Verified WinLibs (MinGW‑w64) `g++` installation and configured PATH.
  - Documented troubleshooting for LLVM/Clang header conflicts (`C_INCLUDE_PATH`, `CPLUS_INCLUDE_PATH`, `CPATH`, `INCLUDE`) in `dist/README.md`.
  - Ensured runtime DLLs (e.g., `libstdc++-6.dll`) are found by adding WinLibs `mingw64\bin` to PATH when launching the production executable.

- Backend integration:
  - Confirmed `omega.ps1` CLI compiles OMEGA sources and emits IR (`*.omegair`) and placeholder target stubs (`.sol`, `.rs`, `.go`).
  - Validated that `bin/omega-production.exe compile` now delegates correctly to `omega.ps1` without recursion.

- Quality checks:
  - Rebuilt `bin/omega-production.exe` with `g++ -std=c++17 -O2`.
  - Ran `version`, `help`, and `compile` commands to verify expected outputs and exit codes.
  - Ensured IR generation works via CLI, and target stubs exist in `build/`.

## 2025-11-19

- Native codegen integration:
  - Implemented native target emission directly in the production wrapper for EVM (`.sol`), Solana (`.rs`), and Cosmos (`.go`).
  - IR emission (`*.omegair`) remains available and is always produced alongside target outputs.
  - Removed reliance on PowerShell backend for `compile` and `build` commands.

- Standardized option parsing:
  - The wrapper now accepts `--target <evm|solana|cosmos|all>`, `-t <...>`, or `target=<...>`.
  - Supports `--output <dir>` or `output=<dir>` to control artifact destination.
  - Avoids PowerShell `--` mis-parsing issues across environments.

- End-to-end tests:
  - Added `tests/e2e/native_codegen_e2e.ps1` to validate compile/build/test flows and artifact creation per target.
  - Tests assert exit codes and presence of generated files; includes PATH setup for WinLibs runtime DLLs.

- Production build script hardening:
  - Updated `build_production_real_native.ps1` to prefer `g++` and fall back to `clang++` automatically when compilation fails.
  - Temporarily clears `CPATH` and `CPLUS_INCLUDE_PATH` during compilation to prevent libc++/libstdc++ header mixing on Windows (LLVM MinGW + WinLibs GCC coexistence).
  - Captures and prints compiler output on failure to aid troubleshooting.
  - Verified successful build of `bin/omega-production.exe` with fallback `clang++`, with `version`, `help`, and smoke `compile` commands passing.