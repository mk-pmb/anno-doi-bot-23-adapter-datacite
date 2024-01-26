#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function update_doi_meta_for_one_dcmetajson () {
  [ -n "$DC_META_JSON" ] || return 5$(echo '-ERR Empty DC_META_JSON.' >&2)
  local WANT_DOI='"doi":\s*"[^\s"]+"'
  WANT_DOI="$(<<<"$DC_META_JSON" grep -oPe "$WANT_DOI" | cut -sd $'\x22' -f 4)"
  [ -n "$JSON_FILE" ] || local JSON_FILE='(unknown input method)'
  case "$WANT_DOI" in
    '' )
      echo -ERR 'Found no "doi": key in' "$JSON_FILE" >&2
      return 8;;
    *$'\n'* )
      echo -ERR 'Found too many "doi": keys in' "$JSON_FILE" >&2
      return 8;;
    "$anno_doi_expect" ) ;;
    * )
      echo -ERR "DOI '$anno_doi_expect' in environment differs from DOI" \
        "'$WANT_DOI' in $JSON_FILE" >&2
      return 8;;
  esac
  safechars_verify doi "$WANT_DOI" || return $?$(
    echo E: 'DOI contains unacceptable characters.' >&2)


  # ===== Update URL ===== ===== ===== ===== ===== ===== ===== ===== ===== #

  echo D: 'Update URL and check current visibility:'
  local REDIR_URL="$anno_doi_targeturl"
  safechars_verify url "$REDIR_URL" || return $?$(
    echo E: 'Target URL contains unacceptable characters.' >&2)
  dc_api_put_doi_interpret "$WANT_DOI" url:"$REDIR_URL" || return $?


  # ===== Update full metadata ===== ===== ===== ===== ===== ===== ===== #

  if [ "$DC_META_JSON" == '__skip__' ]; then
    echo D: 'Not updating meta data: Skipping as requested.'
  elif [ "${STATE[dc_visibility]}" == draft ]; then
    echo D: 'Update full meta data for draft:'
    STATE[dc_meta_json]="$DC_META_JSON"
    [ "$DBGLV" -lt 4 ] || dc_api_debug_dump dc_meta_json || return $?
    dc_api_put_doi_interpret "$WANT_DOI" <<<"$DC_META_JSON" || return $?
  else
    echo D: 'Not updating meta data: DOI not in draft state.'
  fi


  # ===== Publish if needed ===== ===== ===== ===== ===== ===== ===== #

  if [ "${STATE[dc_visibility]}" == public ]; then
    echo D: 'Visibility aleady is public.'
  else
    echo D: 'Set visibility to public:'
    dc_api_put_doi_interpret "$WANT_DOI" event:publish
    echo "D: New visibility: ${STATE[dc_visibility]}"
    [ "${STATE[dc_visibility]}" == public ] || return 4$(
      echo E: 'Failed to publish DOI.' >&2)
  fi

  echo "+OK reg/upd <urn:doi:$WANT_DOI>"
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
