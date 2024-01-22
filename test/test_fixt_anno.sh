#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

[ "$1" == --lib ] || exec "$(readlink -m -- "$BASH_SOURCE"/../../adapter.sh
  )" run_test $(basename -- "${BASH_SOURCE##*/test_}" .sh) || exit $?


function test_fixt_anno () {
  local DBGLV="${DEBUGLEVEL:-0}"
  local QUOT='"' APOS="'"
  local VERS_ID_RGX='^[a-z0-9_.-]+\~[1-9][0-9]*$'

  echo -n 'Lint: '; elp || return $?

  local ERR_CNT=0 SXS_CNT=0
  test_fixt_anno__all_vers 'doibot-test-v'
  # test_fixt_anno__all_vers 'esau-rsterr_'

  echo
  [ "$ERR_CNT" == 0 ] || return "$ERR_CNT"$(
    echo >&2 "-ERR $ERR_CNT fixtures tests failed. ($SXS_CNT succeeded.)")
  echo "+OK All $SXS_CNT fixtures tests succeeded."
}


function find_json_prop () {
  local PROP="$1"; shift
  sed -nre 's~"?,?$~~;s~^\s+"'"$PROP"'":\s*"~~p' "$@" || return $?
}


function test_fixt_anno__all_vers () {
  local FIXT_BFN_NOVERS="test/fixtures/$1"; shift
  local FIXT_FILE= ANNO_VER_NUM= CREA1=
  local MIN_VER_NUM= MAX_VER_NUM=
  for FIXT_FILE in "$FIXT_BFN_NOVERS"[0-9]*.anno.json; do
    [ -f "$FIXT_FILE" ] || continue
    ANNO_VER_NUM="${FIXT_FILE:${#FIXT_BFN_NOVERS}}"
    ANNO_VER_NUM="${ANNO_VER_NUM%.anno.json}"
    [ -n "$MIN_VERS" ] || MIN_VERS="$ANNO_VER_NUM"
    [ "$MIN_VERS" -lt "$ANNO_VER_NUM" ] || MIN_VERS="$ANNO_VER_NUM"
    [ -n "$MAX_VERS" ] || MAX_VERS="$ANNO_VER_NUM"
    [ "$MAX_VERS" -gt "$ANNO_VER_NUM" ] || MAX_VERS="$ANNO_VER_NUM"
  done
  ANNO_VER_NUM=0
  while [ "$ANNO_VER_NUM" -lt "$MAX_VERS" ]; do
    (( ANNO_VER_NUM += 1 ))
    FIXT_FILE="$FIXT_BFN_NOVERS$ANNO_VER_NUM.anno.json"
    [ -f "$FIXT_FILE" ] || continue
    [ -n "$CREA1" ] || CREA1="$(find_json_prop created <"$FIXT_FILE")"
    [ -n "$CREA1" ] || return 5$(echo "E: no CREA1" >&2)
    test_fixt_anno__one_ver && continue
    echo W: $FUNCNAME: >&2 "Test failed (rv=$?) for $FIXT_FILE"
    (( ERR_CNT += 1 ))
  done
  if [ -z "$CREA1" ]; then
    echo E: $FUNCNAME: >&2 "Fond no fixtures for $FIXT_BFN_NOVERS"
    (( ERR_CNT += 1 ))
    return 5
  fi
}


function test_fixt_anno__one_ver () {
  [ -n "$CREA1" ] || return 4$(
    echo E: $FUNCNAME: "Missing creation date of first anno version!" >&2)
  echo
  echo P: "test $FUNCNAME $FIXT_BFN_NOVERS ~$ANNO_VER_NUM$(
    [ "$ANNO_VER_NUM" == "$MIN_VERS" ] && echo -n ' (first)'
    [ "$ANNO_VER_NUM" == "$MAX_VERS" ] && echo -n ' (latest)'
    )"
  [ "${ANNO_VER_NUM:-0}" -ge 1 ] || return 5$(
    echo E: $FUNCNAME: 'Expected a positive number as ANNO_VER_NUM.' >&2)
  local FIXT_VERS_BFN="$FIXT_BFN_NOVERS$ANNO_VER_NUM"
  local FIXT_FILE="$FIXT_VERS_BFN.anno.json"
  local RESULTS_BFN="test/tmp.$(basename -- "$FIXT_VERS_BFN")"
  local FIXT_DATA="$(./test/mark_anno_fixture_slots.sed -- "$FIXT_FILE")"
  local ANNO_VERS_ID="${FIXT_DATA#*<°id>}"
  ANNO_VERS_ID="${ANNO_VERS_ID%%$QUOT*}"
  [[ "$ANNO_VERS_ID" =~ $VERS_ID_RGX ]] || return 4$(
    echo E: $FUNCNAME: "Failed to detect ANNO_VERS_ID" >&2)
  FIXT_DATA="${FIXT_DATA//<°id>/}"
  FIXT_DATA="${FIXT_DATA//<°anno_base_url>/$anno_baseurl}"

  local REG_DOI="${anno_doi_prefix:-0.NO.PREFIX.}$(
    )${ANNO_VERS_ID/\~/${anno_doi_versep:-|}}$(
    )${CFG[anno_doi_suffix]}"
  echo "D: Expected DOI: $REG_DOI"

  local ADAPT=(
    env
    anno_initial_version_date="$CREA1"
    anno_doi_expect="$REG_DOI"
    anno_ver_num="$VHE_NUM"
    ./adapter.sh
    )

  local DCMETA="$RESULTS_BFN.anno2dc.json"
  <<<"$FIXT_DATA" "${ADAPT[@]}" dc_api_anno_to_doirequest \
    >"$DCMETA" || return $?
  diff -sU 2 -- "$FIXT_VERS_BFN.dcmeta.json" "$DCMETA" || return $?
  rm -- "$DCMETA"

  <<<"$FIXT_DATA" "${ADAPT[@]}" update_doi_meta_for_one_anno_on_stdin \
    |& tee -- "$RESULTS_BFN.log"
  [ "${PIPESTATUS[*]}" == '0 0' ] || return 4
  rm -- "$RESULTS_BFN.log"

  (( SXS_CNT += 1 ))
}


return 0
