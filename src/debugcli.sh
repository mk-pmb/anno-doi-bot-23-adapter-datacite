#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function debug_cli () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  # cd -- "$SELFPATH" || return $?
  source -- "$SELFPATH"/lib_cfg.sh --lib || return $?
  source -- "$SELFPATH"/lib_api.sh --lib || return $?
  local -A CFG=(); load_config || return $?

  local PKG_PATH="$(dirname -- "$SELFPATH")"
  local TASK="$1"; shift
  case "$TASK" in
    '' ) TASK='no_task_given';;

    lac )
      TASK='logged_api_curl'
      # lac POST dois --data '@yolo.json'
      # lac GET dois/10.11588/anno.diglit.09a70a00f6719~2
      ;;

    l1 ) TASK='lookup_one_doi';;
    gdd ) TASK='generate_doi_draft';;
    upd ) TASK='update_doi_data';;
  esac

  "$TASK" "$@" || return $?$(echo "E: Task '$TASK' failed, rv=$?" >&2)
}


function generate_doi_draft () {
  nodemjs "$PKG_PATH"/src/anno_to_datacite_doi.mjs <"$1" || return $?
}


function update_doi_data () {
  local DATACITE_JSON="$(cat -- "${1:-/dev/stdin}")"
  local DOI='"doi":\s*"[^\s"]+"'
  DOI="$(<<<"$DATACITE_JSON" grep -oPe "$DOI" | cut -sd $'\x22' -f 4)"
  case "$DOI" in
    '' )
      echo 'E: Found no "doi": key in' "$JSON_FILE" >&2
      return 8;;
    *$'\n'* )
      echo 'E: Found too many "doi": keys in' "$JSON_FILE" >&2
      return 8;;
  esac
  logged_api_curl PUT dois/"$DOI" --data '@-' <<<"$DATACITE_JSON" || return $?
}


function lookup_one_doi () {
  logged_api_curl GET dois/"$1" || return $?
}












debug_cli "$@"; exit $?
