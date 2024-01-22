#!/bin/sed -urf
# -*- coding: UTF-8, tab-width: 2 -*-

/^\s+"doi":/s![^A-Za-z0-9"][0-9]+(",?)$!\1!
/^\s+"url":/s!\~[0-9]+(",?)$!\1!
