{
  description = "Local Home Assistant for Tuya BLE development";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      environments = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          hass = pkgs.home-assistant.override {
            extraComponents = [
              "bluetooth" "bluetooth_adapters" "config" "frontend"
              "history" "logbook" "recorder"
              # Nearby advertisements also trigger these discovery flows.
              "ibeacon" "kegtron" "xiaomi_ble"
            ];
            extraPackages = ps: with ps; [ pycryptodome bleak-retry-connector ];
          };
          python = hass.python3Packages.python.withPackages (_: hass.propagatedBuildInputs);
          prepare = ''
            export HA_DEV_ROOT="''${HA_DEV_ROOT:-$PWD}"
            if [[ ! -f "$HA_DEV_ROOT/custom_components/tuya_local_ble/manifest.json" ]]; then
              echo "Run from the repository root or set HA_DEV_ROOT to its absolute path." >&2
              exit 1
            fi
            export HA_DEV_CONFIG="$HA_DEV_ROOT/.ha-dev"
            export PYTHONPATH="${hass.pythonPath}''${PYTHONPATH:+:$PYTHONPATH}"
            umask 077
            mkdir -p "$HA_DEV_CONFIG/custom_components"
            ln -sfn "$HA_DEV_ROOT/custom_components/tuya_local_ble" \
              "$HA_DEV_CONFIG/custom_components/tuya_local_ble"
            if [[ ! -e "$HA_DEV_CONFIG/configuration.yaml" ]]; then
              cp ${./dev/home-assistant.yaml} "$HA_DEV_CONFIG/configuration.yaml"
            fi
          '';
          start = pkgs.writeShellApplication {
            name = "ha-dev";
            runtimeInputs = [ pkgs.coreutils ];
            text = prepare + ''
              exec ${hass}/bin/hass --config "$HA_DEV_CONFIG" --skip-pip "$@"
            '';
          };
          check = pkgs.writeShellApplication {
            name = "ha-dev-check";
            runtimeInputs = [ pkgs.coreutils ];
            text = prepare + ''
              export PYTHONPATH="${hass}/${hass.python3Packages.python.sitePackages}:$PYTHONPATH"
              exec ${python}/bin/python ${./dev/check-config.py}
            '';
          };
        in {
          packages = { default = start; ha-dev = start; ha-dev-check = check; };
          shell = pkgs.mkShell {
            packages = [ start check pkgs.bluez ];
            shellHook = ''
              echo "Run ha-dev, then open http://127.0.0.1:8124"
              echo "Check config: ha-dev-check | Bluetooth adapters: bluetoothctl list"
            '';
          };
        });
    in {
      packages = forAllSystems (system: environments.${system}.packages);
      devShells = forAllSystems (system: { default = environments.${system}.shell; });
    };
}
