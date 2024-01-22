#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function put_one_dcmeta_file () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  if [ -n "$1" ]; then
    exec <"$1" || return $?
  else
    echo "D: reading DC metadata JSON from stdin." >&2
  fi
  npm run adapter update_doi_meta_for_one_dcmetajson_from_command cat
}


put_one_dcmeta_file "$@"; exit $?
