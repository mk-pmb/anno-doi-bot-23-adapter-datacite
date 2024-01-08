#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function load_default_config () {
  CFG=(
    [datacite_server]='https://api.test.datacite.org/'
    )
}


function load_host_config () {
  load_default_config || return $?
  local KEY= VAL=
  for VAL in "cfg.@$HOSTNAME/"[0-9]*_*.rc; do
    source -- "$VAL" || return $?$(
      echo "E: Failed to config file '$VAL', rv=$?" >&2)
  done
  for KEY in "${!CFG[@]}"; do
    VAL="${CFG[$KEY]}"
    export "cfg_$KEY=$VAL"
  done
}




return 0
