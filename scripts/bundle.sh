#!/usr/bin/env bash
# Sync inventory into a Hauler store, save the haul, upload to S3.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

require_cmd yq
require_cmd hauler
require_cmd aws

[[ -n "${ARTIFACT_BUCKET}" ]] || die "ARTIFACT_BUCKET is required"

configure_pull_auth

cd "$ROOT_DIR"
mkdir -p hauler/store

artifact_name="$HAULER_ARTIFACT_NAME"

{
  printf '%s\n' \
    'apiVersion: content.hauler.cattle.io/v1' \
    'kind: Images' \
    'metadata:' \
    '  name: hauler-inventory' \
    'spec:' \
    '  images:'

  while IFS= read -r path; do
    [[ -f "$path" ]] || { log "inventory not found: $path"; continue; }
    count=$(yq '.inventory // [] | length' "$path")
    for ((i = 0; i < count; i++)); do
      entry_type=$(yq -r ".inventory[$i] | tag" "$path")
      if [[ "$entry_type" == "!!str" ]]; then
        name=$(yq -r ".inventory[$i]" "$path")
      else
        name=$(yq -r ".inventory[$i].name" "$path")
      fi
      [[ -n "$name" && "$name" != "null" ]] || continue
      printf '    - name: %s\n' "$name"
    done
  done < <(inventory_paths)

  printf '%s\n' \
    '---' \
    'apiVersion: content.hauler.cattle.io/v1' \
    'kind: Charts' \
    'metadata:' \
    '  name: hauler-helm-charts' \
    'spec:' \
    '  charts:'

  while IFS= read -r path; do
    [[ -f "$path" ]] || continue
    count=$(yq '.charts // [] | length' "$path")
    for ((i = 0; i < count; i++)); do
      name=$(yq -r ".charts[$i].name" "$path")
      version=$(yq -r ".charts[$i].version" "$path")
      repo=$(yq -r ".charts[$i].repo" "$path")
      [[ -n "$name" && "$name" != "null" ]] || continue
      [[ -n "$repo" && "$repo" != "null" ]] || continue
      # Hauler Charts expect an HTTP(S) or OCI repo URL.
      if [[ "$repo" == oci://* || "$repo" == https://* || "$repo" == http://* ]]; then
        repo_url="$repo"
      elif [[ "$repo" == *.git ]]; then
        # Git chart sources are not pulled by hauler store sync; skip with a warning.
        log "skipping git chart source ${name} (${repo}) — use an HTTP/OCI chart repo"
        continue
      else
        repo_url="$repo"
      fi
      printf '    - name: %s\n      repoURL: %s\n      version: "%s"\n' \
        "$name" "$repo_url" "$version"
    done
  done < <(inventory_paths)
} >hauler/store.yaml

log "hauler store sync"
hauler store sync --store hauler/store --filename hauler/store.yaml
log "hauler store save → ${artifact_name}"
hauler store save --store hauler/store --filename "${artifact_name}"

haul="${artifact_name}.tar.zst"
[[ -f "$haul" ]] || haul="${artifact_name}"
[[ -f "$haul" ]] || die "hauler store save produced no haul"

prefix="$(artifact_tag_prefix)"
cp -f "$haul" "${prefix}.tar.zst"
cp -f hauler/store.yaml "${prefix}.yaml"

s3_dir="s3://${ARTIFACT_BUCKET}/${ARTIFACT_PREFIX}/${prefix}"
log "upload → ${s3_dir}/"
aws s3 cp "${prefix}.tar.zst" "${s3_dir}/${prefix}.tar.zst"
aws s3 cp "${prefix}.yaml" "${s3_dir}/${prefix}.yaml"

aws s3 cp "${prefix}.tar.zst" "s3://${ARTIFACT_BUCKET}/${ARTIFACT_PREFIX}/${artifact_name}-latest.tar.zst"
aws s3 cp "${prefix}.yaml" "s3://${ARTIFACT_BUCKET}/${ARTIFACT_PREFIX}/${artifact_name}-latest.yaml"

ref="${s3_dir}/${prefix}.tar.zst"
cat >hauler.env <<EOF
HAULER_S3_URI=${ref}
HAULER_ARTIFACT_NAME=${artifact_name}
HAULER_ARTIFACT_PREFIX=${prefix}
DATE=${DATE}
COMMIT_SHORT_SHA=${COMMIT_SHORT_SHA}
EOF

log "HAULER_S3_URI=${ref}"
log "bundle complete"
