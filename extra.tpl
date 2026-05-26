#!/usr/bin/env zsh
# extra.tpl — template for ~/.extra. Materialized via `op inject` by install.sh,
# or copied as-is if 1Password CLI is unavailable.
#
# To regenerate manually:    op inject -i extra.tpl -o ~/.extra && chmod 600 ~/.extra
# To inspect placeholders:   grep -o 'op://[^ )}]*' extra.tpl

# =============================================================================
# GetYourGuide
# =============================================================================
# Create a 1Password item "GYG" (Private vault) with fields:
#   - databricks_host       (Text)
#   - aws_profile           (Text)   e.g. production/developer
#   - aws_codeartifact_domain (Text) e.g. getyourguide
#   - aws_account_id        (Text)   e.g. 130607246975
# Then `op signin` once per laptop and re-run `./install.sh link`.

export MLFLOW_TRACKING_URI=databricks
export DATABRICKS_HOST="op://Private/GYG/databricks_host"

# AWS CodeArtifact token. Cached on disk for 10h so subsequent shells start
# instantly. Token is refreshed automatically on cache miss / expiry; run
# `ca-refresh` to force a refresh after AWS SSO re-login.
_CA_CACHE_FILE="${TMPDIR:-/tmp}/codeartifact-token-${USER}"
_CA_CACHE_TTL=36000   # 10h

_CA_AWS_PROFILE="op://Private/GYG/aws_profile"
_CA_AWS_DOMAIN="op://Private/GYG/aws_codeartifact_domain"
_CA_AWS_ACCOUNT="op://Private/GYG/aws_account_id"

_ca_token() {
  if [[ -r "$_CA_CACHE_FILE" ]]; then
    local mtime
    mtime=$(stat -f %m "$_CA_CACHE_FILE" 2>/dev/null || stat -c %Y "$_CA_CACHE_FILE" 2>/dev/null)
    if (( $(date +%s) - mtime < _CA_CACHE_TTL )); then
      cat "$_CA_CACHE_FILE"
      return 0
    fi
  fi
  command -v aws >/dev/null || return 1
  local token
  token=$(aws codeartifact get-authorization-token \
            --profile "$_CA_AWS_PROFILE" \
            --domain "$_CA_AWS_DOMAIN" \
            --domain-owner "$_CA_AWS_ACCOUNT" \
            --query authorizationToken --output text 2>/dev/null) || return 1
  printf '%s' "$token" > "$_CA_CACHE_FILE"
  chmod 600 "$_CA_CACHE_FILE"
  printf '%s' "$token"
}

ca-refresh() {
  rm -f "$_CA_CACHE_FILE"
  if _t=$(_ca_token); then
    export POETRY_HTTP_BASIC_CODEARTIFACT_USERNAME=aws
    export POETRY_HTTP_BASIC_CODEARTIFACT_PASSWORD="$_t"
    export CODEARTIFACT_AUTH_TOKEN="$_t"
    echo "CodeArtifact token refreshed (valid ~10h)."
    unset _t
  else
    echo "Failed to fetch CodeArtifact token. Did you run 'aws sso login'?" >&2
    return 1
  fi
}

if _t=$(_ca_token 2>/dev/null); then
  export POETRY_HTTP_BASIC_CODEARTIFACT_USERNAME=aws
  export POETRY_HTTP_BASIC_CODEARTIFACT_PASSWORD="$_t"
  export CODEARTIFACT_AUTH_TOKEN="$_t"
  unset _t
fi

# =============================================================================
# Personal secrets (example — uncomment + adapt)
# =============================================================================
# export OPENAI_API_KEY="op://Private/OpenAI/credential"
# export ANTHROPIC_API_KEY="op://Private/Anthropic/credential"
# export GITHUB_TOKEN="op://Private/GitHub PAT/credential"
