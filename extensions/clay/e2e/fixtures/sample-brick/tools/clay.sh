#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
monorepo_root="$(cd "${script_dir}/../../../../../../" && pwd)"

exec dart run "${monorepo_root}/packages/clay_cli/bin/clay.dart" "$@"
