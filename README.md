# seiscomp-gui

![CI](https://github.com/platformfuzz/seiscomp-gui/actions/workflows/ci.yml/badge.svg)
![Build and Release](https://github.com/platformfuzz/seiscomp-gui/actions/workflows/build-and-release.yml/badge.svg)

Unofficial SeisComP GUI image (XFCE + xrdp) layered on `seiscomp-base`. Not gempa-supported.

RDP as `sysop` on TCP 3389. Needs `--shm-size 2g`. Set `SYSOP_PASSWORD` at run time.

**Package:** [ghcr.io/platformfuzz/seiscomp-gui](https://github.com/platformfuzz/seiscomp-gui/pkgs/container/seiscomp-gui)

## Run

```bash
docker pull ghcr.io/platformfuzz/seiscomp-gui:latest
docker run --rm --shm-size 2g -p 3389:3389 \
  -e SYSOP_PASSWORD=changeme \
  ghcr.io/platformfuzz/seiscomp-gui:latest
```

`DB_HOST`, `SCMASTER_HOST`, and `SEEDLINK_HOST` can be overridden so desktop tools talk to the lab.

## Build

```bash
docker build -t seiscomp-gui:test .
```

The Dockerfile pins `FROM ghcr.io/platformfuzz/seiscomp-base:<x.y.z>`. A daily workflow (and Dependabot) opens a PR when GHCR publishes a newer `x.y.z` tag. Pushes to base `latest` without a new semver tag do not retag GUI. You can also run **Bump seiscomp-base** from Actions.
