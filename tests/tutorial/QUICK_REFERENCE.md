# Quick Reference - Tutorial Tests

## 🚀 Run Tests

First, navigate to the tutorial tests directory:

```bash
cd tests/tutorial
```

### ⚡ Fast Approach (Recommended for Local Testing)

Run directly on host (10-15 minutes):

```bash
./run_direct.sh
```

### 🔒 Isolated Approach (Full Spread Testing)

Run in LXD containers (40-50 minutes):

```bash
./run_tests.sh
```

Alternatively, run individual tests:

```bash
~/go/bin/spread lxd:ubuntu-24.04:tutorial/01-environment
~/go/bin/spread lxd:ubuntu-24.04:tutorial/02-deploy
```

Or run with reuse for faster results:

```bash
~/go/bin/spread -reuse lxd:ubuntu-24.04:tutorial/01-environment
~/go/bin/spread -reuse lxd:ubuntu-24.04:tutorial/02-deploy
```

## ⚖️ Which Approach?

| Approach | Time | Isolation | Best For |
|----------|------|-----------|----------|
| **Direct** | 10-15 min | Runs on host | Local development |
| **Spread** | 40-50 min | Full isolation | CI/CD, reproducibility |

## 🔍 Debug Tests

```bash
# Interactive debugging (shell on failure)
~/go/bin/spread -debug lxd:ubuntu-24.04:tutorial/01-environment

# Verbose output
~/go/bin/spread -v lxd:ubuntu-24.04:tutorial/02-deploy

# Very verbose (show all command output)
~/go/bin/spread -vv lxd:ubuntu-24.04:tutorial/02-deploy

# List tests without running
~/go/bin/spread -list
```

## 🧹 Cleanup

```bash
# Clean up test resources
./cleanup.sh

# Or manually
~/go/bin/spread -discard
```

## 📝 Update Tests After Markdown Changes

```bash
# 1. Update the markdown file
vim docs/tutorial/environment.md

# 2. Copy to test directory
cp docs/tutorial/environment.md tests/tutorial/docs/tutorial/

# 3. Run test
~/go/bin/spread lxd:ubuntu-24.04:tutorial/01-environment
```

## ➕ Add New Tutorial Step

```bash
# 1. Copy markdown
cp docs/tutorial/new-step.md tests/tutorial/docs/tutorial/

# 2. Create task directory
mkdir tutorial/03-new-step

# 3. Create task.yaml (see README.md for template)
# 4. Set priority < 90 (e.g., 80)
# 5. Test it
~/go/bin/spread lxd:ubuntu-24.04:tutorial/03-new-step
```

## 📊 Current Test Coverage

- ✅ Step 1: Set up the environment (priority 100)
- ✅ Step 2: Deploy Apache Kafka (priority 90)
- ⏳ Step 3-8: Not yet implemented (templates available)

## 🛠 Helper Scripts

- `helpers/extract_commands.py` - Extract shell commands from markdown
- `helpers/juju_wait.sh` - Wait for Juju to stabilize
- `cleanup.sh` - Clean up all test resources
- `run_tests.sh` - Run all tests in order

## ⚙️ Configuration

- `spread.yaml` - Main configuration
- `tutorial/*/task.yaml` - Individual test tasks

## 📖 Documentation

- `README.md` - Full documentation
- `IMPLEMENTATION.md` - Implementation details
- `QUICK_REFERENCE.md` - This file

## ⏱️ Timing

- Step 1: ~5-10 minutes
- Step 2: ~10-15 minutes
- Total: ~15-25 minutes

## 💾 Resources

- RAM: 4-8GB recommended (you have 9GB free ✓)
- Disk: ~10-20GB
- Network: LXD image download on first run

## 🔧 Troubleshooting

### Spread not found
```bash
go install github.com/snapcore/spread/cmd/spread@latest
export PATH=$PATH:~/go/bin
```

### LXD permission denied
```bash
sudo usermod -aG lxd $USER
newgrp lxd
```

### Tests stuck
```bash
# Check logs
~/go/bin/spread -v lxd:ubuntu-24.04:tutorial/01-environment

# Force cleanup
./cleanup.sh
```

### Out of resources
```bash
# Free up space
./cleanup.sh
lxc image list  # Remove old images if needed
```

---

**Need help?** See [README.md](README.md) for detailed documentation.
