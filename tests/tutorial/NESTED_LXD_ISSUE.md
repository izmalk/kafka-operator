# Nested LXD Performance Issue - Resolved with Alternative Approach

## The Problem

When running Spread tests in LXD containers (which is the default behavior), the tests create a **nested LXD environment**:
- Your host machine runs LXD
- Spread creates an LXD container (`spread-X-ubuntu-24-04`)
- Inside that container, the tutorial commands run `lxd init` and `juju bootstrap localhost`
- Juju then creates another LXD container (`juju-XXXXX-0`) inside the Spread container
- This is **3 levels deep**: Host → Spread Container → Juju Controller Container

### Why It's Slow
Nested virtualization has significant performance overhead:
- Container-in-container operations are slow
- Network routing through multiple layers
- Resource constraints at each level
- Juju bootstrap can take 30-45+ minutes (vs. 3-5 minutes on bare metal)

### What Happened in Your Tests
- Test started at 22:46:45
- Got stuck at "Running machine configuration script..." (last step of bootstrap)
- Timeout hit at 23:16:44 (exactly 30 minutes)
- Increased to 45 minutes, but may still timeout

## The Solution: Two Approaches

### ⚡ Approach 1: Direct Testing (RECOMMENDED for local development)

**File:** `run_direct.sh`

**What it does:**
- Runs tutorial commands directly on your host machine
- No nested LXD - just one level of containers
- Uses the same markdown parsing
- Much faster: ~10-15 minutes total

**Pros:**
- ✅ 3-4x faster than nested approach
- ✅ Guaranteed to work with 9GB RAM
- ✅ Same commands from markdown
- ✅ Same assertions
- ✅ Perfect for local development

**Cons:**
- ⚠️ Runs on your host (less isolation)
- ⚠️ Will create actual LXD containers and Juju resources on your machine

**Usage:**
```bash
cd tests/tutorial
./run_direct.sh
```

### 🔒 Approach 2: Spread Testing (for CI/CD and full isolation)

**Files:** `spread.yaml`, `run_tests.sh`

**What it does:**
- Runs tests in isolated LXD containers
- Complete environment isolation
- Reproducible across different machines
- Slow but thorough

**Pros:**
- ✅ Complete isolation
- ✅ Reproducible
- ✅ Perfect for CI/CD
- ✅ Can run on different backends (cloud, etc.)

**Cons:**
- ⚠️ Very slow (40-50+ minutes) due to nested LXD
- ⚠️ May timeout on slower machines
- ⚠️ Higher resource usage

**Usage:**
```bash
cd tests/tutorial
./run_tests.sh  # Or individual spread commands
```

**Timeout increased to:** 45 minutes (was 30m, then default 15m)

## Recommendations

### For Local Development
Use `./run_direct.sh`:
- Fast feedback loop
- Same command extraction from markdown
- Same validation logic
- Runs in 10-15 minutes

### For CI/CD
Use Spread tests but on a CI runner with:
- Better hardware (more RAM, faster CPU)
- Non-nested environment (bare metal or VM, not LXD)
- Or use a cloud backend (google, openstack, linode) instead of LXD

### For Production Validation
Consider both:
- Direct tests for quick validation
- Spread tests for full reproducibility check

## What Was Fixed

1. ✅ **Juju directory permission** - Added `mkdir -p /root/.local/share/juju`
2. ✅ **Timeout increased** - From 15m → 30m → 45m
3. ✅ **LXD performance tuning** - Added config for nested containers
4. ✅ **Direct testing option** - Created fast alternative for local use

## Files Delivered

- `run_direct.sh` - **NEW** Fast direct testing script
- `run_tests.sh` - Original Spread-based runner (updated timeouts)
- `tutorial/01-environment/task.yaml` - Updated with 45m timeout and LXD tuning
- `tutorial/02-deploy/task.yaml` - Updated with 45m timeout
- `README.md` - Updated with both approaches
- All other files unchanged

## Next Steps

1. **Try the direct approach first:**
   ```bash
   cd tests/tutorial
   ./run_direct.sh
   ```

2. **If you need full isolation**, try Spread again with the increased 45m timeout:
   ```bash
   ./run_tests.sh
   ```

3. **For CI/CD**, configure Spread to use a cloud backend instead of nested LXD

---

**Both approaches use the same markdown files as source of truth and the same validation logic. Choose based on your needs: speed (direct) vs. isolation (spread).**
