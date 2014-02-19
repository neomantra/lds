#!/bin/bash
# lds - LuaJIT Data Structures
#
# Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
# MIT License, see the COPYRIGHT file.

for t in \
    test_Array \
    test_Vector \
    test_HashMap \
    ;
do
    echo $t
    luajit ./tests/$t.lua
done
