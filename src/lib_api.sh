#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function api_curl () {
  local CURL_PROG='curl'
  case "$1" in
    --log ) CURL_PROG='logged_curl';;
  esac

  local VERB="$1"; shift
  local SUB_URL="$1"; shift
  local OPT=(
    --request "$VERB"
    --header 'Content-Type: application/vnd.api+json'
    --silent
    )
  [ -z "${CFG[repo_user]}" ] || OPT+=(
    --user "${CFG[repo_user]}:${CFG[repo_pswd]}" )
  local FULL_URL="${CFG[datacite_server]}$SUB_URL"
  "$CURL_PROG" "${OPT[@]}" "$@" -- "$FULL_URL" || return $?
}


function logged_api_curl () { api_curl --log "$@"; }


function logged_curl () {
  local LOG_FILE="tmp.$(printf '%(%y%m%d-%H%M%S)T' -1).$$.curl.log"
  curl "$@" |& tee -- "$LOG_FILE"
  local RV="${PIPESTATUS[*]}"
  let RV="${RV// /+}"
  if [ "$RV" != 0 ]; then
    echo
    echo "W: curl: error, rv=$RV, log file: $LOG_FILE" >&2
    return "$RV"
  fi

  maybe_sort_json_logfile || return $?
  echo "D: curl: success, log file: $LOG_FILE"
}


function maybe_sort_json_logfile () {
  [ "$(cut --bytes=1 -- "$LOG_FILE")" == '{' ] || return 0
  local JSON_FILE="${LOG_FILE%.*}.json"
  json-sort-pmb "$LOG_FILE" >"$JSON_FILE" || return $?
  echo
  rm -- "$LOG_FILE" || true
  LOG_FILE="$JSON_FILE"
}














debug_cli "$@"; exit $?
