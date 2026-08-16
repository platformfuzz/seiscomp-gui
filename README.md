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

The Dockerfile pins `FROM ghcr.io/platformfuzz/seiscomp-base:<x.y.z>`. Pushes that only update base `:latest` do not rebuild GUI.

Dependabot (weekly) can open a pin PR. For a same-day PR when GHCR gets a new `x.y.z` tag, run **Bump seiscomp-base** (daily cron, `workflow_dispatch`, or `repository_dispatch` type `seiscomp-base-released`). That job uses a GitHub App, not `GITHUB_TOKEN`: org policy does not let Actions create pull requests with the default token, and turning on “Allow GitHub Actions to create and approve pull requests” is the wrong fix (org-wide, and it can approve PRs).

### GitHub App for pin PRs

Create a **private** org App, install it only on this repo, then store Client ID + private key as below. The bump workflow no-ops until `SEISCOMP_BUMP_APP_CLIENT_ID` is set.

1. Open [platformfuzz GitHub Apps](https://github.com/organizations/platformfuzz/settings/apps) → **New GitHub App**.
2. **GitHub App name:** something unique, e.g. `platformfuzz-seiscomp-bump`.
3. **Homepage URL:** `https://github.com/platformfuzz/seiscomp-gui`
4. Leave callback / setup URL / identity checks empty. Do not request user authorization.
5. **Webhook:** uncheck **Active** (no events). If a URL is required, use `https://example.com`.
6. **Repository permissions** (nothing else):
   - **Contents:** Read and write (push the pin branch)
   - **Pull requests:** Read and write (open the PR)
   - **Metadata:** Read-only (default)
7. **Where can this GitHub App be installed?** Only on this account.
8. **Create GitHub App**. Copy **Client ID** (not the App ID). **Generate a private key** and keep the `.pem` out of git.
9. **Install App** → **Only select repositories** → `seiscomp-gui` → **Install**.
10. In this repo: **Settings → Secrets and variables → Actions**
    - Variable `SEISCOMP_BUMP_APP_CLIENT_ID` = Client ID
    - Secret `SEISCOMP_BUMP_APP_PRIVATE_KEY` = full PEM (`-----BEGIN … PRIVATE KEY-----` through the end)

Do not enable org **Allow GitHub Actions to create and approve pull requests** for this. After the variable is set, **Actions → Bump seiscomp-base → Run workflow** to prove `gh pr create` as the App.
