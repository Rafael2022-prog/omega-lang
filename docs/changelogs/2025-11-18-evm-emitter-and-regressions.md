Title: EVM Emitter: Automatic pure/view, deeper tuple regressions, ABI parity
Date: 2025-11-18

Summary of changes:
- Implemented automatic visibility/mutability inference (public + pure/view) in EVM emitter:
  - File: build/omega_production_wrapper.cpp
  - Logic: track state variable names; scan function bodies for state reads/writes and environment access; annotate headers accordingly.
  - Heuristics:
    * Writes (assignment, compound ops, emit) -> no pure/view
    * Reads or env usage (msg/tx/block/address/this/gasleft) -> view
    * Otherwise -> pure
- Enhanced return/param handling remains: memory insertion for dynamic types and tuple flattening for nested returns.

Regression tests added (Hardhat):
- Contracts:
  - build/hardhat_evm/contracts/TupleDeeperNestedExample.sol
  - build/hardhat_evm/contracts/NamedOutputsExample.sol
- Tests:
  - build/hardhat_evm/test/TupleDeeperNestedExample.js
  - build/hardhat_evm/test/NamedOutputsExample.js
- Results: 10 passing; ABI outputs validated and behaviors confirmed.

Cross-toolchain validation:
- Added solc-js parity check script: build/hardhat_evm/scripts/abi_compare.js
- npm script: npm run abi:compare
- Confirms ABI from solc-js matches Hardhat artifacts for multiple contracts.

Known limitations & follow-ups:
- Foundry setup in WSL pending (no distro detected; bash missing). Recommend installing a WSL distro (Ubuntu) and rerunning setup.
- omega-production.exe rebuild currently blocked by PowerShell script parsing errors; alternative build path or environment tweaks required to produce a new binary.