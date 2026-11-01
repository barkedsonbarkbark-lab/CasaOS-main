# Ubuntu LTS installation

One-command installer:

```bash
curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash
```

Service status:

```bash
sudo systemctl status casaos-main
```

Logs:

```bash
sudo journalctl -u casaos-main -f
```

Update:

```bash
sudo /opt/casaos-main/update.sh
```

Uninstall the installed main component:

```bash
sudo /opt/casaos-main/uninstall.sh
```

> This repository is the CasaOS main component. A complete CasaOS stack normally includes companion services such as Gateway, MessageBus, UserService, LocalStorage, and the UI. Do not treat this installer as a complete replacement OS until those components are integrated and tested together.
