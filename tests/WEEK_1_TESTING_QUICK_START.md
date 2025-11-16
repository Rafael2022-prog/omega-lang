# Week 1 Testing Guide - Quick Start

**Phase**: Week 1 - Functionality Testing  
**Duration**: 4 days (Day 1-4)  
**Location**: tests/sample/  
**Report Template**: tests/WEEK_1_TESTING_REPORT.md  

---

## QUICK START - RUN THESE COMMANDS

### Day 1-2: Build Command Testing

```bash
# Navigate to project
cd r:\OMEGA

# Test 1: Basic build
omega build

# Test 2: Debug mode
omega build --debug

# Test 3: Release mode
omega build --release

# Test 4: Verbose output
omega build --verbose

# Test 5: Clean build
omega build --clean --release

# Test 6: Missing TOML (run from different directory)
cd tests\sample\src
omega build

# Test 7: Verify output directories
dir target\native\
dir target\evm\
dir target\solana\
```

### Day 2-3: Test Framework Testing

```bash
# Navigate to tests/sample
cd r:\OMEGA\tests\sample

# Test 1: Run all tests
omega test

# Test 2: Assertions verification (included in above)
# Check for output showing test results

# Test 3: Verbose output
omega test --verbose

# Test 4: Coverage reporting
omega test --coverage

# Test 5: Filter by math
omega test --filter=math

# Test 6: Multiple filters
omega test --filter=math --filter=edge

# Test 7: No matches
omega test --filter=nonexistent
```

### Day 3-4: Deploy Command Testing

```bash
# Setup: Get a testnet wallet first
# Create: tests/sample/contracts/sample.abi (or use example)

# Test 1: List available networks
omega deploy --list-networks

# Test 2: Dry run to Goerli (replace YOUR_KEY_FILE)
omega deploy goerli --contract=contracts/sample.abi --key=YOUR_KEY_FILE --dry-run

# Test 3: Gas estimation
omega deploy goerli --contract=contracts/sample.abi --estimate-gas

# Test 4: Check balance
omega deploy goerli --key=YOUR_KEY_FILE --check-balance

# Test 5: Invalid key (should show error)
omega deploy goerli --key=invalid.json

# Test 6: Dry run with simulated low balance
omega deploy goerli --key=YOUR_KEY_FILE --contract=large.abi --dry-run

# Test 7: Solana network test
omega deploy solana --contract=program.so --key=solana_key.json --dry-run
```

---

## HOW TO DOCUMENT RESULTS

For each test, fill in the template in WEEK_1_TESTING_REPORT.md:

```
Command: omega [command] [args]
Expected: [What should happen]
Actual: [What actually happened]
Status: [ ] PASS [ ] FAIL [ ] SKIP
Issues: [Any problems]
```

---

## SAMPLE PROJECT LOCATION

All tests use the sample project at:
```
tests/sample/
├── src/
│   ├── main.omega
│   ├── math.omega
│   └── utils.omega
├── contracts/
├── math.test.omega
├── string.test.omega
├── edge_cases.test.omega
└── omega.toml
```

This is already created and ready to test.

---

## FILE STRUCTURE CREATED

```
tests/sample/
├── src/                      (3 source files)
│   ├── main.omega           ✅ Created
│   ├── math.omega           ✅ Created
│   └── utils.omega          ✅ Created
├── contracts/               ✅ Created (empty, add files as needed)
├── omega.toml              ✅ Created
├── math.test.omega         ✅ Created (16 tests)
├── string.test.omega       ✅ Created (7 tests)
└── edge_cases.test.omega   ✅ Created (11 tests)

Total: ~34 tests ready to run
```

---

## SUCCESS CRITERIA

### Build Command
- [x] Sample project created
- [ ] omega build runs without crashing
- [ ] target/native/ created
- [ ] target/evm/ created
- [ ] target/solana/ created
- [ ] Error handling works

### Test Framework
- [x] 34 test cases created
- [ ] Tests discover all test files
- [ ] All assertions execute
- [ ] Test filtering works
- [ ] Coverage calculation works

### Deploy Command
- [ ] Network list displays
- [ ] Dry-run mode works
- [ ] Gas estimation runs
- [ ] Balance checking works
- [ ] Error handling works

---

## WHAT TO DO IF SOMETHING FAILS

1. **Command Not Found**
   - Make sure omega is in PATH
   - Or use full path: `r:\OMEGA\omega build`

2. **Syntax Errors in Tests**
   - Check: math.test.omega, string.test.omega, edge_cases.test.omega
   - They are provided pre-written, should not error

3. **Build Fails**
   - Check: tests/sample/omega.toml exists
   - Check: src/ directory has the 3 .omega files
   - Check: No syntax errors in .omega files

4. **Test Not Found**
   - Make sure you're in tests/sample/ directory
   - Make sure test files end in .test.omega
   - Make sure functions start with test_

---

## DAILY TIMELINE

### Day 1 (Morning)
- [ ] Read this guide
- [ ] Run basic build test
- [ ] Run debug build
- [ ] Run release build
- [ ] Document results

### Day 1 (Afternoon)
- [ ] Run verbose build
- [ ] Run clean build
- [ ] Test error handling (missing TOML)
- [ ] Verify output directories exist
- [ ] Document all results

### Day 2 (Morning)
- [ ] Run all tests
- [ ] Run tests with --verbose
- [ ] Run tests with --coverage
- [ ] Document results
- [ ] Note any assertion failures

### Day 2 (Afternoon)
- [ ] Test filtering: --filter=math
- [ ] Test filtering: --filter=edge
- [ ] Test no-match scenario
- [ ] Test parallel execution (if supported)
- [ ] Document results

### Day 3 (Morning)
- [ ] Setup testnet wallet
- [ ] Get testnet ETH from faucet
- [ ] Export private key to JSON
- [ ] Create sample contract file
- [ ] Document setup

### Day 3 (Afternoon)
- [ ] Test: omega deploy --list-networks
- [ ] Test: Goerli dry-run
- [ ] Test: Gas estimation
- [ ] Test: Balance checking
- [ ] Document results

### Day 4 (Morning)
- [ ] Test: Invalid key error
- [ ] Test: Insufficient balance error
- [ ] Test: Solana network
- [ ] Test: Multiple networks
- [ ] Document all results

### Day 4 (Afternoon)
- [ ] Review all test results
- [ ] Fill in WEEK_1_TESTING_REPORT.md completely
- [ ] Identify any blockers
- [ ] Prepare issue reports
- [ ] Ready for Day 5 integration testing

---

## REFERENCE

**Report Template**: `WEEK_1_TESTING_REPORT.md`  
**Full Testing Plan**: `PHASE_3_ACTION_PLAN.md`  
**Sample Project**: `tests/sample/`  
**Status Dashboard**: `STATUS_DASHBOARD_v2.0.0.md`  

---

## BEFORE YOU START

1. ✅ Sample project created (already done)
2. ✅ Test files created (already done)
3. ✅ Configuration file created (already done)
4. [ ] You ready to test? Start above!

---

**Ready?** Start with Day 1 commands above!

