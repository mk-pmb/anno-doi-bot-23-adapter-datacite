#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function dc_api_anno_to_doirequest () {
  runmjs_file "$DBA_PATH"/src/annoToDataciteDoi.mjs
}


function dc_api_curl () {
  local VERB="$1"; shift
  local SUB_URL="$1"; shift
  local DC_USER="${CFG[datacite_repo_user]}:${CFG[datacite_repo_pswd]}"
  case "$DC_USER" in
    :* ) echo E: $FUNCNAME: 'Empty datacite_repo_user!' >&2; return 4;;
    *: ) echo E: $FUNCNAME: 'Empty datacite_repo_pswd!' >&2; return 4;;
  esac
  local OPT=(
    --silent
    --request "$VERB"
    --header 'Content-Type: application/vnd.api+json'
    )
  [ -z "${CFG[datacite_repo_user]}" ] || OPT+=(
    --user "${CFG[datacite_repo_user]}:${CFG[datacite_repo_pswd]}" )
  local FULL_URL="${CFG[datacite_api_server]}$SUB_URL"
  curl "${OPT[@]}" "$@" -- "$FULL_URL" || return $?
}


function dc_api_debug_dump () {
  local KEY="$1"
  local VAL="${STATE[$KEY]}"

  local DUMP_NUM="${STATE[dc_api_debug_dump_counter]:-0}"
  (( DUMP_NUM += 1 ))
  STATE[dc_api_debug_dump_counter]="$DUMP_NUM"

  local DEST_BFN="test/tmp.$(basename -- "$WANT_DOI").$KEY.$DUMP_NUM"
  local DEST_FXT='txt'
  local CONV='cat'
  case "${VAL//[$'\t \r\n']/}" in
    '{'*'}' ) DEST_FXT='json';;
  esac
  case "$DEST_FXT" in
    json )
      for CONV in json-sort-pmb jq cat; do
        which "$CONV" |& grep -qPe '^/' && break
      done;;
  esac
  echo "D: $KEY (${#VAL} bytes) -> $CONV -> $DEST_BFN.$DEST_FXT" >&2
  <<<"$VAL" $CONV >"$DEST_BFN.$DEST_FXT" || return $?
}


function dc_api_put_doi_interpret () {
  local WANT_DOI="$1"; shift
  local RV=
  STATE[dc_result]=
  STATE[dc_reply]="$(dc_api_curl PUT dois/"$WANT_DOI" --data '@-')"; RV=$?
  [ "$DBGLV" -lt 4 ] || dc_api_debug_dump dc_reply || return $?
  [ "$RV" == 0 ] || return 4$(echo "E: API request error, rv=$RV" >&2)

  case "${STATE[dc_reply]//[$'\r\n \t']/}" in
    '{'*'}' ) ;;
    * )
      echo E: "Received an unexpected API reply:" \
        "Message is not wrapped in a JSON object container." >&2
      return 4;;
  esac

  STATE[dc_result]="$(<<<"${STATE[dc_reply]}" \
    runmjs_file "$DBA_PATH"/src/interpretDcDoiPutResult.mjs
    )" || return 4$(echo "E: Failed to interpret API result, rv=$RV" >&2)
  [ "$DBGLV" -lt 4 ] || dc_api_debug_dump dc_result || return $?
}







return 0
