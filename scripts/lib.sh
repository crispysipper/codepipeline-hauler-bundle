#!/usr/bin/env bash
# Shared helpers for the Hauler CodeBuild job.
set -euo pipefail

ROOT_DIR="${CODEBUILD_SRC_DIR:-${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
export ROOT_DIR

DATE="${DATE:-$(date +%Y%m%d)}"
COMMIT_SHA="${COMMIT_SHA:-${CODEBUILD_RESOLVED_SOURCE_VERSION:-unknown}}"
COMMIT_SHORT_SHA="${COMMIT_SHORT_SHA:-${COMMIT_SHA:0:7}}"
export DATE COMMIT_SHA COMMIT_SHORT_SHA

INVENTORY_MANIFEST="${INVENTORY_MANIFEST:-manifests/inventory.yaml}"
HAULER_ARTIFACT_NAME="${HAULER_ARTIFACT_NAME:-rke2-bootstrap}"
ARTIFACT_BUCKET="${ARTIFACT_BUCKET:-}"
ARTIFACT_PREFIX="${ARTIFACT_PREFIX:-hauler-bundles}"

AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
export AWS_REGION AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-$AWS_REGION}"

export REGISTRY_AUTH_FILE="${REGISTRY_AUTH_FILE:-${HOME}/.docker/config.json}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-$(dirname "$REGISTRY_AUTH_FILE")}"
mkdir -p "$(dirname "$REGISTRY_AUTH_FILE")"
[[ -f "$REGISTRY_AUTH_FILE" ]] || echo '{"auths":{}}' >"$REGISTRY_AUTH_FILE"

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# Optional pull credentials for upstream registries (Iron Bank, Docker Hub, etc.).
configure_pull_auth() {
  if [[ -n "${DOCKER_AUTH_CONFIG:-}" ]]; then
    echo "$DOCKER_AUTH_CONFIG" >"$REGISTRY_AUTH_FILE"
    log "Loaded DOCKER_AUTH_CONFIG into ${REGISTRY_AUTH_FILE}"
  fi
  if [[ -n "${DOCKER_CONFIG_JSON_SECRET_ARN:-}" ]]; then
    aws secretsmanager get-secret-value \
      --secret-id "$DOCKER_CONFIG_JSON_SECRET_ARN" \
      --query SecretString --output text >"$REGISTRY_AUTH_FILE"
    log "Loaded docker config from Secrets Manager"
  fi
}

inventory_paths() {
  local IFS=','
  # shellcheck disable=SC2206
  local parts=(${INVENTORY_MANIFEST})
  local p
  for p in "${parts[@]}"; do
    p="${p#"${p%%[![:space:]]*}"}"
    p="${p%"${p##*[![:space:]]}"}"
    [[ -n "$p" ]] || continue
    if [[ "$p" = /* ]]; then
      printf '%s\n' "$p"
    else
      printf '%s\n' "${ROOT_DIR}/${p}"
    fi
  done
}

artifact_tag_prefix() {
  printf '%s-%s-%s' "$HAULER_ARTIFACT_NAME" "$DATE" "$COMMIT_SHORT_SHA"
}
