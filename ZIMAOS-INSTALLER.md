# CasaOS installer

This repository's `install.sh` is based directly on the supplied official CasaOS Installer v0.4.16.

It installs the complete CasaOS component stack rather than attempting to build only the `CasaOS` main service. This is important because CasaOS requires Gateway, MessageBus, UserService, LocalStorage, AppManagement, rclone, the main service, UI, and AppStore to be installed and started in order.

The installer defines the service order as:

1. casaos-gateway.service
2. casaos-message-bus.service
3. casaos-user-service.service
4. casaos-local-storage.service
5. casaos-app-management.service
6. rclone.service
7. casaos.service

The supplied installer also checks all of those services before reporting success.

## One-command install

```bash
curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash
```

## Important

This installer is the complete CasaOS installer supplied for this project. It does **not** claim to be a complete ZimaOS 1.8 feature implementation. ZimaOS-style features should be added on top of a working CasaOS stack rather than replacing the multi-service stack with only the main CasaOS binary.
