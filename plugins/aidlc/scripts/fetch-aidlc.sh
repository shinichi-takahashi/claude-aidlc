#!/usr/bin/env bash
# fetch-aidlc.sh — Fetch AI-DLC workflow rules from awslabs/aidlc-workflows
#
# Usage:
#   fetch-aidlc.sh init    — Download rules for the first time
#   fetch-aidlc.sh check   — Check if a newer version is available
#   fetch-aidlc.sh update  — Update to the latest version
#
# Environment:
#   AIDLC_TARGET_DIR  — Target directory (default: current directory)

set -euo pipefail

REPO_OWNER="awslabs"
REPO_NAME="aidlc-workflows"
RULES_BASE_PATH="aidlc-rules"
CORE_WORKFLOW_PATH="${RULES_BASE_PATH}/aws-aidlc-rules/core-workflow.md"
RULE_DETAILS_PATH="${RULES_BASE_PATH}/aws-aidlc-rule-details"

TARGET_DIR="${AIDLC_TARGET_DIR:-.}"
VERSION_FILE="${TARGET_DIR}/.aidlc-version"
RULE_DETAILS_DIR="${TARGET_DIR}/.aidlc-rule-details"
CORE_WORKFLOW_DEST="${RULE_DETAILS_DIR}/core-workflow.md"

# ─── Helpers ────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo ":: $*"; }

# Get latest release tag. Tries gh CLI first, falls back to curl.
get_latest_tag() {
  local tag
  if command -v gh &>/dev/null; then
    tag=$(gh api "repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" --jq '.tag_name' 2>/dev/null) && {
      echo "$tag"
      return
    }
  fi
  # Fallback to curl
  tag=$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" 2>/dev/null \
    | grep '"tag_name"' | head -1 | sed 's/.*: *"//;s/".*//')
  [[ -n "$tag" ]] || die "Failed to fetch latest release tag"
  echo "$tag"
}

# Get release notes for a specific tag
get_release_notes() {
  local tag="$1"
  if command -v gh &>/dev/null; then
    gh api "repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${tag}" --jq '.body' 2>/dev/null && return
  fi
  curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${tag}" 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('body',''))" 2>/dev/null || true
}

# List rule files via GitHub Trees API, with a hardcoded fallback.
list_rule_detail_files() {
  local tag="$1"
  local files

  # Try Trees API (gh → curl)
  if command -v gh &>/dev/null; then
    files=$(gh api "repos/${REPO_OWNER}/${REPO_NAME}/git/trees/${tag}?recursive=1" \
      --jq ".tree[] | select(.path | startswith(\"${RULE_DETAILS_PATH}/\")) | .path" 2>/dev/null) && {
      echo "$files"
      return
    }
  fi
  files=$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/git/trees/${tag}?recursive=1" 2>/dev/null \
    | grep "\"path\"" | sed 's/.*"path": *"//;s/".*//' \
    | grep "^${RULE_DETAILS_PATH}/.*\.md$") && {
    echo "$files"
    return
  }

  # Hardcoded fallback (v0.1.3 structure)
  info "Trees API unavailable, using fallback file list"
  cat <<'FALLBACK'
aidlc-rules/aws-aidlc-rule-details/common/ascii-diagram-standards.md
aidlc-rules/aws-aidlc-rule-details/common/content-validation.md
aidlc-rules/aws-aidlc-rule-details/common/depth-levels.md
aidlc-rules/aws-aidlc-rule-details/common/error-handling.md
aidlc-rules/aws-aidlc-rule-details/common/overconfidence-prevention.md
aidlc-rules/aws-aidlc-rule-details/common/process-overview.md
aidlc-rules/aws-aidlc-rule-details/common/question-format-guide.md
aidlc-rules/aws-aidlc-rule-details/common/session-continuity.md
aidlc-rules/aws-aidlc-rule-details/common/terminology.md
aidlc-rules/aws-aidlc-rule-details/common/welcome-message.md
aidlc-rules/aws-aidlc-rule-details/common/workflow-changes.md
aidlc-rules/aws-aidlc-rule-details/construction/build-and-test.md
aidlc-rules/aws-aidlc-rule-details/construction/code-generation.md
aidlc-rules/aws-aidlc-rule-details/construction/functional-design.md
aidlc-rules/aws-aidlc-rule-details/construction/infrastructure-design.md
aidlc-rules/aws-aidlc-rule-details/construction/nfr-design.md
aidlc-rules/aws-aidlc-rule-details/construction/nfr-requirements.md
aidlc-rules/aws-aidlc-rule-details/inception/application-design.md
aidlc-rules/aws-aidlc-rule-details/inception/requirements-analysis.md
aidlc-rules/aws-aidlc-rule-details/inception/reverse-engineering.md
aidlc-rules/aws-aidlc-rule-details/inception/units-generation.md
aidlc-rules/aws-aidlc-rule-details/inception/user-stories.md
aidlc-rules/aws-aidlc-rule-details/inception/workflow-planning.md
aidlc-rules/aws-aidlc-rule-details/inception/workspace-detection.md
aidlc-rules/aws-aidlc-rule-details/operations/operations.md
FALLBACK
}

