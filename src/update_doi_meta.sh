#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function update_doi_meta_for_one_dcmetajson () {
  [ -n "$DC_META_JSON" ] || return 5$(echo '-ERR Empty DC_META_JSON.' >&2)
  local WANT_DOI='"doi":\s*"[^\s"]+"'
  WANT_DOI="$(<<<"$DC_META_JSON" grep -oPe "$WANT_DOI" | cut -sd $'\x22' -f 4)"
  case "$WANT_DOI" in
    '' )
      echo '-ERR Found no "doi": key in' "$JSON_FILE" >&2
      return 8;;
    *$'\n'* )
      echo '-ERR Found too many "doi": keys in' "$JSON_FILE" >&2
      return 8;;
  esac

  STATE[dc_meta_json]="$DC_META_JSON"
  [ "$DBGLV" -lt 4 ] || dc_api_debug_dump dc_meta_json || return $?
  dc_api_put_doi_interpret "$WANT_DOI" <<<"$DC_META_JSON" || return $?
  local VAL="${STATE[dc_result]}"
  case "$VAL" in
    '<urn:doi:'*'> public' )
      echo "+OK reg/upd ${VAL% *}"
      return 0;;

    '<urn:doi:'*'> draft' | \
    '<urn:doi:'*'> hidden' | \
    __needs_publish__ ) ;;

    * )
      echo "-ERR Unsupported DC API DOI state: '$VAL'" >&2
      return 5;;
  esac

  echo "D: Set visibility to public:"
  dc_api_put_doi_interpret "$WANT_DOI" <<<'
    {"data":{"type":"dois","attributes":{"event":"publish"}}}
    ' || return $?
  VAL="${STATE[dc_result]}"
  echo "D: New visibility: $VAL"
  case "$VAL" in
    '<urn:doi:'*'> public' )
      echo "+OK reg/upd ${VAL% *}"
      return 0;;

    '<urn:doi:'*'> draft' | \
    '<urn:doi:'*'> hidden' | \
    __needs_publish__ )
      echo "-ERR DOI still not public even after publishing: '$VAL'" >&2
      return 5;;

    * )
      echo "-ERR Unsupported DC API DOI state: '$VAL'" >&2
      return 5;;
  esac
}


function update_doi_meta_for_one_anno_on_stdin () {
  local DC_META_JSON="$(dc_api_anno_to_doirequest)"
  [ -n "$DC_META_JSON" ] || return 5$(
    echo '-ERR Failed to convert anno to DataCite API format.' >&2)
  local JSON_FILE='(anno on stdin)'
  update_doi_meta_for_one_dcmetajson || return $?
}


function update_doi_meta_for_one_dcmetajson_from_command () {
  local PRE= DC_META_JSON= RV=
  [ "$#" -ge 1 ] || PRE='cat'
  DC_META_JSON="$("$@")"; RV=$?
  [ -n "$DC_META_JSON" ] || return 5$(echo >&2 \
    '-ERR Failed to read DataCite API metadata from command:' \
    "command failed with exit status $RV: $*")
  local JSON_FILE='(external)'
  update_doi_meta_for_one_dcmetajson || return $?
}










return 0
