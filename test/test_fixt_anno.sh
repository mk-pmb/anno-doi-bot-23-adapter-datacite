#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

[ "$1" == --lib ] || exec "$(readlink -m -- "$BASH_SOURCE"/../../adapter.sh
  )" run_test $(basename -- "${BASH_SOURCE##*/test_}" .sh) || exit $?


function test_fixt_anno () {
  local DBGLV="${DEBUGLEVEL:-0}"
  local QUOT='"' APOS="'"
  local VERS_ID_RGX='^[a-z0-9_.-]+\~[1-9][0-9]*$'

  echo -n 'Lint: '; elp || return $?

  local TEST_SKIPS=" ${CFG[doibot_test_skips]//[$'\t\r\n']/ } "
  local ERR_CNT=0 SXS_CNT=0
  test_fixt_anno__all_vers 'dbt240126-'
  test_fixt_anno__all_vers 'esau-rsterr_'

  echo
  [ "$ERR_CNT" == 0 ] || return "$ERR_CNT"$(
    echo >&2 "-ERR $ERR_CNT fixtures tests failed. ($SXS_CNT succeeded.)")
  echo "+OK All $SXS_CNT fixtures tests succeeded."
}


function find_json_prop () {
  local PROP="$1"; shift
  sed -nre 's~"?,?$~~;s~^\s+"'"$PROP"'":\s*"~~p' "$@" || return $?
}


function test_check_skip () {
  [[ "$TEST_SKIPS" == *' ?checks? '* ]] \
    && echo D: ${FUNCNAME[1]}: "check skip: $1" >&2
  [[ "$TEST_SKIPS" == *" $1 "* ]] || return 1
  echo W: ${FUNCNAME[1]}: "skip as configured: $1" >&2
}


function test_fixt_anno__all_vers () {
  echo
  test_check_skip fixt:"$1" && return 0
  local FIXT_BFN_NOVERS="test/fixtures/$1"; shift
  local FIXT_FILE= ANNO_VER_NUM= CREA1=
  local MIN_VER_NUM= MAX_VER_NUM=
  for FIXT_FILE in "$FIXT_BFN_NOVERS"[0-9]*.anno.json; do
    [ -f "$FIXT_FILE" ] || continue
    ANNO_VER_NUM="${FIXT_FILE:${#FIXT_BFN_NOVERS}}"
    ANNO_VER_NUM="${ANNO_VER_NUM%.anno.json}"
    [ -n "$MIN_VER_NUM" ] || MIN_VER_NUM="$ANNO_VER_NUM"
    [ "$MIN_VER_NUM" -lt "$ANNO_VER_NUM" ] || MIN_VER_NUM="$ANNO_VER_NUM"
    [ -n "$MAX_VER_NUM" ] || MAX_VER_NUM="$ANNO_VER_NUM"
    [ "$MAX_VER_NUM" -gt "$ANNO_VER_NUM" ] || MAX_VER_NUM="$ANNO_VER_NUM"
  done
  ANNO_VER_NUM=0
  while [ "$ANNO_VER_NUM" -lt "$MAX_VER_NUM" ]; do
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

  ANNO_VER_NUM="lvr:$MAX_VER_NUM" test_fixt_anno__one_ver || (( ERR_CNT += 1 ))
}


function test_fixt_anno__one_ver () {
  local FIXT_SKIP_ID="$FIXT_BFN_NOVERS~$ANNO_VER_NUM"
  test_check_skip fixt:"$FIXT_SKIP_ID" && return 0
  [ -n "$CREA1" ] || return 4$(
    echo E: $FUNCNAME: "Missing creation date of first anno version!" >&2)
  echo
  echo P: "$FUNCNAME: $FIXT_BFN_NOVERS ~$ANNO_VER_NUM$(
    [ "$ANNO_VER_NUM" == "$MIN_VER_NUM" ] && echo -n ' (first)'
    [ "$ANNO_VER_NUM" == "$MAX_VER_NUM" ] && echo -n ' (latest)'
    )"
  local VER_FX=
  case "$ANNO_VER_NUM" in
    [a-z]*:[0-9]* )
      VER_FX="${ANNO_VER_NUM%:*}"
      ANNO_VER_NUM="${ANNO_VER_NUM#*:}"
      ;;
  esac
  [ "${ANNO_VER_NUM:-0}" -ge 1 ] || return 5$(
    echo E: $FUNCNAME: 'Expected a positive number as ANNO_VER_NUM.' >&2)
  local RESULTS_BFN="test/tmp.$(basename -- "$FIXT_BFN_NOVERS"
    )${VER_FX:-$ANNO_VER_NUM}"
  local FIXT_VERS_BFN="$FIXT_BFN_NOVERS$ANNO_VER_NUM"
  local FIXT_FILE="$FIXT_VERS_BFN.anno.json"
  local FIXT_DATA="$(./test/mark_anno_fixture_slots.sed -- "$FIXT_FILE")"
  local ANNO_VERS_ID="${FIXT_DATA#*<°id>}"
  ANNO_VERS_ID="${ANNO_VERS_ID%%$QUOT*}"
  [[ "$ANNO_VERS_ID" =~ $VERS_ID_RGX ]] || return 4$(
    echo E: $FUNCNAME: "Failed to detect ANNO_VERS_ID" >&2)
  local ANNO_BASE_ID="${ANNO_VERS_ID%\~$ANNO_VER_NUM}"
  [ "$ANNO_BASE_ID" != "$ANNO_VERS_ID" ] || return 4$(
    echo E: $FUNCNAME: "Detected version number isn't $ANNO_VER_NUM" >&2)
  FIXT_DATA="${FIXT_DATA//<°id>/}"
  FIXT_DATA="${FIXT_DATA//<°anno_base_url>/$anno_baseurl}"

  local REG_DOI="${anno_doi_prefix:-0.NO.PREFIX.}$ANNO_BASE_ID"
  case "$VER_FX" in
    lvr ) ;;
    * ) REG_DOI+="${anno_doi_versep:-/}$ANNO_VER_NUM";;
  esac
  REG_DOI+="${CFG[anno_doi_suffix]}"
  echo "D: Expected DOI: $REG_DOI"

  local ADAPT=(
    env
    anno_initial_version_date="$CREA1"
    anno_doi_expect="$REG_DOI"
    anno_doi_targeturl="$anno_baseurl$ANNO_VERS_ID"
    anno_ver_num="$ANNO_VER_NUM"
    anno_ver_fx="$VER_FX"
    )
  case "$VER_FX" in
    lvr ) ADAPT+=( anno_custom_url='anno-fx:latest' );;
  esac
  ADAPT+=( ./adapter.sh )

  test_fixt_anno__compare_dcmeta || return $?

  <<<"$FIXT_DATA" "${ADAPT[@]}" update_doi_meta_for_one_anno_on_stdin \
    |& tee -- "$RESULTS_BFN.log"
  [ "${PIPESTATUS[*]}" == '0 0' ] || return 4
  rm -- "$RESULTS_BFN.log"

  (( SXS_CNT += 1 ))
}


