# Ubuntu one-line installer

After this repository is pushed to GitHub, install with:

```bash
curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash
```

This installs the repository's **CasaOS main backend** and its build/runtime dependencies. It does not claim to install ZimaOS itself or provide complete ZimaOS 1.8 feature parity.

Check:

```bash
systemctl status casaos-main
journalctl -u casaos-main -n 100 --no-pager
```
