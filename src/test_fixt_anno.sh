#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function test_fixt_anno () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?
  elp -- *.mjs || return $?

  local FIXT_BFN='../test/fixtures/9a7d0028~'
  local CREA1='s~"?,?$~~;s~^\s+"created":\s*"~~p'
  CREA1="$(sed -nre "$CREA1" -- "$FIXT_BFN"1.json)"
  [ -n "$CREA1" ] || return 5$(echo "E: no CREA1" >&2)
  export initialVersionDate="$CREA1"

  test_one_ver 1 || return $?
  test_one_ver 2 || return $?
}


function test_one_ver () {
  local ANNO_VER_NUM="$1"
  local FIXT_FILE="$FIXT_BFN$ANNO_VER_NUM.json"
  local DATACITE_JSON="tmp.test-9a7d0028~$ANNO_VER_NUM.log.json"
  <"$FIXT_FILE" ./debugcli.sh doibot_update_one_anno_stdin || return $?
}


test_fixt_anno "$@"; exit $?