function test_fixt_anno__compare_dcmeta () {
  local DCMETA_HAVE="$RESULTS_BFN.anno2dc.json"
  <<<"$FIXT_DATA" "${ADAPT[@]}" dc_api_anno_to_doirequest \
    >"$DCMETA_HAVE" || return $?

  local CONV_PROG='cat'
  local CONV_HINT=
  case "$VER_FX" in
    lvr )
      CONV_PROG='./test/dcmeta_latest_version_redirect.sed'
      CONV_HINT=' (modfied: LVR DOI/URL)'
      ;;
  esac

  local DCMETA_FIXT="$FIXT_VERS_BFN.dcmeta.json"
  local DCMETA_DIFF="$RESULTS_BFN.anno2dc.diff"
  diff -U 2 --label "$DCMETA_FIXT$CONV_HINT" -- <(
    $CONV_PROG -- "$DCMETA_FIXT") "$DCMETA_HAVE" >"$DCMETA_DIFF"
  local DIFF_RV="$?"
  if [ "$DIFF_RV" == 0 ]; then
    [ -s "$DCMETA_DIFF" ] && return 7$(
      echo E: $FUNCNAME: 'diff succeeded with unexpected output' >&2)
    rm -- "$DCMETA_DIFF" "$DCMETA_HAVE"
    return 0
  fi

  [ -s "$DCMETA_DIFF" ] || return 7$(
    echo E: $FUNCNAME: 'diff failed without producing output' >&2)

  test_check_skip fixt:dcmeta-diff:"$FIXT_SKIP_ID" && return 0
  echo E: "Unexpected DC metadata JSON. See $DCMETA_DIFF" >&2
  return 4
}







return 0
