# Ubuntu/Debian installation

This repository contains the CasaOS main backend plus an installer that clones the repository and its UI submodule.

## One command

```bash
curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash
```

The installer verifies `api/casaos/openapi.yaml` before generating Go code. It then generates both the CasaOS OpenAPI server code and CasaOS MessageBus client code before compiling.

## Verify

```bash
systemctl status casaos-main
journalctl -u casaos-main -n 100 --no-pager
```

## Update

```bash
sudo /opt/casaos-main/update.sh
```

## Uninstall backend

```bash
sudo /opt/casaos-main/uninstall.sh
```

Configuration and data under `/etc/casaos` and `/var/lib/casaos` are intentionally preserved by the uninstall script.
