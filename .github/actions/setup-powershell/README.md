# setup-powershell (Composite Action)

This composite action ensures PowerShell (`pwsh`) is available across all GitHub-hosted runners and sets it up for consistent cross-platform scripting.

## Why
Many OMEGA workflows use PowerShell scripts (e.g., version computation, native build/test). GitHub Windows runners include `pwsh` by default, but Linux/macOS runners may need additional setup for reliable usage in subsequent steps.

## Usage

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup PowerShell
    # You can scope it to non-Windows runners if desired
    if: runner.os != 'Windows'
    uses: ./.github/actions/setup-powershell

  - name: Verify pwsh
    run: pwsh -v
    shell: bash
```

## Tips
- Call this action before any step that uses `shell: pwsh` on Linux/macOS.
- Windows runners already have `pwsh`; the `if: runner.os != 'Windows'` guard helps skip unnecessary setup.
- Keep PowerShell scripts in `scripts/` or project root, and invoke them with `pwsh -ExecutionPolicy Bypass -File <script>.ps1` for clarity.