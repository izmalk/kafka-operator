# Nested Snap Support Configuration

## Problem
When running Juju in nested LXD containers (Spread test → LXD container → Juju creates another container), the inner Juju container cannot access snapd to install `juju-db`:

```
error: cannot communicate with server: Post "http://localhost/v2/snaps/juju-db": 
dial unix /run/snapd.socket: connect: connection refused
```

## Solution Applied

### 1. LXD Profile Configuration (spread.yaml)
Configured the LXD backend with settings to support nested containers and snaps:

```yaml
backends:
  lxd:
    lxd-config: |
      # Enable nested containers and snap support
      lxc profile set default security.nesting=true
      lxc profile set default security.privileged=true
```

### 2. Suite Preparation (spread.yaml)
Added LXD profile configuration in the prepare hook:

```bash
# Configure LXD profile for nested snap support
lxc profile set default security.nesting true
lxc profile set default security.privileged true

# Enable snap support in nested containers
lxc profile device add default kmsg unix-char source=/dev/kmsg path=/dev/kmsg || true
```

### 3. Task-Level Snapd Verification (task.yaml)
Ensure snapd is running before executing tutorial commands:

```bash
# Ensure snapd is running and accessible
systemctl start snapd.socket || true
systemctl start snapd.service || true
sleep 5

# Verify snapd socket is accessible
if [ ! -S /run/snapd.socket ]; then
    echo "WARNING: snapd socket not available, attempting to fix..."
    systemctl restart snapd.socket snapd.service
    sleep 10
fi
```

## What These Settings Do

### security.nesting=true
- Allows the container to create nested containers (required for Juju's LXD provider)
- Enables LXD inside LXD functionality

### security.privileged=true
- Grants additional capabilities to the container
- Required for snap operations in nested environments
- **Security Note**: Only use in isolated test environments, not production

### kmsg device
- Provides kernel message access to nested containers
- Helps with snap initialization in nested environments

### Snapd Socket Check
- Verifies `/run/snapd.socket` is accessible before proceeding
- Attempts to restart snapd services if socket is missing
- Prevents the "connection refused" error

## Performance Note

⚠️ **These settings fix the snap accessibility issue but don't solve the performance problem** with nested LXD. Tests will still be slow (30-45+ minutes) due to nested virtualization overhead.

For faster local testing, use:
```bash
cd tests/tutorial
./run_direct.sh
```

## When to Use This Configuration

- **CI/CD pipelines** where isolation is critical
- **Automated testing** in cloud environments (non-nested)
- **Integration tests** that need complete environment isolation

## When to Use Direct Testing Instead

- **Local development** - much faster (10-15 min vs 40-50 min)
- **Debugging** - easier to inspect and troubleshoot
- **Rapid iteration** - no container overhead

## Testing the Fix

Run the test with:
```bash
cd tests/tutorial
./run_tests.sh
```

Or directly with Spread:
```bash
~/go/bin/spread lxd:ubuntu-24.04:tutorial/01-environment
```

If it still fails with snapd connection errors, check:
1. Host LXD version supports nested containers
2. Security profiles are applied correctly: `lxc profile show default`
3. Snapd is running in test container: `lxc exec <container> -- systemctl status snapd`
