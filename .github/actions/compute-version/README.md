# compute-version (Composite Action)

This composite action centralizes OMEGA CI version computation and exposes a consistent version name for artifact naming across workflows.

What it does:
- Runs scripts/compute_ci_version.ps1 to compute a version string.
- Exports OMEGA_VERSION_NAME into the workflow environment for all subsequent steps.
- Provides a fallback version when the repository state is irregular (e.g., local dev or non-standard refs).
- Exposes an action output `version` that mirrors `OMEGA_VERSION_NAME`.

## Usage

On Linux/macOS runners, ensure PowerShell is set up first, then call the action:

```yaml
steps:
  - uses: actions/checkout@v4

  # Required on non-Windows runners
  - name: Setup PowerShell
    if: runner.os != 'Windows'
    uses: ./.github/actions/setup-powershell

  - name: Compute CI Version
    id: compute_version
    uses: ./.github/actions/compute-version

  - name: Use the computed version
    run: |
      echo "Version from env: $env:OMEGA_VERSION_NAME"
      echo "Version from output: ${{ steps.compute_version.outputs.version }}"
    shell: pwsh

  - name: Upload artifact with versioned name
    uses: actions/upload-artifact@v4
    with:
      name: omega-${{ env.OMEGA_VERSION_NAME }}
      path: ./dist/**
```

Notes:
- Prefer `env.OMEGA_VERSION_NAME` for naming artifacts; it's always available after this action.
- The output `version` is provided for convenience in expressions (`${{ steps.compute_version.outputs.version }}`), but either mechanism works.
- On Windows runners, you may omit the Setup PowerShell step since `pwsh` is already available.