# CasaOS ZimaOS-style Control Center

This source tree has been upgraded with a bundled, standalone web control center inspired by the modern UX patterns of ZimaOS 1.8.x.

## Included

- Responsive dashboard with live CPU, memory and temperature metrics
- Sidebar navigation and dark/light themes
- Spotlight-style local navigation search
- Docker container list and lifecycle controls
- Docker container logs and stats API
- Docker Compose deployment API with persistent project directories under `/DATA/Apps/<project>`
- Built-in App Store starter catalog using Docker/Compose templates
- File browser for server directories
- Create folders and upload files
- Storage/cloud mount view and cloud driver links
- Gallery view for common image/video files
- System hardware/network/logs pages
- Restart and shutdown controls
- Token storage in browser local storage

## Important architecture note

The original `CasaOS-main.zip` contains the CasaOS backend but does not contain the upstream `CasaOS-UI` git submodule. Therefore this package supplies a new self-contained UI instead of pretending the missing upstream UI is present.

Features such as RAID orchestration, hardware-specific fan curves, AI photo indexing/semantic search, map-based photo browsing, and device-specific GPIO/touchscreen controls depend on separate services or hardware integrations that are not implemented by this backend. The UI exposes the available backend capabilities without faking unsupported operations.

## Build

```bash
go build ./...
```

The web UI is embedded into the Go binary at `route/ui/index.html` and the server registers `/` with the CasaOS gateway. Docker endpoints are under `/v1/docker/*` and use the host Docker CLI.

## Security

Docker lifecycle and Compose endpoints are administrator operations. Keep the CasaOS API behind its normal authentication layer and do not expose the service directly to the public internet without authentication.
