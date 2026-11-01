# Ubuntu/Debian installation

```bash
curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash
```

The installer creates `/etc/casaos/casaos.conf` from the repository sample before starting the service, generates the OpenAPI code locally, builds the backend, installs a systemd unit, and enables the service at boot.

Check status:

```bash
sudo systemctl status casaos --no-pager
sudo journalctl -u casaos -n 100 --no-pager
```
