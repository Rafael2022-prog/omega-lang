# OMEGA v2.0.0 Testing Quick Start Guide

**Purpose**: Get started with testing Session 3 implementation  
**Duration**: Follow Week 1 plan from PHASE_3_ACTION_PLAN.md  
**Status**: Ready to execute  

---

## ONE-MINUTE OVERVIEW

Session 3 implemented 3 new commands:
1. **`omega build`** - Compile multi-file projects to 5 targets
2. **`omega test`** - Run tests with assertions
3. **`omega deploy`** - Deploy to blockchains

All code is written, verified, and documented. Now we need to **test** it.

---

## QUICK TEST SEQUENCE

### Step 1: Verify Build Command (5 min)

```powershell
# Verify build.mega exists and has content
Get-Content src/commands/build.mega -Head 20

# Expected: Proper imports and function definitions
```

### Step 2: Verify Test Command (5 min)

```powershell
# Verify test.mega exists
Get-Content src/commands/test.mega -Head 20

# Expected: Proper imports and function definitions
```

### Step 3: Verify Deploy Command (5 min)

```powershell
# Verify deploy.mega exists
Get-Content src/commands/deploy.mega -Head 20

# Expected: Proper imports and function definitions
```

### Step 4: Verify CLI Integration (5 min)

```powershell
# Check CLI has all imports
Select-String "import" omega_cli.mega

# Expected:
# import "src/commands/build";
# import "src/commands/test";
# import "src/commands/deploy";
```

---

## TESTING CHECKLIST FOR WEEK 1

### Day 1: Build Command
- [ ] Test `omega build --debug`
- [ ] Test `omega build --release`
- [ ] Test `omega build --clean`
- [ ] Verify output directories created
- [ ] Verify error handling

### Day 2: Test Command
- [ ] Create test files in tests/
- [ ] Test `omega test --verbose`
- [ ] Test `omega test --coverage`
- [ ] Verify assertions work
- [ ] Verify test discovery

### Day 3: Deploy Command
- [ ] Verify network configuration loads
- [ ] Test `omega deploy --help`
- [ ] Create test private key
- [ ] Test deployment dry-run
- [ ] Verify error handling

### Day 4: Integration Testing
- [ ] Build → Test → Deploy workflow
- [ ] Cross-module communication
- [ ] Error propagation
- [ ] Performance baseline

---

## FILE CREATION CHECKLIST

Create these files to enable testing:

### `tests/sample/HelloWorld.omega`
```
// Simple contract for testing
function main() {
    print("Hello, OMEGA!");
}
```

### `tests/sample/omega.toml`
```toml
[project]
name = "hello-world"
version = "0.1.0"

[build]
sources = ["tests/sample"]
targets = ["evm", "native"]
```

### `tests/sample/math.test.omega`
```
import "src/std/assert";

test_addition() {
    assert_equal_int(2 + 2, 4);
}

test_subtraction() {
    assert_equal_int(5 - 3, 2);
}
```

---

## WHAT TO DOCUMENT

For each test, document:
1. **Test Name**: Descriptive title
2. **Command**: What command was run
3. **Expected**: What should happen
4. **Actual**: What actually happened
5. **Status**: ✅ PASS or ❌ FAIL
6. **Notes**: Any observations

---

## SUCCESS CRITERIA

### Build Command ✅
- [x] Syntax is correct
- [x] Imports resolve
- [x] Function signatures match
- [ ] Functionality works (TO TEST)
- [ ] Error handling triggers (TO TEST)
- [ ] Output is correct (TO TEST)

### Test Command ✅
- [x] Syntax is correct
- [x] Imports resolve
- [x] Function signatures match
- [ ] Assertions work (TO TEST)
- [ ] Coverage calculates (TO TEST)
- [ ] Filtering works (TO TEST)

### Deploy Command ✅
- [x] Syntax is correct
- [x] Imports resolve
- [x] Function signatures match
- [ ] Network config loads (TO TEST)
- [ ] Gas estimation runs (TO TEST)
- [ ] Transaction flow works (TO TEST)

---

## KNOWN ISSUES TO WATCH FOR

1. **RPC Endpoints**: Currently placeholders, will return mock data
2. **Signing**: Currently placeholder, won't actually sign
3. **Gas Estimation**: Currently placeholder, won't calculate real costs

**What to do**: Document these as expected, move forward with testing framework

---

## REFERENCES

### Main Documents
- **PHASE_3_ACTION_PLAN.md** - Detailed week-by-week plan
- **IMPLEMENTATION_VERIFICATION_REPORT.md** - Technical details
- **SESSION_3_COMPLETION_REPORT.md** - Overall status

### Code Files
- **src/commands/build.mega** - Build implementation
- **src/commands/test.mega** - Test implementation
- **src/commands/deploy.mega** - Deploy implementation
- **src/std/assert.mega** - Assertion library

---

## GETTING HELP

If you encounter issues:

1. Check **IMPLEMENTATION_VERIFICATION_REPORT.md** for known placeholders
2. Review **PHASE_3_ACTION_PLAN.md** section on expected outcomes
3. Look at function comments in the source files
4. Check **SESSION_3_COMPLETION_REPORT.md** for architecture

---

## NEXT STEPS

### After Day 1 (Build Testing)
- Document results
- Report any issues
- Proceed to Day 2 only if all tests pass

### After Day 2 (Test Testing)
- Document results
- Report any issues
- Proceed to Day 3 only if all tests pass

### After Day 3 (Deploy Testing)
- Document results
- Note placeholder functions
- Proceed to integration testing

### After Day 4 (Integration)
- Summarize all findings
- Create bug reports for issues
- Plan fixes for Week 2

---

## QUICK REFERENCE: TEST COMMANDS

```bash
# Build command
omega build --debug           # Debug mode
omega build --release         # Release mode
omega build --clean           # Clean build

# Test command
omega test                    # Run all tests
omega test --verbose          # Verbose output
omega test --coverage         # Show coverage

# Deploy command
omega deploy ethereum         # Deploy to Ethereum (dry-run)
omega deploy goerli --testnet # Deploy to testnet
omega deploy --help           # Show help
```

---

## REPORTING TEMPLATE

Use this format when reporting test results:

```
TEST: [Test Name]
Command: omega [command] [args]
Expected: [What should happen]
Actual: [What actually happened]
Status: [✅ PASS / ❌ FAIL / ⏳ BLOCKED]
Error: [Any error messages]
Notes: [Additional observations]
Duration: [How long it took]
```

---

**Start Here**: Choose Day 1, Day 2, or Day 3 from the checklist above and follow the commands.

**Good Luck!** 🚀