# Download a single file from raw.githubusercontent.com
download_file() {
  local tag="$1" remote_path="$2" local_path="$3"
  local url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${tag}/${remote_path}"
  local dir
  dir=$(dirname "$local_path")
  mkdir -p "$dir"
  curl -fsSL -o "$local_path" "$url" || die "Failed to download: ${remote_path}"
}

# ─── Subcommands ────────────────────────────────────────────────────

do_init() {
  info "Fetching latest AI-DLC release tag..."
  local tag
  tag=$(get_latest_tag)
  info "Latest version: ${tag}"

  # Download core-workflow.md → .aidlc-rule-details/core-workflow.md
  info "Downloading core-workflow.md..."
  download_file "$tag" "$CORE_WORKFLOW_PATH" "$CORE_WORKFLOW_DEST"

  # Download rule details
  info "Fetching rule detail file list..."
  local files
  files=$(list_rule_detail_files "$tag")

  local count=0
  while IFS= read -r fpath; do
    [[ "$fpath" == *.md ]] || continue
    local rel="${fpath#${RULE_DETAILS_PATH}/}"
    local dest="${RULE_DETAILS_DIR}/${rel}"
    info "  ${rel}"
    download_file "$tag" "$fpath" "$dest"
    count=$((count + 1))
  done <<< "$files"

  # Save version
  echo "$tag" > "$VERSION_FILE"

  info "Done! Installed AI-DLC ${tag} (${count} rule detail files + core-workflow.md)"
}

do_check() {
  local current_tag latest_tag

  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "NOT_INITIALIZED"
    return
  fi

  current_tag=$(cat "$VERSION_FILE")
  latest_tag=$(get_latest_tag)

  if [[ "$current_tag" == "$latest_tag" ]]; then
    echo "UP_TO_DATE ${current_tag}"
  else
    echo "UPDATE_AVAILABLE ${current_tag} ${latest_tag}"
  fi
}

do_update() {
  if [[ ! -f "$VERSION_FILE" ]]; then
    die "AI-DLC is not initialized. Run init first."
  fi

  local current_tag latest_tag
  current_tag=$(cat "$VERSION_FILE")
  latest_tag=$(get_latest_tag)

  if [[ "$current_tag" == "$latest_tag" ]]; then
    info "Already up to date: ${current_tag}"
    return
  fi

  info "Updating AI-DLC from ${current_tag} to ${latest_tag}..."

  # Clean old rule details
  if [[ -d "$RULE_DETAILS_DIR" ]]; then
    rm -rf "$RULE_DETAILS_DIR"
  fi

  # Download core-workflow.md → .aidlc-rule-details/core-workflow.md
  info "Downloading core-workflow.md..."
  download_file "$latest_tag" "$CORE_WORKFLOW_PATH" "$CORE_WORKFLOW_DEST"

  # Download rule details
  info "Fetching rule detail file list..."
  local files
  files=$(list_rule_detail_files "$latest_tag")

  local count=0
  while IFS= read -r fpath; do
    [[ "$fpath" == *.md ]] || continue
    local rel="${fpath#${RULE_DETAILS_PATH}/}"
    local dest="${RULE_DETAILS_DIR}/${rel}"
    info "  ${rel}"
    download_file "$latest_tag" "$fpath" "$dest"
    count=$((count + 1))
  done <<< "$files"

  # Save version
  echo "$latest_tag" > "$VERSION_FILE"

  info "Done! Updated AI-DLC to ${latest_tag} (${count} rule detail files + core-workflow.md)"
}

# ─── Main ───────────────────────────────────────────────────────────

case "${1:-}" in
  init)   do_init ;;
  check)  do_check ;;
  update) do_update ;;
  *)      die "Usage: $0 {init|check|update}" ;;
esac
