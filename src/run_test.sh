#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function run_test () {
  local TEST_NAME="$1"; shift
  source_in_func "$DBA_PATH/test/test_$TEST_NAME.sh" --lib || return $?
  env_export_anno_cfg || return $?
  test_"$TEST_NAME" "$@" || return $?
}

return 0
