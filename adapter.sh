#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local DBGLV="${DEBUGLEVEL:-0}"
  local DBA_PATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  # ^-- DBA = <D>OI <b>ot <a>dapter
  local BOT_FUNCD="$DBA_PATH/botfuncs"
  cd -- "$DBA_PATH" || return $?
  local -A CFG=() STATE=()
  CFG[task]="${1:-update_doi_meta_for_one_anno_on_stdin}"; shift
  source -- "$BOT_FUNCD"/bot_init.sh || return $?
  source_these_libs "$BOT_FUNCD"/*.sh || return $?
  source_these_libs "$DBA_PATH"/src/*.sh || return $?
  bot_init_before_config || return $?
  source_in_func "$BOT_FUNCD"/cfg.default.rc || return $?
  source_in_func "$DBA_PATH"/src/cfg.default.rc || return $?
  load_host_config datacite || return $?
  "${CFG[task]}" "$@" || return $?
}



cli_main "$@"; exit $?
