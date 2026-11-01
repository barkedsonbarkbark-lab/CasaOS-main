# Ubuntu LTS one-line installation

After this repository is pushed to GitHub, set the `GITHUB_REPO` value in `install.sh` to the real repository URL.

Then a fresh Ubuntu LTS machine can install it with:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main/install.sh | sudo bash
```

The installer installs the required build/runtime packages, Docker, builds the Go backend, installs the configuration, creates a systemd service, and starts it.

Check it with:

```bash
sudo systemctl status casaos-zimaos
sudo journalctl -u casaos-zimaos -f
```

Remove it with:

```bash
sudo /opt/casaos-zimaos/source/uninstall.sh
```
