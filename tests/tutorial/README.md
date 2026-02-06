# Tutorial Tests

This directory contains automated tests for the Kafka operator tutorial using [Spread](https://github.com/canonical/spread).

## ✅ Implementation Complete

The test framework has been successfully implemented with:
- ✅ Markdown command extraction (skips output examples)
- ✅ Sequential execution matching tutorial order
- ✅ Juju status waiting for deployments
- ✅ Comprehensive assertions for each step
- ✅ Automatic cleanup after tests

## Overview

These tests automatically extract and execute shell commands from the tutorial markdown files, ensuring the tutorial stays up-to-date and functional. **The markdown files are the single source of truth** - when you update the tutorial, the tests automatically use the new commands.

## Quick Start

**⚡ Recommended for local testing (faster):**
```bash
cd tests/tutorial

# Run tests directly on your host machine (10-15 minutes total)
./run_direct.sh
```

**🔒 For full isolation (slower but more reproducible):**
```bash
cd tests/tutorial

# Run in isolated LXD containers (40-50 minutes due to nested LXD)
./run_tests.sh

# Or run individual steps
~/go/bin/spread lxd:ubuntu-24.04:tutorial/01-environment
~/go/bin/spread -reuse lxd:ubuntu-24.04:tutorial/02-deploy

# Clean up when done
~/go/bin/spread -discard
```

### Which approach to use?

| Approach | Speed | Isolation | Use When |
|----------|-------|-----------|----------|
| **Direct** (`run_direct.sh`) | ⚡ Fast (10-15min) | 🟡 Runs on host | Local development, quick validation |
| **Spread** (`run_tests.sh`) | 🐌 Slow (40-50min) | 🟢 Full isolation | CI/CD, reproducibility testing |

**Note:** Nested LXD (Spread tests running in LXD containers) is significantly slower due to virtualization overhead. The direct approach runs commands on your host machine, which is much faster for local testing.

## Structure

```
tests/tutorial/
├── spread.yaml              # Spread configuration
├── docs/tutorial/          # Copy of tutorial markdown files
├── helpers/
│   ├── extract_commands.py  # Extracts shell/bash blocks from markdown
│   └── juju_wait.sh        # Waits for Juju to reach stable state
└── tutorial/
    ├── 01-environment/     # Tutorial step 1 (priority: 100)
    │   └── task.yaml
    └── 02-deploy/          # Tutorial step 2 (priority: 90)
        └── task.yaml
```

## Prerequisites

1. **LXD** - Container runtime (comes with Ubuntu 24.04)
   ```bash
   sudo snap install lxd
   sudo lxd init --auto
   ```

2. **Spread** - Test runner
   ```bash
   go install github.com/snapcore/spread/cmd/spread@latest
   ```

3. **Python 3** - For markdown parsing (already on Ubuntu)

## How It Works

### 1. Markdown Parsing
The `extract_commands.py` helper:
- Extracts all ` ```shell` and ` ```bash` code blocks
- Skips output examples (lines starting with `/`, `|`, `Model`, `App`, etc.)
- Preserves command order exactly as in the markdown

### 2. Test Execution
Each test task:
1. Loads the corresponding markdown file from `docs/tutorial/`
2. Extracts commands using the parser
3. Executes commands sequentially
4. Waits for Juju to stabilize (if deployment commands detected)
5. Runs assertions to verify success

### 3. Task Priority (ensures correct order)
- Step 1 (environment): Priority 100 (runs first)
- Step 2 (deploy): Priority 90 (runs second)
- Lower priority numbers run later

### 4. Assertions
Each task includes comprehensive checks:

**Step 1 - Environment:**
- ✓ LXD installed and initialized
- ✓ IPv6 disabled on lxdbr0
- ✓ Juju installed
- ✓ Controller 'overlord' exists
- ✓ Model 'tutorial' created
- ✓ Juju controller container running

**Step 2 - Deploy:**
- ✓ Kafka application deployed
- ✓ KRaft controller deployed
- ✓ 3 Kafka units running
- ✓ 3 KRaft units running
- ✓ All units active/idle
- ✓ Integration exists
- ✓ Cluster secret created
- ✓ Ports opened correctly

### 5. Cleanup
The suite automatically cleans up resources:
- Destroys Juju model and controller
- Removes LXD containers
- Runs after each test suite

## Running Tests

### Run all tutorial tests:
```bash
cd tests/tutorial
~/go/bin/spread
```

### Run specific steps:
```bash
~/go/bin/spread lxd:ubuntu-24.04:tutorial/01-environment
~/go/bin/spread lxd:ubuntu-24.04:tutorial/02-deploy
```

### Debug mode (interactive shell on failure):
```bash
~/go/bin/spread -debug lxd:ubuntu-24.04:tutorial/02-deploy
```

### Reuse containers (faster iterations):
```bash
~/go/bin/spread -reuse lxd:ubuntu-24.04:tutorial/01-environment
~/go/bin/spread -reuse lxd:ubuntu-24.04:tutorial/02-deploy
~/go/bin/spread -discard  # Clean up when done
```

### View test list without running:
```bash
~/go/bin/spread -list
```

## Updating Tutorial Markdown Files

When you update the tutorial documentation:

1. Edit the markdown file in `docs/tutorial/`
2. Copy it to the test directory:
   ```bash
   cp docs/tutorial/environment.md tests/tutorial/docs/tutorial/
   ```
3. Run the tests to verify:
   ```bash
   ~/go/bin/spread lxd:ubuntu-24.04:tutorial/01-environment
   ```

**That's it!** No need to update test code - the commands are extracted automatically.

## Adding New Tutorial Steps

To add tests for additional tutorial steps (e.g., Step 3, 4, etc.):

1. Copy the tutorial markdown:
   ```bash
   cp ../../docs/tutorial/step-name.md docs/tutorial/
   ```

2. Create task directory:
   ```bash
   mkdir tutorial/03-step-name
   ```

3. Create `tutorial/03-step-name/task.yaml`:
   ```yaml
   summary: Tutorial Step 3 - <Title>
   priority: 80  # Lower than previous steps
   
   execute: |
       set -e
       echo "=== Running Tutorial Step 3: <Title> ==="
       
       TUTORIAL_FILE="$TUTORIAL_DOCS/step-name.md"
       python3 $HELPERS/extract_commands.py "$TUTORIAL_FILE" > /tmp/commands.sh
       bash /tmp/commands.sh
       
       # Wait for Juju if needed
       if grep -q "juju deploy\|juju integrate" /tmp/commands.sh; then
           $HELPERS/juju_wait.sh 900
       fi
       
       # === ASSERTIONS ===
       echo "=== Running assertions ==="
       
       # Add your assertions here
       echo "✓ Checking something..."
       # juju status ... || exit 1
       
       echo "=== ✓ All assertions passed ==="
   ```

4. Test it:
   ```bash
   ~/go/bin/spread lxd:ubuntu-24.04:tutorial/03-step-name
   ```

## Resource Requirements

- **Disk**: ~10-20GB for LXD images and containers
- **RAM**: 4-8GB (for Juju controller + Kafka cluster)
- **Time**: 
  - Step 1 (environment): ~5-10 minutes
  - Step 2 (deploy): ~10-15 minutes
  - Full suite: ~15-25 minutes

## Troubleshooting

### LXD permission denied
```bash
sudo usermod -aG lxd $USER
newgrp lxd
```

### Spread not found
```bash
go install github.com/snapcore/spread/cmd/spread@latest
# Add ~/go/bin to PATH
export PATH=$PATH:~/go/bin
```

### Juju timeout
Increase timeout in task.yaml or juju_wait.sh:
```bash
$HELPERS/juju_wait.sh 1800  # 30 minutes
```

### Manual cleanup
```bash
# Destroy Juju resources
juju destroy-model tutorial --destroy-storage --force -y
juju destroy-controller overlord --destroy-storage --force -y

# Remove LXD containers
lxc list | grep juju- | awk '{print $2}' | xargs -I {} lxc delete {} --force

# Remove spread containers
lxc list | grep spread- | awk '{print $2}' | xargs -I {} lxc delete {} --force
```

### View test execution logs
```bash
~/go/bin/spread -v  # Verbose output
~/go/bin/spread -vv  # Very verbose (shows all command output)
```

## CI/CD Integration

To integrate with GitHub Actions or similar:

```yaml
- name: Install Spread
  run: go install github.com/snapcore/spread/cmd/spread@latest

- name: Setup LXD
  run: |
    sudo snap install lxd
    sudo lxd init --auto
    sudo usermod -aG lxd $USER

- name: Run Tutorial Tests
  run: |
    cd tests/tutorial
    ~/go/bin/spread lxd:ubuntu-24.04
```

## Files Maintained

✅ **Auto-updated (no manual changes needed):**
- Tutorial markdown files (source of truth)

📝 **Manual maintenance:**
- `task.yaml` files (add assertions as tutorial evolves)
- `helpers/extract_commands.py` (improve parsing logic if needed)
- `helpers/juju_wait.sh` (adjust timeouts if needed)

---

**Questions? Issues?**
- Check logs with `-v` or `-vv` flags
- Use `-debug` to interactively debug failures
- See [Spread documentation](https://github.com/canonical/spread)

