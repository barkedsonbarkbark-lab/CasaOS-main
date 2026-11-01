# Ubuntu/Debian installation

After pushing this repository to GitHub, install with:

```bash
curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash
```

The installer clones the repository with submodules, verifies `api/casaos/openapi.yaml`, generates the missing `codegen` packages with `oapi-codegen`, builds the backend, and creates a systemd service.

Check:

```bash
sudo systemctl status casaos
sudo journalctl -u casaos -n 100 --no-pager
```

Update:

```bash
sudo /opt/casaos-main/update.sh
```

Uninstall the main service (data/config are preserved):

```bash
sudo /opt/casaos-main/uninstall.sh
```

This repository is the CasaOS main service. A complete CasaOS deployment also requires the gateway, message bus, user service, local storage, app management, and UI components.
