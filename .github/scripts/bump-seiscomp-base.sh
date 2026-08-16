#!/usr/bin/env bash
# Open a PR when GHCR has a newer x.y.z tag than Dockerfile FROM.
set -euo pipefail

IMAGE="platformfuzz/seiscomp-base"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

current="$(sed -nE 's|^FROM ghcr.io/platformfuzz/seiscomp-base:([0-9]+\.[0-9]+\.[0-9]+).*|\1|p' "$DOCKERFILE" | head -n1)"
if [[ -z "$current" ]]; then
  echo "could not parse a x.y.z pin from FROM ghcr.io/platformfuzz/seiscomp-base in ${DOCKERFILE}" >&2
  exit 1
fi

token="$(
  curl -fsS "https://ghcr.io/token?service=ghcr.io&scope=repository:${IMAGE}:pull" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
)"
tags_json="$(curl -fsS -H "Authorization: Bearer ${token}" "https://ghcr.io/v2/${IMAGE}/tags/list")"
newest="$(
  printf '%s' "$tags_json" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
pat = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
vers = [t for t in data.get("tags") or [] if pat.match(t)]
if not vers:
    sys.exit("no x.y.z tags on ghcr.io/platformfuzz/seiscomp-base")
vers.sort(key=lambda v: tuple(int(p) for p in v.split(".")))
print(vers[-1])
'
)"

echo "dockerfile pin=${current} newest_ghcr=${newest}"

if python3 -c '
import sys
cur = tuple(int(p) for p in sys.argv[1].split("."))
new = tuple(int(p) for p in sys.argv[2].split("."))
raise SystemExit(0 if new <= cur else 1)
' "$current" "$newest"; then
  echo "already on newest x.y.z tag"
  exit 0
fi

branch="chore/bump-seiscomp-base-${newest}"
open_prs="$(gh pr list --repo "$REPO" --head "$branch" --state open --json number --jq 'length')"
if [[ "${open_prs}" != "0" ]]; then
  echo "open PR already exists for ${branch}"
  exit 0
fi

if git ls-remote --exit-code origin "refs/heads/${branch}" >/dev/null 2>&1; then
  echo "remote branch ${branch} already exists"
  exit 0
fi

sed -i "s|^FROM ghcr.io/platformfuzz/seiscomp-base:${current}|FROM ghcr.io/platformfuzz/seiscomp-base:${newest}|" "$DOCKERFILE"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git checkout -b "$branch"
git add "$DOCKERFILE"
git commit -m "$(cat <<EOF
chore(deps): bump seiscomp-base from ${current} to ${newest}

Track the new GHCR x.y.z tag so the GUI image rebuilds on the
released base rather than staying pinned to ${current}.
EOF
)"
git push -u origin HEAD

gh pr create --repo "$REPO" --base main --head "$branch" \
  --title "chore(deps): bump seiscomp-base from ${current} to ${newest}" \
  --body "$(cat <<EOF
## Summary

- Bump \`FROM ghcr.io/platformfuzz/seiscomp-base\` from \`${current}\` to \`${newest}\` so GUI rebuilds on the new base semver tag.

## Test plan

- [ ] CI docker-image-validate passes
- [ ] After merge, GHCR \`seiscomp-gui\` publishes from the new base
EOF
)"
