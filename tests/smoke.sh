#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PLUGIN="${SCRIPT_DIR}/../kubectl-node_df"
readonly PLUGIN

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

assert_complete_row() {
  local output="$1"
  local node_name="$2"
  local expected_fields="$3"
  local row
  local field_count

  row=$(awk -v node_name="${node_name}" '$1 == node_name { print; exit }' <<<"${output}")
  [[ -n "${row}" ]] || die "output does not contain a row for ${node_name}"

  field_count=$(awk '{ print NF }' <<<"${row}")
  [[ "${field_count}" -eq "${expected_fields}" ]] ||
    die "expected ${expected_fields} fields for ${node_name}, got ${field_count}: ${row}"

  if grep -Eq '(^|[[:space:]])-($|[[:space:]])' <<<"${row}"; then
    die "row contains unavailable values: ${row}"
  fi
}

main() {
  [[ "$#" -eq 0 ]] || die "usage: ${0##*/}"
  [[ -n "${EXPECTED_KUBERNETES_VERSION:-}" ]] ||
    die "EXPECTED_KUBERNETES_VERSION is required"

  require_command kubectl
  require_command jq
  [[ -x "${PLUGIN}" ]] || die "plugin is not executable: ${PLUGIN}"

  kubectl wait --for=condition=Ready node --all --timeout=120s

  local server_version
  local runtime_version
  local node_name
  local summary
  local config
  local output

  server_version=$(kubectl version -o json | jq -r '.serverVersion.gitVersion')
  [[ "${server_version}" == "${EXPECTED_KUBERNETES_VERSION}" ]] ||
    die "expected Kubernetes ${EXPECTED_KUBERNETES_VERSION}, got ${server_version}"

  node_name=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
  [[ -n "${node_name}" ]] || die "cluster has no nodes"
  runtime_version=$(kubectl get node "${node_name}" -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}')
  [[ -n "${runtime_version}" ]] || die "node did not report a container runtime version"

  summary=$(kubectl get --raw "/api/v1/nodes/${node_name}/proxy/stats/summary")
  jq -e '
    (.node.fs | type == "object") and
    (.node.fs.capacityBytes | type == "number") and
    (.node.fs.capacityBytes > 0) and
    (.node.runtime.imageFs | type == "object")
  ' <<<"${summary}" >/dev/null || die "Summary API did not return node filesystem metrics"

  config=$(kubectl get --raw "/api/v1/nodes/${node_name}/proxy/configz")
  jq -e '
    (.kubeletconfig.evictionHard["imagefs.available"] | type == "string") and
    (.kubeletconfig.evictionHard["nodefs.available"] | type == "string") and
    (.kubeletconfig.evictionHard["nodefs.inodesFree"] | type == "string")
  ' <<<"${config}" >/dev/null || die "configz did not return expected eviction thresholds"

  output=$("${PLUGIN}" "${node_name}")
  printf '%s\n' "${output}"
  assert_complete_row "${output}" "${node_name}" 5
  assert_complete_row "${output}" "${node_name}:imagefs" 5

  output=$("${PLUGIN}" -o wide "${node_name}")
  printf '%s\n' "${output}"
  assert_complete_row "${output}" "${node_name}" 9

  output=$("${PLUGIN}" --inodes "${node_name}")
  printf '%s\n' "${output}"
  assert_complete_row "${output}" "${node_name}" 6

  printf 'Smoke test passed on Kubernetes %s with %s (%s)\n' \
    "${server_version}" "${runtime_version}" "${node_name}"
}

main "$@"
