#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
plugin="$repo_dir/kubectl-node_df"
PATH="$repo_dir/tests/fixtures:$PATH"
export PATH

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  haystack=$1
  needle=$2
  printf '%s\n' "$haystack" | grep -F -- "$needle" >/dev/null ||
    fail "expected output to contain: $needle"
}

assert_row() {
  table=$1
  row_name=$2
  expected=$3
  actual=$(printf '%s\n' "$table" | awk -v row_name="$row_name" '
    $1 == row_name {
      for (i = 1; i <= NF; i++) {
        printf "%s%s", (i == 1 ? "" : " "), $i
      }
      print ""
    }
  ')
  [ "$actual" = "$expected" ] ||
    fail "row $row_name: expected '$expected', got '$actual'"
}

help_output=$($plugin --help)
assert_contains "$help_output" "Usage: kubectl node-df"

output=$($plugin)
assert_row "$output" "node-a" "node-a 10.0G 30.0G 40.0G 25%"
assert_row "$output" "node-a:imagefs" "node-a:imagefs 5.0G 15.0G 20.0G 25%"
assert_row "$output" "node-a:containerfs" "node-a:containerfs 1.0G - 4.0G 25%"
assert_row "$output" "node-b" "node-b - - - -"

wide_output=$($plugin -o wide)
assert_row "$wide_output" "node-a" "node-a 10.0G 30.0G 40.0G 25% +13.0G +26.0G +65% +65%"

inode_output=$($plugin --inodes)
assert_row "$inode_output" "node-a" "node-a 100 900 1000 10% +800"
assert_row "$inode_output" "node-a:containerfs" "node-a:containerfs 10 - 100 10% -"

explicit_output=$($plugin node-a)
if printf '%s\n' "$explicit_output" | grep -F 'node-b' >/dev/null; then
  fail "explicit node selection unexpectedly included node-b"
fi

if NODE_DF_PARALLEL=0 "$plugin" >/dev/null 2>&1; then
  fail "NODE_DF_PARALLEL=0 should fail"
fi

if "$plugin" ../escape >/dev/null 2>&1; then
  fail "invalid node names should fail"
fi

printf '%s\n' "All tests passed"
