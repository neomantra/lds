#!/bin/bash

for t in \
    test_Array \
    test_Vector \
    test_HashMap \
    ;
do
    echo $t
    luajit ./tests/$t.lua
done
