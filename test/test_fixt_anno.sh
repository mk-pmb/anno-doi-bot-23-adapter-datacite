#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

[ "$1" == --lib ] || exec "$(readlink -m -- "$BASH_SOURCE"/../../adapter.sh
  )" run_test $(basename -- "${BASH_SOURCE##*/test_}" .sh) || exit $?


function test_fixt_anno () {
  elp || return $?

  local DBGLV="${DEBUGLEVEL:-0}"
  local FIXT_BFN='test/fixtures/doibot-test-v'
  local QUOT='"' APOS="'"
  local CREA1='s~"?,?$~~;s~^\s+"created":\s*"~~p'
  CREA1="$(sed -nre "$CREA1" -- "$FIXT_BFN"1.json)"
  [ -n "$CREA1" ] || return 5$(echo "E: no CREA1" >&2)

  test_fixt_anno__one_ver 1 || return $?
  test_fixt_anno__one_ver 2 || return $?
}


function test_fixt_anno__one_ver () {
  local ANNO_VER_NUM="$1"
  echo P: "test $FUNCNAME ~$ANNO_VER_NUM"
  local FIXT_FILE="$FIXT_BFN$ANNO_VER_NUM.json"
  local RESULTS_BFN="test/tmp.doibot-test-$ANNO_VER_NUM"
  local DATACITE_JSON="$RESULTS_BFN.json"
  local FIXT_SED='
    s~^(\s*[^"a-z:]*"id":\s*")([^"/]+",?)$~\1<°anno_base_url><°id>\2~
    '
  local FIXT_DATA="$(sed -rf <(echo "$FIXT_SED") -- "$FIXT_FILE")"
  local ANNO_VERS_ID="${FIXT_DATA#*<°id>}"
  ANNO_VERS_ID="${ANNO_VERS_ID%%$QUOT*}"
  FIXT_DATA="${FIXT_DATA//<°id>/}"
  FIXT_DATA="${FIXT_DATA//<°anno_base_url>/$anno_baseurl}"

  local REG_DOI="${anno_doi_prefix:-0.NO.PREFIX.}$(
    )${ANNO_VERS_ID/\~/${anno_doi_versep:-|}}$(
    )${CFG[anno_doi_suffix]}"
  echo "D: Expected DOI: $REG_DOI"

  <<<"$FIXT_DATA" \
    anno_initial_version_date="$CREA1" \
    anno_doi_expect="$REG_DOI" \
    anno_ver_num="$VHE_NUM" \
    ./adapter.sh update_doi_meta_for_one_anno_on_stdin \
    |& tee -- "$RESULTS_BFN.log" || return $?
}


return 0
