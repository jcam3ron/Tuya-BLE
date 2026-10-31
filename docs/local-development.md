# Local Home Assistant

This Linux development environment runs Home Assistant Core with Nix-managed
dependencies and the integration linked directly to this working tree. It keeps
configuration, accounts, device credentials, logs and the database under
`.ha-dev/`, which Git ignores.

## Start

From the repository root, with Nix flakes enabled:

```sh
nix develop path:.
ha-dev
```

Or start directly:

```sh
nix run path:.
```

The `path:.` form includes the new flake files before they are tracked by Git.
Run from the repository root, or set `HA_DEV_ROOT` to its absolute path.

Open http://127.0.0.1:8124, create a separate local account, then add
**Tuya Local BLE** in **Settings > Devices & services > Add integration**.
Supply your device credentials through the integration's configuration flow.
Stop the instance with Ctrl-C.

For foreground operation or configuration checks:

```sh
nix develop path:.
ha-dev-check
ha-dev
```

Restart Home Assistant after Python edits. The source is linked, so no copying
or HACS installation is needed. The YAML template in `dev/home-assistant.yaml`
is copied only on first startup; edit the generated configuration for subsequent
local changes. Nix supplies Python dependencies; runtime pip installs are disabled.
The development environment uses Nixpkgs' PyCryptodome version rather than the
integration manifest's pip pin.

## Bluetooth

The host must have a running BlueZ service, a powered Bluetooth adapter and
permission for your user to access BlueZ through the system D-Bus. Check with
`bluetoothctl list` and `bluetoothctl show` inside `nix develop path:.`.
On NixOS, configure `hardware.bluetooth.enable = true;` in your Nix configuration
if Bluetooth is not already enabled. The shell supplies tools, not a system daemon
or elevated privileges. Missing adapter-management capabilities can limit
automatic adapter recovery; do not run the development instance as root.

If another nearby device triggers a discovery flow with a missing Python module,
add its Home Assistant integration domain to `extraComponents` in `flake.nix`.

This instance has separate storage and a loopback-only HTTP port, but it uses
real Bluetooth hardware. Disable the device's integration on your active Home
Assistant while testing the same device here to avoid competing connections.
Device commands still operate the real timer.

## Reproducibility

The included `flake.lock` pins the Nix inputs. Use
`nix flake update --flake path:.` deliberately to update Home Assistant and its dependencies.
