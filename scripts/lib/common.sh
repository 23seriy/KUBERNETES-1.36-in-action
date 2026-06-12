#!/usr/bin/env bash
# Shared helpers for all numbered scripts.
# Source with: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Color codes — only emit if stdout is a TTY.
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    NC=''
fi

info()   { printf '%b[INFO]%b  %s\n'  "$GREEN"  "$NC" "$*"; }
warn()   { printf '%b[WARN]%b  %s\n'  "$YELLOW" "$NC" "$*"; }
error()  { printf '%b[ERROR]%b %s\n'  "$RED"    "$NC" "$*" >&2; }
header() {
    printf '\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$CYAN" "$NC"
    printf '%b  %s%b\n'                                            "$CYAN" "$*" "$NC"
    printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n\n' "$CYAN" "$NC"
}

# Profile and namespace are consistent across all scripts.
export MINIKUBE_PROFILE="k8s136-in-action"
export DEMO_NAMESPACE="k8s136-demo"
export TARGET_K8S_VERSION="v1.36.0"
