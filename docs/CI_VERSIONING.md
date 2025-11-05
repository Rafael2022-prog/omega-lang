# OMEGA CI Versioning and Artifact Naming

This document describes how the CI pipeline computes a dynamic version string and applies it consistently to artifact names. The goal is traceability across runs and environments, with zero duplication of logic in YAML.

## Overview
- Base version is read from the repository `VERSION` file. If empty or missing, the fallback base is `1.2.1`.
- CI metadata is appended to the base version to produce a unique version per run:
  - In GitHub Actions: `ci.<GITHUB_RUN_NUMBER>.<SHA7>`
  - In local/non-CI runs: `local.<YYYYMMDD>.<HHMM>`
- The final version string is exported to:
  - `GITHUB_OUTPUT`: key `version` (for step outputs)
  - `GITHUB_ENV`: variable `OMEGA_VERSION_NAME` (for subsequent steps)

## Helper Script: scripts/compute_ci_version.ps1
Responsibilities:
- Read the first non-empty line from `VERSION` (fallback: `1.2.1`).
- Compose metadata from CI environment (`GITHUB_RUN_NUMBER` and `GITHUB_SHA`) or local timestamp when running outside CI.
- Emit outputs:
  - Step output: `version=<BASE>-<META>` via `GITHUB_OUTPUT`
  - Environment variable: `OMEGA_VERSION_NAME=<BASE>-<META>` via `GITHUB_ENV`
- Print `OMEGA CI Version: <BASE>-<META>` to the step log for debugging.

Example (simplified):
```powershell
# scripts/compute_ci_version.ps1
$base = (Get-Content -TotalCount 1 -Path 'VERSION').Trim()
if (-not $base) { $base = '1.2.1' }
$sha7 = $env:GITHUB_SHA ? $env:GITHUB_SHA.Substring(0,7) : ''
$meta = if ($env:GITHUB_RUN_NUMBER -and $sha7) { "ci.$($env:GITHUB_RUN_NUMBER).$sha7" } else { "local.$(Get-Date -Format 'yyyyMMdd.HHmm')" }
$full = "$base-$meta"
"version=$full" | Out-File -Append -FilePath $env:GITHUB_OUTPUT -Encoding utf8
"OMEGA_VERSION_NAME=$full" | Out-File -Append -FilePath $env:GITHUB_ENV -Encoding utf8
Write-Host "OMEGA CI Version: $full"
```

## Usage in CI (GitHub Actions)
For non-Windows runners (Ubuntu/macOS), ensure PowerShell is installed before invoking the script.

Linux/macOS setup (Ubuntu example):
```yaml
- name: 🔧 Setup PowerShell
  run: |
    sudo apt-get update
    sudo apt-get install -y wget apt-transport-https software-properties-common
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update
    sudo apt-get install -y powershell

- name: 🔎 Compute version for artifact naming
  shell: pwsh
  run: |
    ./scripts/compute_ci_version.ps1
```

Windows runner:
```yaml
- name: 🔎 Compute version for artifact naming
  shell: pwsh
  run: |
    ./scripts/compute_ci_version.ps1
```

Consume the version:
- Via environment: `${{ env.OMEGA_VERSION_NAME }}`
- Via step output: `${{ steps.<id>.outputs.version }}` (when the step has `id: <id>`)

## Artifact Naming Patterns
The CI pipeline uses the computed version across jobs:
- Test: `test-results-<os>-<version>`
- Lint: `lint-results-<version>`
- Security: `security-results-<version>`
- Performance: `performance-results-<version>`
- Audit Tools: `audit-results-<os>-<version>`
- Self-Hosting Validation: `self-hosting-artifacts-<version>`
- Build (VS Code): `build-artifacts-<os>-<version>`
- Compile Smoke: `compile-smoke-windows-<version>`
- HTTP /version Check: `http-version-check-<version>`
- Coverage: `coverage-<version>`

Notes:
- Prefer using `${{ env.OMEGA_VERSION_NAME }}` when multiple steps need the version.
- Use step outputs (e.g., `${{ steps.ver_build.outputs.version }}`) when you need an explicit dependency on a specific step.

## Local Runs
When running the script outside CI, it generates metadata based on local time:
- `local.<YYYYMMDD>.<HHMM>`
This ensures locally produced artifacts are uniquely identified and distinguishable from CI artifacts.

## Best Practices
- Call `scripts/compute_ci_version.ps1` once per job, before any artifact uploads.
- On non-Windows runners, install PowerShell first.
- If you need to change the version format, edit the helper script instead of duplicating logic in YAML.
- Validate the computed version in logs: look for `OMEGA CI Version: <...>`

## Troubleshooting
- Missing PowerShell on Ubuntu/macOS: ensure the setup step runs before any `shell: pwsh` steps.
- Empty `VERSION`: the script falls back to `1.2.1`.
- Step outputs not found: include an `id:` on the compute step and reference `${{ steps.<id>.outputs.version }}`.