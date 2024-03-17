#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
<<__DOC__

This command is meant for debug purposes only.
You can pass it a list of DOIs to download meta data for, e.g.:

./adapter.sh download_meta_for_dois \
  '10.82109/anno.test.doibot-datacite-test-240126_'{1..3}

It also supports a template mode, where a question mark (?) is used
in the first argument to mark the spot where all other arguments
shall be inserted. The next example uses this to fetch meta data for
some specific versions and, using the empty string as last argument,
also the meta data for the latest version redirect:

./adapter.sh download_meta_for_dois \
  '10.82109/anno.test.doibot-datacite-test-240126?' _{1..3} ''


__DOC__


function download_meta_for_dois () {
  local SLOT='?'
  local DOI_TPL="$SLOT"
  if [[ "$1" == *"$SLOT"* ]]; then DOI_TPL="$1"; shift; fi
  local DOI_ARG= SAVE_DEST= SAVE_TMP=
  for DOI_ARG in "$@"; do
    DOI_ARG="${DOI_TPL//"$SLOT"/"$DOI_ARG"}"
    SAVE_DEST="tmp.${DOI_ARG//[^A-Za-z0-9_.~-]/,}.json"
    SAVE_TMP="$SAVE_DEST.$$.part"
    echo D: $FUNCNAME: "$SAVE_DEST <- DataCite<urn:doi:$DOI_ARG>"
    dc_api_curl GET dois/"$DOI_ARG" >"$SAVE_TMP" || return $?
    "${CFG[json_prettify_prog]}" <"$SAVE_TMP" >"$SAVE_DEST" || return $?
    rm -- "$SAVE_TMP" || true
    du -ba -- "$SAVE_DEST" || return $?
  done
}






return 0
