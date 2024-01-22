#!/bin/sed -urf
# -*- coding: UTF-8, tab-width: 2 -*-

s~^(\s*[^"a-z:]*"(id|$\
  |dc:isVersionOf|$\
  )":\s*")([^"/]+",?)$~\1<°anno_base_url><°id>\3~
